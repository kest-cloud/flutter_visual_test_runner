import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Simulates realistic pointer gestures and text input on live Flutter widgets.
class GestureSimulator {
  static int _nextPointerId = 1000;

  /// Programmatically simulate a tap at global screen [position] with optional [element] callback trigger.
  static Future<void> tap(Offset position, {Element? element, int? pointer}) async {
    final p = pointer ?? _nextPointerId++;
    final downTime = DateTime.now();

    _dispatch(PointerAddedEvent(
      pointer: p,
      position: position,
      timeStamp: Duration(milliseconds: downTime.millisecondsSinceEpoch),
    ));

    _dispatch(PointerDownEvent(
      pointer: p,
      position: position,
      buttons: kPrimaryButton,
      timeStamp: Duration(milliseconds: downTime.millisecondsSinceEpoch),
    ));

    // Natural tap contact duration
    await Future.delayed(const Duration(milliseconds: 60));

    final upTime = DateTime.now();
    _dispatch(PointerUpEvent(
      pointer: p,
      position: position,
      timeStamp: Duration(milliseconds: upTime.millisecondsSinceEpoch),
    ));

    _dispatch(PointerRemovedEvent(
      pointer: p,
      position: position,
      timeStamp: Duration(milliseconds: upTime.millisecondsSinceEpoch),
    ));

    if (element != null && element.mounted) {
      invokeTapCallback(element);
    }
  }

  /// Programmatically simulate a double-tap at global screen [position].
  static Future<void> doubleTap(Offset position, {Element? element}) async {
    await tap(position, element: element);
    await Future.delayed(const Duration(milliseconds: 100));
    await tap(position, element: element);
  }

  /// Invoke tap/press callback on an element or its nearest button/gesture ancestor/descendant.
  static void invokeTapCallback(Element element) {
    bool invoked = false;

    void checkWidget(Widget w) {
      if (invoked) return;
      if (w is ButtonStyleButton && w.onPressed != null) {
        w.onPressed!();
        invoked = true;
      } else if (w is IconButton && w.onPressed != null) {
        w.onPressed!();
        invoked = true;
      } else if (w is FloatingActionButton && w.onPressed != null) {
        w.onPressed!();
        invoked = true;
      } else if (w is InkWell && w.onTap != null) {
        w.onTap!();
        invoked = true;
      } else if (w is GestureDetector && w.onTap != null) {
        w.onTap!();
        invoked = true;
      } else if (w is ListTile && w.onTap != null) {
        w.onTap!();
        invoked = true;
      }
    }

    checkWidget(element.widget);

    if (!invoked) {
      element.visitAncestorElements((ancestor) {
        checkWidget(ancestor.widget);
        return !invoked;
      });
    }

    if (!invoked) {
      element.visitChildren((child) {
        checkWidget(child.widget);
      });
    }
  }

  /// Programmatically simulate a long-press at [position] for [duration].
  static Future<void> longPress(
    Offset position, {
    Duration duration = const Duration(milliseconds: 700),
  }) async {
    final p = _nextPointerId++;
    final downTime = DateTime.now();

    _dispatch(PointerAddedEvent(
      pointer: p,
      position: position,
      timeStamp: Duration(milliseconds: downTime.millisecondsSinceEpoch),
    ));

    _dispatch(PointerDownEvent(
      pointer: p,
      position: position,
      buttons: kPrimaryButton,
      timeStamp: Duration(milliseconds: downTime.millisecondsSinceEpoch),
    ));

    await Future.delayed(duration);

    final upTime = DateTime.now();
    _dispatch(PointerUpEvent(
      pointer: p,
      position: position,
      timeStamp: Duration(milliseconds: upTime.millisecondsSinceEpoch),
    ));

    _dispatch(PointerRemovedEvent(
      pointer: p,
      position: position,
      timeStamp: Duration(milliseconds: upTime.millisecondsSinceEpoch),
    ));
  }

