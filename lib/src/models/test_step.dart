import 'package:flutter/widgets.dart';
import '../utils/log_entry.dart';
import 'target_finder.dart';
import 'test_enums.dart';

/// Defines an individual executable action, assertion, or wait step in a test case.
class TestStep {
  /// Unique identifier for this step.
  final String id;

  /// Type of action or assertion.
  final TestStepType type;

  /// Target widget finder to locate in the Element tree.
  final TargetFinder? target;

  /// Text to enter (for enterText) or expected text (for expectText).
  final String? text;

  /// Scroll delta offset, or start coordinate for pointer drag.
  final Offset? offset;

  /// End coordinate for drag gesture.
  final Offset? dragEndOffset;

  /// Duration to wait (for wait step) or drag duration.
  final Duration? duration;

  /// Maximum timeout duration for assertions and widget lookup.
  final Duration? timeout;

  /// Whether to clear existing text before typing in an enterText action.
  final bool clearFirst;

  /// User-defined description of this step.
  final String? description;

  /// Optional custom asynchronous action callback.
  final Future<void> Function(BuildContext context)? customAction;

  /// Whether execution should pause before running this step (breakpoint).
  bool isBreakpoint;

  /// Current execution status.
  TestStatus status;

  /// Timestamp when step started executing.
  DateTime? startTime;

  /// Timestamp when step finished executing.
  DateTime? endTime;

  /// Error message if the step failed.
  String? errorMessage;

  /// Stack trace if an unhandled exception occurred.
  StackTrace? stackTrace;

  /// Logs captured during the execution of this step.
  final List<RunnerLogEntry> logs;

  TestStep({
    String? id,
    required this.type,
    this.target,
    this.text,
    this.offset,
    this.dragEndOffset,
    this.duration,
    this.timeout,
    this.clearFirst = false,
    this.description,
    this.customAction,
    this.isBreakpoint = false,
    this.status = TestStatus.pending,
    this.startTime,
    this.endTime,
    this.errorMessage,
    this.stackTrace,
    List<RunnerLogEntry>? logs,
  })  : id = id ?? UniqueKey().toString(),
        logs = logs ?? [];

  /// Create a tap step on a target widget.
  factory TestStep.tap({
    required TargetFinder target,
    String? description,
    bool isBreakpoint = false,
  }) {
    return TestStep(
      type: TestStepType.tap,
      target: target,
      description: description ?? 'Tap on ${target.description}',
      isBreakpoint: isBreakpoint,
    );
  }

  /// Create a double-tap step on a target widget.
  factory TestStep.doubleTap({
    required TargetFinder target,
    String? description,
    bool isBreakpoint = false,
  }) {
    return TestStep(
      type: TestStepType.doubleTap,
      target: target,
      description: description ?? 'Double tap on ${target.description}',
      isBreakpoint: isBreakpoint,
    );
  }

  /// Create a long-press step on a target widget.
  factory TestStep.longPress({
    required TargetFinder target,
    Duration duration = const Duration(milliseconds: 700),
    String? description,
    bool isBreakpoint = false,
  }) {
    return TestStep(
      type: TestStepType.longPress,
      target: target,
      duration: duration,
      description: description ?? 'Long press on ${target.description}',
      isBreakpoint: isBreakpoint,
    );
  }

  /// Create an enterText step typing [text] into target input field.
  factory TestStep.enterText({
    required TargetFinder target,
    required String text,
    bool clearFirst = true,
    String? description,
    bool isBreakpoint = false,
  }) {
    return TestStep(
      type: TestStepType.enterText,
      target: target,
      text: text,
      clearFirst: clearFirst,
      description: description ?? 'Enter "$text" into ${target.description}',
      isBreakpoint: isBreakpoint,
    );
  }

  /// Create a clearText step.
  factory TestStep.clearText({
    required TargetFinder target,
    String? description,
    bool isBreakpoint = false,
  }) {
    return TestStep(
      type: TestStepType.clearText,
      target: target,
      description: description ?? 'Clear text in ${target.description}',
      isBreakpoint: isBreakpoint,
    );
  }

  /// Create a scroll step with relative [offset] delta.
  factory TestStep.scroll({
    required TargetFinder target,
    required Offset offset,
    String? description,
    bool isBreakpoint = false,
  }) {
    return TestStep(
      type: TestStepType.scroll,
      target: target,
      offset: offset,
      description:
          description ?? 'Scroll ${target.description} by (${offset.dx}, ${offset.dy})',
      isBreakpoint: isBreakpoint,
    );
  }

  /// Create a drag gesture from target to target + [offset].
  factory TestStep.drag({
    required TargetFinder target,
    required Offset offset,
    Duration duration = const Duration(milliseconds: 300),
    String? description,
    bool isBreakpoint = false,
  }) {
    return TestStep(
      type: TestStepType.drag,
      target: target,
      offset: offset,
      duration: duration,
      description: description ?? 'Drag ${target.description}',
      isBreakpoint: isBreakpoint,
    );
  }

  /// Create an auto-scroll step to bring [target] into viewport.
  factory TestStep.scrollTo({
    required TargetFinder target,
    String? description,
    bool isBreakpoint = false,
  }) {
    return TestStep(
      type: TestStepType.scrollTo,
      target: target,
      description: description ?? 'Scroll into view: ${target.description}',
      isBreakpoint: isBreakpoint,
    );
  }

