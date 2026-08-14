import 'package:flutter/widgets.dart';
import 'test_enums.dart';
import 'test_step.dart';

/// Represents a distinct test case comprising an ordered series of [TestStep]s.
class TestCase {
  /// Unique identifier for this test case.
  final String id;

  /// Human-readable title of the test case (e.g. "Test for required phonenumber length").
  final String name;

  /// Optional description or user story.
  final String? description;

  /// Categorization tags for filtering (e.g. `['@smoke', '@auth', '@phone']`).
  final List<String> tags;

  /// Ordered list of steps executed in this test case.
  final List<TestStep> steps;

  /// Optional hook executed before the first step runs.
  final Future<void> Function(BuildContext context)? setup;

  /// Optional hook executed after all steps finish (or on failure).
  final Future<void> Function(BuildContext context)? teardown;

  /// Execution status of the test case.
  TestStatus status;

  /// Timestamp when test case execution started.
  DateTime? startTime;

  /// Timestamp when test case execution finished.
  DateTime? endTime;

  /// Error message if this test case failed.
  String? errorMessage;

  TestCase({
    String? id,
    required this.name,
    this.description,
    List<String>? tags,
    List<TestStep>? steps,
    this.setup,
    this.teardown,
    this.status = TestStatus.pending,
    this.startTime,
    this.endTime,
    this.errorMessage,
  })  : id = id ?? UniqueKey().toString(),
        tags = tags ?? [],
        steps = steps ?? [];

  /// Total duration taken to execute this test case.
  Duration get duration {
    if (startTime == null) return Duration.zero;
    final end = endTime ?? DateTime.now();
    return end.difference(startTime!);
  }

  /// Total number of steps.
  int get totalStepCount => steps.length;

  /// Number of steps that passed.
  int get passedStepCount =>
      steps.where((s) => s.status == TestStatus.passed).length;

  /// Number of steps that failed.
  int get failedStepCount =>
      steps.where((s) => s.status == TestStatus.failed).length;

  /// Whether the test case completed successfully.
  bool get isPassed => status == TestStatus.passed;

  /// Whether the test case encountered a failure.
  bool get isFailed => status == TestStatus.failed;

  /// Whether the test case is currently running.
  bool get isRunning => status == TestStatus.running;

  /// Whether the test case is pending.
  bool get isPending => status == TestStatus.pending;

  /// Reset execution state and reset all child steps.
  void reset() {
    status = TestStatus.pending;
    startTime = null;
    endTime = null;
    errorMessage = null;
    for (final step in steps) {
      step.reset();
    }
  }

  /// Add a step to this test case.
  void addStep(TestStep step) {
    steps.add(step);
  }

  /// Serialize this test case to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'tags': tags,
      'status': status.name,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'durationMs': duration.inMilliseconds,
      'errorMessage': errorMessage,
      'totalStepCount': totalStepCount,
      'passedStepCount': passedStepCount,
      'failedStepCount': failedStepCount,
      'steps': steps.map((s) => s.toJson()).toList(),
    };
  }

  /// Create a [TestCase] from JSON map.
  factory TestCase.fromJson(Map<String, dynamic> json) {
    return TestCase(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'Untitled Test Case',
      description: json['description'] as String?,
      tags: (json['tags'] as List?)?.map((t) => t.toString()).toList() ?? [],
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
      steps: (json['steps'] as List?)
              ?.map((s) => TestStep.fromJson(Map<String, dynamic>.from(s as Map)))
              .toList() ??
          [],
    );
  }

  @override
  String toString() => '$name (${status.name})';
}