  /// Programmatically simulate a smooth drag gesture from [start] to [end].
  static Future<void> drag(
    Offset start,
    Offset end, {
    Duration duration = const Duration(milliseconds: 300),
    int steps = 15,
  }) async {
    final p = _nextPointerId++;
    final startTime = DateTime.now();

    _dispatch(PointerAddedEvent(
      pointer: p,
      position: start,
      timeStamp: Duration(milliseconds: startTime.millisecondsSinceEpoch),
    ));

    _dispatch(PointerDownEvent(
      pointer: p,
      position: start,
      buttons: kPrimaryButton,
      timeStamp: Duration(milliseconds: startTime.millisecondsSinceEpoch),
    ));

    final stepDuration = Duration(
      milliseconds: (duration.inMilliseconds / steps).round().clamp(5, 50),
    );

    for (int i = 1; i <= steps; i++) {
      await Future.delayed(stepDuration);
      final progress = i / steps;
      final currentPos = Offset.lerp(start, end, progress)!;
      final moveTime = DateTime.now();

      _dispatch(PointerMoveEvent(
        pointer: p,
        position: currentPos,
        delta: (end - start) / steps.toDouble(),
        buttons: kPrimaryButton,
        timeStamp: Duration(milliseconds: moveTime.millisecondsSinceEpoch),
      ));
    }

    final upTime = DateTime.now();
    _dispatch(PointerUpEvent(
      pointer: p,
      position: end,
      timeStamp: Duration(milliseconds: upTime.millisecondsSinceEpoch),
    ));

    _dispatch(PointerRemovedEvent(
      pointer: p,
      position: end,
      timeStamp: Duration(milliseconds: upTime.millisecondsSinceEpoch),
    ));
  }

  /// Programmatically simulate a scroll gesture by dragging opposite to [offset].
  static Future<void> scroll(
    Offset centerPosition,
    Offset offset, {
    Duration duration = const Duration(milliseconds: 350),
  }) async {
    // Scrolling down moves content up, so drag upwards
    final end = centerPosition - offset;
    await drag(centerPosition, end, duration: duration);
  }

  /// Enter text into the target [Element] (TextField, TextFormField, EditableText).
  static Future<void> enterText(
    Element element,
    String text, {
    bool clearFirst = false,
  }) async {
    // 1. Focus the widget
    if (element.renderObject is RenderBox) {
      final box = element.renderObject as RenderBox;
      if (box.hasSize && box.attached) {
        final pos = box.localToGlobal(box.size.center(Offset.zero));
        await tap(pos);
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    // 2. Find EditableTextState or TextEditingController
    EditableTextState? editableState;
    TextEditingController? controller;

    void visitor(Element el) {
      if (editableState != null) return;
      if (el is StatefulElement && el.state is EditableTextState) {
        editableState = el.state as EditableTextState;
      }
      el.visitChildren(visitor);
    }

    if (element is StatefulElement && element.state is EditableTextState) {
      editableState = element.state as EditableTextState;
    } else {
      element.visitChildren(visitor);
    }

    // Check if widget is TextField or TextFormField with controller
    final widget = element.widget;
    if (widget is TextField && widget.controller != null) {
      controller = widget.controller;
    }

    final targetController = controller ?? editableState?.widget.controller;

    if (targetController != null) {
      final newText = clearFirst ? text : '${targetController.text}$text';
      targetController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      );
      if (widget is TextField) {
        widget.onChanged?.call(newText);
      }
    } else if (editableState != null) {
      final current = clearFirst ? '' : editableState!.textEditingValue.text;
      final updated = '$current$text';
      editableState!.userUpdateTextEditingValue(
        TextEditingValue(
          text: updated,
          selection: TextSelection.collapsed(offset: updated.length),
        ),
        SelectionChangedCause.keyboard,
      );
    }

    // Give the framework a frame to rebuild and trigger validation
    await Future.delayed(const Duration(milliseconds: 80));
  }

  /// Clear text inside target [Element].
  static Future<void> clearText(Element element) async {
    await enterText(element, '', clearFirst: true);
  }

  /// Dismiss the soft keyboard.
  static void dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  static void _dispatch(PointerEvent event) {
    WidgetsBinding.instance.handlePointerEvent(event);
  }
}
