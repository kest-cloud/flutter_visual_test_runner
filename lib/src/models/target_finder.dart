import 'package:flutter/widgets.dart';
import 'test_enums.dart';

/// Defines how the test runner locates a target widget in the live Flutter Element tree.
class TargetFinder {
  /// The lookup strategy type.
  final FinderType type;

  /// String value used for matching (e.g. key name, text content, tooltip, type name, or smart query).
  final String? value;

  /// Optional regular expression pattern if matching text via regex.
  final RegExp? regex;

  /// Optional [Type] if matching by exact Dart widget Type.
  final Type? widgetType;

  /// Optional [IconData] if matching by icon.
  final IconData? iconData;

  /// Optional custom predicate matching an [Element].
  final bool Function(Element element)? customPredicate;

  /// Human-readable description of this finder.
  final String? customDescription;

  const TargetFinder._({
    required this.type,
    this.value,
    this.regex,
    this.widgetType,
    this.iconData,
    this.customPredicate,
    this.customDescription,
  });

  /// Finds a widget by [Key] or string key name (e.g. `Key('submit_button')` or `'submit_button'`).
  factory TargetFinder.byKey(dynamic key, {String? description}) {
    final keyStr = key is Key
        ? (key is ValueKey ? key.value.toString() : key.toString())
        : key.toString();
    return TargetFinder._(
      type: FinderType.byKey,
      value: keyStr,
      customDescription: description ?? 'Key("$keyStr")',
    );
  }

  /// Finds a widget displaying specific text or matching a regular expression.
  factory TargetFinder.byText(String text, {bool isRegex = false, String? description}) {
    return TargetFinder._(
      type: FinderType.byText,
      value: text,
      regex: isRegex ? RegExp(text) : null,
      customDescription: description ?? 'Text("$text")',
    );
  }

  /// Finds a widget matching a regular expression.
  factory TargetFinder.byPattern(RegExp pattern, {String? description}) {
    return TargetFinder._(
      type: FinderType.byText,
      value: pattern.pattern,
      regex: pattern,
      customDescription: description ?? 'Pattern(/${pattern.pattern}/)',
    );
  }

  /// Finds a widget by its Dart [Type] or type name.
  factory TargetFinder.byType(Type type, {String? description}) {
    return TargetFinder._(
      type: FinderType.byType,
      widgetType: type,
      value: type.toString(),
      customDescription: description ?? 'Type(${type.toString()})',
    );
  }

  /// Finds a widget by type name string (useful when parsing from JSON/YAML).
  factory TargetFinder.byTypeName(String typeName, {String? description}) {
    return TargetFinder._(
      type: FinderType.byType,
      value: typeName,
      customDescription: description ?? 'Type($typeName)',
    );
  }

  /// Finds a widget with a matching [Tooltip] message.
  factory TargetFinder.byTooltip(String message, {String? description}) {
    return TargetFinder._(
      type: FinderType.byTooltip,
      value: message,
      customDescription: description ?? 'Tooltip("$message")',
    );
  }

  /// Finds an [Icon] widget displaying the given [IconData].
  factory TargetFinder.byIcon(IconData icon, {String? description}) {
    return TargetFinder._(
      type: FinderType.byIcon,
      iconData: icon,
      value: icon.codePoint.toString(),
      customDescription: description ?? 'Icon(${icon.codePoint})',
    );
  }

  /// Finds a widget with a matching [Semantics] label.
  factory TargetFinder.bySemantics(String label, {String? description}) {
    return TargetFinder._(
      type: FinderType.bySemantics,
      value: label,
      customDescription: description ?? 'Semantics("$label")',
    );
  }

  /// Finds a text input / form field with matching hint text or label text.
  factory TargetFinder.byHint(String hint, {String? description}) {
    return TargetFinder._(
      type: FinderType.byHint,
      value: hint,
      customDescription: description ?? 'Hint("$hint")',
    );
  }

  /// Intelligent fuzzy lookup: automatically checks key, text, label, hint, tooltip, and semantic roles.
  /// E.g. `TargetFinder.smart('phone number')`, `TargetFinder.smart('Sign In')`
  factory TargetFinder.smart(String query, {String? description}) {
    return TargetFinder._(
      type: FinderType.smart,
      value: query,
      customDescription: description ?? 'Smart("$query")',
    );
  }

  /// Custom predicate callback for advanced widget tree queries.
  factory TargetFinder.custom(
    bool Function(Element element) predicate, {
    String? description,
  }) {
    return TargetFinder._(
      type: FinderType.custom,
      customPredicate: predicate,
      customDescription: description ?? 'CustomPredicate()',
    );
  }

  /// Short display description of this finder.
  String get description => customDescription ?? '$type: $value';

  /// Serialize this target finder to a JSON/Map object.
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'value': value,
      'isRegex': regex != null,
      'customDescription': customDescription,
    };
  }

  /// Create a [TargetFinder] from a JSON/Map structure.
  factory TargetFinder.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'smart';
    final val = json['value'] as String? ?? '';
    final isRegex = json['isRegex'] as bool? ?? false;
    final desc = json['customDescription'] as String?;

    switch (typeStr) {
      case 'byKey':
      case 'key':
        return TargetFinder.byKey(val, description: desc);
      case 'byText':
      case 'text':
        return TargetFinder.byText(val, isRegex: isRegex, description: desc);
      case 'byType':
      case 'type':
        return TargetFinder.byTypeName(val, description: desc);
      case 'byTooltip':
      case 'tooltip':
        return TargetFinder.byTooltip(val, description: desc);
      case 'bySemantics':
      case 'semantics':
        return TargetFinder.bySemantics(val, description: desc);
      case 'byHint':
      case 'hint':
        return TargetFinder.byHint(val, description: desc);
      case 'smart':
      default:
        return TargetFinder.smart(val, description: desc);
    }
  }

  @override
  String toString() => description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TargetFinder &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          value == other.value &&
          widgetType == other.widgetType;

  @override
  int get hashCode => Object.hash(type, value, widgetType);
}
