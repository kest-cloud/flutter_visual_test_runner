import 'package:flutter/widgets.dart';
import 'test_case.dart';
import 'test_enums.dart';

/// Represents a cohesive feature scenario grouping multiple related [TestCase]s.
class TestScenario {
  /// Unique identifier for this scenario.
  final String id;

  /// Name of the scenario (e.g. "Phone Number Verification & Sign In").
  final String name;

  /// Optional detailed description.
  final String? description;

  /// Tags associated with this scenario (e.g. `['@smoke', '@auth']`).
  final List<String> tags;

  /// List of test cases in this scenario.
  final List<TestCase> cases;

  /// Overall execution status of this scenario.
  TestStatus status;

  /// Timestamp when scenario execution started.
  DateTime? startTime;

  /// Timestamp when scenario execution finished.
  DateTime? endTime;

  TestScenario({
    String? id,
    required this.name,
    this.description,
    List<String>? tags,
    List<TestCase>? cases,
    this.status = TestStatus.pending,
    this.startTime,
    this.endTime,
  })  : id = id ?? UniqueKey().toString(),
        tags = tags ?? [],
        cases = cases ?? [];

  /// Total duration taken to execute this scenario.
  Duration get duration {
    if (startTime == null) return Duration.zero;
    final end = endTime ?? DateTime.now();
    return end.difference(startTime!);
  }

  /// Total number of test cases.
  int get totalCaseCount => cases.length;

  /// Number of passed test cases.
  int get passedCaseCount =>
      cases.where((c) => c.status == TestStatus.passed).length;

  /// Number of failed test cases.
  int get failedCaseCount =>
      cases.where((c) => c.status == TestStatus.failed).length;

  /// Number of pending test cases.
  int get pendingCaseCount =>
      cases.where((c) => c.status == TestStatus.pending).length;

  /// Total number of steps across all test cases.
  int get totalStepCount =>
      cases.fold<int>(0, (sum, c) => sum + c.totalStepCount);

  /// Total number of passed steps across all test cases.
  int get passedStepCount =>
      cases.fold<int>(0, (sum, c) => sum + c.passedStepCount);

  /// Total number of failed steps across all test cases.
  int get failedStepCount =>
      cases.fold<int>(0, (sum, c) => sum + c.failedStepCount);

  /// Whether the scenario has passed.
  bool get isPassed => status == TestStatus.passed;

  /// Whether the scenario has failed.
  bool get isFailed => status == TestStatus.failed;

  /// Whether the scenario is running.
  bool get isRunning => status == TestStatus.running;

  /// Whether the scenario is pending.
  bool get isPending => status == TestStatus.pending;

  /// Reset the scenario and all its child test cases.
  void reset() {
    status = TestStatus.pending;
    startTime = null;
    endTime = null;
    for (final testCase in cases) {
      testCase.reset();
    }
  }

  /// Add a test case to this scenario.
  void addCase(TestCase testCase) {
    cases.add(testCase);
  }

  /// Serialize this scenario to JSON.
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
      'totalCaseCount': totalCaseCount,
      'passedCaseCount': passedCaseCount,
      'failedCaseCount': failedCaseCount,
      'totalStepCount': totalStepCount,
      'passedStepCount': passedStepCount,
      'failedStepCount': failedStepCount,
      'cases': cases.map((c) => c.toJson()).toList(),
    };
  }

  /// Create a [TestScenario] from JSON map.
  factory TestScenario.fromJson(Map<String, dynamic> json) {
    return TestScenario(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'Untitled Scenario',
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
      cases: (json['cases'] as List?)
              ?.map((c) => TestCase.fromJson(Map<String, dynamic>.from(c as Map)))
              .toList() ??
          [],
    );
  }

  @override
  String toString() => '$name (${cases.length} cases - ${status.name})';
}
