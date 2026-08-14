import 'package:flutter/material.dart';
import '../models/target_finder.dart';
import '../models/test_enums.dart';

/// Represents the result of locating a widget in the live Element tree.
class FoundWidgetResult {
  final Element element;
  final Widget widget;
  final RenderBox? renderBox;
  final Rect globalRect;
  final Offset centerPoint;
  final bool isVisibleInViewport;

  const FoundWidgetResult({
    required this.element,
    required this.widget,
    this.renderBox,
    required this.globalRect,
    required this.centerPoint,
    required this.isVisibleInViewport,
  });
}

/// Intelligent engine that inspects the live Flutter Element tree to locate widgets,
/// compute screen geometry, and automatically resolve off-screen elements.
class WidgetFinderEngine {
  /// GlobalKey identifying the host application boundary to avoid matching runner overlay widgets.
  static GlobalKey? hostAppKey;

  /// Root element of the live Flutter application.
  static Element? get rootElement {
    if (hostAppKey?.currentContext != null) {
      return hostAppKey!.currentContext as Element?;
    }
    return WidgetsBinding.instance.rootElement;
  }

  /// Locate all elements matching [finder] in the live widget tree.
  static List<FoundWidgetResult> findAll(
    TargetFinder finder, {
    Element? customRoot,
  }) {
    final root = customRoot ?? rootElement;
    if (root == null) return [];

    final results = <FoundWidgetResult>[];

    void visitor(Element element) {
      if (matches(element, finder)) {
        final renderBox = _getRenderBox(element);
        if (renderBox != null && renderBox.hasSize && renderBox.attached) {
          try {
            final globalTopLeft = renderBox.localToGlobal(Offset.zero);
            final size = renderBox.size;
            final rect = globalTopLeft & size;
            final isVisible = _checkViewportVisibility(rect);

            results.add(
              FoundWidgetResult(
                element: element,
                widget: element.widget,
                renderBox: renderBox,
                globalRect: rect,
                centerPoint: rect.center,
                isVisibleInViewport: isVisible,
              ),
            );
          } catch (_) {
            // RenderBox might be in the middle of layout/unattached
          }
        }
      }
      element.visitChildren(visitor);
    }

    visitor(root);
    return results;
  }

  /// Locate the first and most appropriate matching widget. Returns null if no match found.
  static FoundWidgetResult? findFirst(
    TargetFinder finder, {
    Element? customRoot,
  }) {
    final list = findAll(finder, customRoot: customRoot);
    if (list.isEmpty) return null;

    final query = (finder.value ?? '').trim().toLowerCase();

    int scoreResult(FoundWidgetResult result) {
      int score = 0;
      if (result.isVisibleInViewport) score += 1000;

      // Check if interactive button/clickable
      final isButton = result.widget is ButtonStyleButton ||
          result.widget is IconButton ||
          result.widget is FloatingActionButton ||
          result.widget is InkWell ||
          result.widget is InkResponse ||
          result.widget is GestureDetector ||
          result.widget is ListTile;
      if (isButton) score += 500;

      // Check exact key match
      if (finder.value != null && result.widget.key != null) {
        final keyStr = result.widget.key.toString().toLowerCase();
        final rawKey = finder.value!.toLowerCase();
        if (keyStr == "[<'$rawKey'>]" ||
            keyStr == "<'$rawKey'>" ||
            keyStr == "[$rawKey]" ||
            keyStr == rawKey) {
          score += 800;
        }
      }

      // Check exact text match vs partial substring
      final text = extractTextFromElement(result.element)?.trim().toLowerCase();
      if (text != null && query.isNotEmpty) {
        if (text == query) {
          score += 600; // Exact match heavily preferred over substring
        } else if (text.startsWith(query)) {
          score += 200;
        }
      }

      return score;
    }

    list.sort((a, b) => scoreResult(b).compareTo(scoreResult(a)));
    return list.first;
  }