  /// Assert that [target] is visible on screen.
  factory TestStep.expectVisible({
    required TargetFinder target,
    Duration? timeout,
    String? description,
    bool isBreakpoint = false,
  }) {
    return TestStep(
      type: TestStepType.expectVisible,
      target: target,
      timeout: timeout,
      description: description ?? 'Expect ${target.description} to be visible',
      isBreakpoint: isBreakpoint,
    );
  }

  /// Assert that [target] is NOT visible on screen.
  factory TestStep.expectNotVisible({
    required TargetFinder target,
    Duration? timeout,
    String? description,
    bool isBreakpoint = false,
  }) {
    return TestStep(
      type: TestStepType.expectNotVisible,
      target: target,
      timeout: timeout,
      description: description ?? 'Expect ${target.description} is not visible',
      isBreakpoint: isBreakpoint,
    );
  }

  /// Assert that [target] contains [text].
  factory TestStep.expectText({
    required TargetFinder target,
    required String text,
    Duration? timeout,
    String? description,
    bool isBreakpoint = false,
  }) {
    return TestStep(
      type: TestStepType.expectText,
      target: target,
      text: text,
      timeout: timeout,
      description: description ?? 'Expect ${target.description} has text "$text"',
      isBreakpoint: isBreakpoint,
    );
  }

  /// Dismiss the on-screen soft keyboard.
  factory TestStep.dismissKeyboard({
    String? description,
    bool isBreakpoint = false,
  }) {
    return TestStep(
      type: TestStepType.dismissKeyboard,
      description: description ?? 'Dismiss soft keyboard',
      isBreakpoint: isBreakpoint,
    );
  }

  /// Wait for a duration.
  factory TestStep.wait(
    Duration duration, {
    String? description,
    bool isBreakpoint = false,
  }) {
    return TestStep(
      type: TestStepType.wait,
      duration: duration,
      description: description ?? 'Wait ${duration.inMilliseconds}ms',
      isBreakpoint: isBreakpoint,
    );
  }

  /// Custom async callback step.
  factory TestStep.custom(
    Future<void> Function(BuildContext context) action, {
    String? description,
    bool isBreakpoint = false,
  }) {
    return TestStep(
      type: TestStepType.custom,
      customAction: action,
      description: description ?? 'Custom action',
      isBreakpoint: isBreakpoint,
    );
  }

  /// Total duration taken to execute this step.
  Duration get executionDuration {
    if (startTime == null) return Duration.zero;
    final end = endTime ?? DateTime.now();
    return end.difference(startTime!);
  }

  /// Reset execution state to pending.
  void reset() {
    status = TestStatus.pending;
    startTime = null;
    endTime = null;
    errorMessage = null;
    stackTrace = null;
    logs.clear();
  }

  /// Clone this step.
  TestStep copy() {
    return TestStep(
      id: id,
      type: type,
      target: target,
      text: text,
      offset: offset,
      dragEndOffset: dragEndOffset,
      duration: duration,
      timeout: timeout,
      clearFirst: clearFirst,
      description: description,
      customAction: customAction,
      isBreakpoint: isBreakpoint,
      status: status,
      startTime: startTime,
      endTime: endTime,
      errorMessage: errorMessage,
      stackTrace: stackTrace,
      logs: List.from(logs),
    );
  }

  /// Serialize this step to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'target': target?.toJson(),
      'text': text,
      'offsetDx': offset?.dx,
      'offsetDy': offset?.dy,
      'durationMs': duration?.inMilliseconds,
      'timeoutMs': timeout?.inMilliseconds,
      'clearFirst': clearFirst,
      'description': description,
      'isBreakpoint': isBreakpoint,
      'status': status.name,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'executionDurationMs': executionDuration.inMilliseconds,
      'errorMessage': errorMessage,
      'stackTrace': stackTrace?.toString(),
      'logs': logs.map((l) => l.toJson()).toList(),
    };
  }

  /// Create a [TestStep] from JSON map.
  factory TestStep.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'tap';
    final stepType = TestStepType.values.firstWhere(
      (t) => t.name == typeName,
      orElse: () => TestStepType.tap,
    );

    Offset? offset;
    if (json['offsetDx'] != null && json['offsetDy'] != null) {
      offset = Offset(
        (json['offsetDx'] as num).toDouble(),
        (json['offsetDy'] as num).toDouble(),
      );
    }

    return TestStep(
      id: json['id'] as String?,
      type: stepType,
      target: json['target'] != null
          ? TargetFinder.fromJson(Map<String, dynamic>.from(json['target'] as Map))
          : null,
      text: json['text'] as String?,
      offset: offset,
      duration: json['durationMs'] != null
          ? Duration(milliseconds: json['durationMs'] as int)
          : null,
      timeout: json['timeoutMs'] != null
          ? Duration(milliseconds: json['timeoutMs'] as int)
          : null,
      clearFirst: json['clearFirst'] as bool? ?? false,
      description: json['description'] as String?,
      isBreakpoint: json['isBreakpoint'] as bool? ?? false,
      status: TestStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => TestStatus.pending,
      ),
      startTime: json['startTime'] != null
          ? DateTime.tryParse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.tryParse(json['endTime'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
      logs: (json['logs'] as List?)
              ?.map((l) => RunnerLogEntry.fromJson(Map<String, dynamic>.from(l as Map)))
              .toList() ??
          [],
    );
  }

  @override
  String toString() => description ?? '${type.name} -> ${target?.description ?? "none"}';
}
