import 'package:flutter/widgets.dart';
import '../dsl/natural_language_test_parser.dart';
import 'test_enums.dart';
import 'test_scenario.dart';

/// Top-level test suite container representing an entire test specification or manifest file.
class TestSuite {
  /// Unique identifier for this test suite.
  final String id;

  /// Display name of the test suite (e.g. "Main Mobile App Test Suite").
  final String name;

  /// Optional description.
  final String? description;

  /// List of test scenarios contained in this suite.
  final List<TestScenario> scenarios;

  /// Default timeout for assertion checks and widget searches.
  final Duration defaultTimeout;

  /// Whether the runner should automatically scroll off-screen widgets into view.
  final bool autoScrollToTarget;

  /// Whether the runner should adaptively poll and wait for async frames and navigation transitions.
  final bool adaptiveWait;

  /// Metadata / configuration attributes.
  final Map<String, dynamic> metadata;

  TestSuite({
    String? id,
    required this.name,
    this.description,
    List<TestScenario>? scenarios,
    this.defaultTimeout = const Duration(seconds: 5),
    this.autoScrollToTarget = true,
    this.adaptiveWait = true,
    Map<String, dynamic>? metadata,
  })  : id = id ?? UniqueKey().toString(),
        scenarios = scenarios ?? [],
        metadata = metadata ?? {};

  /// Create a [TestSuite] from natural English text or markdown.
  /// Example:
  /// ```dart
  /// final suite = TestSuite.fromNaturalLanguage('''
  ///   Scenario: Authentication
  ///     Case: Test for required phonenumber length
  ///       - Enter "123" into phone number
  ///       - Tap "Continue"
  ///       - Expect "Phone number too short" to be visible
  /// ''');
  /// ```
  factory TestSuite.fromNaturalLanguage(
    String naturalLanguageText, {
    String? name,
    String? description,
    Duration defaultTimeout = const Duration(seconds: 5),
    bool autoScrollToTarget = true,
    bool adaptiveWait = true,
  }) {
    final parsedScenarios =
        NaturalLanguageTestParser.parse(naturalLanguageText);
    return TestSuite(
      name: name ?? 'Natural Language Test Suite',
      description: description,
      scenarios: parsedScenarios,
      defaultTimeout: defaultTimeout,
      autoScrollToTarget: autoScrollToTarget,
      adaptiveWait: adaptiveWait,
    );
  }

  /// Total number of scenarios.
  int get totalScenarioCount => scenarios.length;

  /// Total number of test cases across all scenarios.
  int get totalCaseCount =>
      scenarios.fold<int>(0, (sum, s) => sum + s.totalCaseCount);

  /// Total number of steps across all test cases.
  int get totalStepCount =>
      scenarios.fold<int>(0, (sum, s) => sum + s.totalStepCount);

  /// Total number of passed test cases.
  int get passedCaseCount =>
      scenarios.fold<int>(0, (sum, s) => sum + s.passedCaseCount);

  /// Total number of failed test cases.
  int get failedCaseCount =>
      scenarios.fold<int>(0, (sum, s) => sum + s.failedCaseCount);

  /// Overall status of the suite.
  TestStatus get status {
    if (scenarios.any((s) => s.status == TestStatus.failed)) {
      return TestStatus.failed;
    }
    if (scenarios.any((s) => s.status == TestStatus.running)) {
      return TestStatus.running;
    }
    if (scenarios.isNotEmpty &&
        scenarios.every((s) => s.status == TestStatus.passed)) {
      return TestStatus.passed;
    }
    return TestStatus.pending;
  }

  /// Reset all scenarios, cases, and steps in this suite.
  void reset() {
    for (final scenario in scenarios) {
      scenario.reset();
    }
  }

  /// Add a scenario to this suite.
  void addScenario(TestScenario scenario) {
    scenarios.add(scenario);
  }

  /// Serialize this test suite to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'defaultTimeoutMs': defaultTimeout.inMilliseconds,
      'autoScrollToTarget': autoScrollToTarget,
      'adaptiveWait': adaptiveWait,
      'metadata': metadata,
      'totalScenarioCount': totalScenarioCount,
      'totalCaseCount': totalCaseCount,
      'totalStepCount': totalStepCount,
      'passedCaseCount': passedCaseCount,
      'failedCaseCount': failedCaseCount,
      'status': status.name,
      'scenarios': scenarios.map((s) => s.toJson()).toList(),
    };
  }

  /// Create a [TestSuite] from JSON map.
  factory TestSuite.fromJson(Map<String, dynamic> json) {
    return TestSuite(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'Test Suite',
      description: json['description'] as String?,
      defaultTimeout: json['defaultTimeoutMs'] != null
          ? Duration(milliseconds: json['defaultTimeoutMs'] as int)
          : const Duration(seconds: 5),
      autoScrollToTarget: json['autoScrollToTarget'] as bool? ?? true,
      adaptiveWait: json['adaptiveWait'] as bool? ?? true,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      scenarios: (json['scenarios'] as List?)
              ?.map((s) => TestScenario.fromJson(Map<String, dynamic>.from(s as Map)))
              .toList() ??
          [],
    );
  }

  @override
  String toString() => '$name (${scenarios.length} scenarios, $totalCaseCount cases)';
}