  /// Determines whether a live [Element] matches the given [TargetFinder].
  static bool matches(Element element, TargetFinder finder) {
    final widget = element.widget;

    switch (finder.type) {
      case FinderType.byKey:
        return _matchesKey(widget, finder.value);

      case FinderType.byText:
        return _matchesText(element, finder.value, finder.regex);

      case FinderType.byType:
        return _matchesType(widget, finder.widgetType, finder.value);

      case FinderType.byTooltip:
        return _matchesTooltip(widget, finder.value);

      case FinderType.byIcon:
        return _matchesIcon(widget, finder.iconData, finder.value);

      case FinderType.bySemantics:
        return _matchesSemantics(element, finder.value);

      case FinderType.byHint:
        return _matchesHint(widget, finder.value);

      case FinderType.smart:
        return _matchesSmart(element, finder.value ?? '');

      case FinderType.custom:
        return finder.customPredicate?.call(element) ?? false;
    }
  }

  static bool _matchesKey(Widget widget, String? keyValue) {
    if (keyValue == null || widget.key == null) return false;
    final key = widget.key!;
    if (key is ValueKey) {
      return key.value.toString() == keyValue;
    }
    final keyStr = key.toString();
    return keyStr == keyValue ||
        keyStr == "[$keyValue]" ||
        keyStr == "[<'$keyValue'>]" ||
        keyStr == "<'$keyValue'>";
  }

  static bool _matchesText(Element element, String? text, RegExp? regex) {
    final extractedText = extractTextFromElement(element);
    if (extractedText == null) return false;

    if (regex != null) {
      return regex.hasMatch(extractedText);
    }
    if (text == null) return false;

    return extractedText.trim() == text.trim() ||
        extractedText.toLowerCase().contains(text.toLowerCase());
  }

  static bool _matchesType(Widget widget, Type? type, String? typeName) {
    if (type != null && widget.runtimeType == type) return true;
    if (typeName != null) {
      final runtimeName = widget.runtimeType.toString();
      return runtimeName == typeName ||
          runtimeName.toLowerCase() == typeName.toLowerCase();
    }
    return false;
  }

  static bool _matchesTooltip(Widget widget, String? message) {
    if (widget is Tooltip && message != null) {
      return widget.message == message ||
          (widget.message?.toLowerCase().contains(message.toLowerCase()) ?? false);
    }
    return false;
  }

  static bool _matchesIcon(Widget widget, IconData? icon, String? codePoint) {
    if (widget is Icon) {
      if (icon != null && widget.icon == icon) {
        return true;
      }
      if (codePoint != null &&
          widget.icon?.codePoint.toString() == codePoint) {
        return true;
      }
    }
    return false;
  }

  static bool _matchesSemantics(Element element, String? label) {
    if (label == null) return false;
    if (element.widget is Semantics) {
      final s = element.widget as Semantics;
      if (s.properties.label?.toLowerCase().contains(label.toLowerCase()) ??
          false) {
        return true;
      }
    }
    return false;
  }

  static bool _matchesHint(Widget widget, String? hint) {
    if (hint == null) return false;
    final lowerHint = hint.toLowerCase();

    if (widget is TextField) {
      final decoration = widget.decoration;
      if (decoration != null) {
        final hintText = decoration.hintText?.toLowerCase();
        final labelText = decoration.labelText?.toLowerCase();
        final helperText = decoration.helperText?.toLowerCase();
        if ((hintText != null && hintText.contains(lowerHint)) ||
            (labelText != null && labelText.contains(lowerHint)) ||
            (helperText != null && helperText.contains(lowerHint))) {
          return true;
        }
      }
    }
    if (widget is TextFormField) {
      // TextFormField wraps a TextField in its state
      return true;
    }
    return false;
  }

