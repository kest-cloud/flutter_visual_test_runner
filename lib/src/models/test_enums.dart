/// Action types that a test step can execute.
enum TestStepType {
  /// Simulate a tap pointer gesture on the target.
  tap,

  /// Simulate a double-tap pointer gesture on the target.
  doubleTap,

  /// Simulate a long-press pointer gesture on the target.
  longPress,

  /// Enter text into a target text field / editable widget.
  enterText,

  /// Clear text from a target text field / editable widget.
  clearText,

  /// Perform a scroll gesture on a scrollable target or container.
  scroll,

  /// Perform a drag gesture from start coordinate to end coordinate.
  drag,

  /// Intelligently scroll the viewport until the target widget is visible.
  scrollTo,

  /// Assert that the target widget is present and visible within viewport.
  expectVisible,

  /// Assert that the target widget is NOT present or hidden.
  expectNotVisible,

  /// Assert that the target widget contains the expected text.
  expectText,

  /// Dismiss the on-screen soft keyboard if active.
  dismissKeyboard,

  /// Wait for a specified duration or until condition passes.
  wait,

  /// Execute a custom Dart asynchronous callback with full context.
  custom,
}

/// Execution status of a scenario, test case, or step.
enum TestStatus {
  /// Not yet executed.
  pending,

  /// Currently executing.
  running,

  /// Execution paused (step-by-step debugger mode).
  paused,

  /// Executed and all assertions passed.
  passed,

  /// Executed and an assertion or action failed.
  failed,

  /// Skipped due to filters or condition failure.
  skipped,
}

/// Supported lookup strategies to locate widgets in the live Element tree.
enum FinderType {
  /// Find by [Key] or String key value.
  byKey,

  /// Find by text content or matching regular expression.
  byText,

  /// Find by Flutter Widget Type name or Type.
  byType,

  /// Find by Tooltip message.
  byTooltip,

  /// Find by IconData (icon code point or name).
  byIcon,

  /// Find by Semantics label.
  bySemantics,

  /// Find by input hint text or placeholder.
  byHint,

  /// Intelligent fuzzy lookup (checks key, text, label, hint, and widget type).
  smart,

  /// Custom predicate matching an Element or Widget.
  custom,
}

/// Log levels for test execution console.
enum RunnerLogLevel {
  debug,
  info,
  success,
  warning,
  error,
}