  /// Smart lookup: checks text, keys, hints, semantic labels, and button child text.
  static bool _matchesSmart(Element element, String query) {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return false;

    final widget = element.widget;

    // 1. Direct key match
    if (widget.key != null) {
      final keyStr = widget.key.toString().toLowerCase();
      if (keyStr.contains(cleanQuery) ||
          keyStr.replaceAll('_', '').contains(cleanQuery.replaceAll(' ', ''))) {
        return true;
      }
    }

    // 2. Direct or child text match
    final text = extractTextFromElement(element);
    if (text != null && text.toLowerCase().contains(cleanQuery)) {
      return true;
    }

    // 3. Hint / Label match for text fields
    if (_matchesHint(widget, cleanQuery)) {
      return true;
    }

    // 4. Check for phone / email / search specific input queries
    if (cleanQuery.contains('phone') && widget is TextField) {
      if (widget.keyboardType == TextInputType.phone) return true;
    }
    if (cleanQuery.contains('email') && widget is TextField) {
      if (widget.keyboardType == TextInputType.emailAddress) return true;
    }
    if (cleanQuery.contains('number') && widget is TextField) {
      if (widget.keyboardType == TextInputType.number) return true;
    }

    // 5. Tooltip match
    if (_matchesTooltip(widget, cleanQuery)) {
      return true;
    }

    return false;
  }

  /// Extracts text representation from [Element] if it is a Text, RichText, or EditableText widget.
  static String? extractTextFromElement(Element element) {
    final widget = element.widget;
    if (widget is Text) {
      return widget.data ?? widget.textSpan?.toPlainText();
    }
    if (widget is RichText) {
      return widget.text.toPlainText();
    }
    if (widget is EditableText) {
      return widget.controller.text;
    }
    if (widget is SelectableText) {
      return widget.data ?? widget.textSpan?.toPlainText();
    }

    // Search descendants recursively for text if it is a container, button, or card
    String? childText;
    void textFinder(Element el) {
      if (childText != null) return;
      final w = el.widget;
      if (w is Text) {
        childText = w.data ?? w.textSpan?.toPlainText();
        return;
      } else if (w is RichText) {
        childText = w.text.toPlainText();
        return;
      } else if (w is EditableText) {
        childText = w.controller.text;
        return;
      }
      el.visitChildren(textFinder);
    }

    element.visitChildren(textFinder);
    return childText;
  }

  /// Locate the [RenderBox] associated with an [Element].
  static RenderBox? _getRenderBox(Element element) {
    if (element.renderObject is RenderBox) {
      return element.renderObject as RenderBox;
    }
    RenderBox? box;
    element.visitChildren((child) {
      if (box != null) return;
      if (child.renderObject is RenderBox) {
        box = child.renderObject as RenderBox;
      }
    });
    return box;
  }

  /// Check if a global screen [Rect] is within the visible screen viewport.
  static bool _checkViewportVisibility(Rect rect) {
    final view = WidgetsBinding.instance.platformDispatcher.views.firstOrNull;
    if (view == null) return true;

    final screenSize = view.physicalSize / view.devicePixelRatio;
    final screenRect = Offset.zero & screenSize;

    return screenRect.overlaps(rect) && rect.width > 0 && rect.height > 0;
  }

  /// Finds the nearest parent [ScrollableState] for an element.
  static ScrollableState? findScrollableParent(Element element) {
    ScrollableState? scrollable;
    element.visitAncestorElements((ancestor) {
      if (ancestor is StatefulElement && ancestor.state is ScrollableState) {
        scrollable = ancestor.state as ScrollableState;
        return false;
      }
      return true;
    });
    return scrollable;
  }

  /// Automatically scrolls parent scrollables until [element] is brought into view.
  static Future<void> scrollIntoView(Element element) async {
    final scrollable = findScrollableParent(element);
    if (scrollable != null && scrollable.context.mounted) {
      await Scrollable.ensureVisible(
        element,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.5,
      );
      // Wait for layout update
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
}
