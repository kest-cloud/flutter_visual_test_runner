import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import '../utils/log_entry.dart';
import 'test_enums.dart';
import 'test_suite.dart';

/// Aggregated execution report detailing duration, pass/fail metrics, step traces, and logs.
class TestReport {
  final String id;
  final String suiteName;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final int totalScenarios;
  final int passedScenarios;
  final int failedScenarios;
  final int totalCases;
  final int passedCases;
  final int failedCases;
  final int totalSteps;
  final int passedSteps;
  final int failedSteps;
  final List<Map<String, dynamic>> scenarios;
  final List<RunnerLogEntry> logs;
  final Map<String, dynamic> environment;

  TestReport({
    String? id,
    required this.suiteName,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.totalScenarios,
    required this.passedScenarios,
    required this.failedScenarios,
    required this.totalCases,
    required this.passedCases,
    required this.failedCases,
    required this.totalSteps,
    required this.passedSteps,
    required this.failedSteps,
    required this.scenarios,
    required this.logs,
    Map<String, dynamic>? environment,
  })  : id = id ?? UniqueKey().toString(),
        environment = environment ?? _defaultEnvironment();

  /// Overall pass rate percentage (0.0% - 100.0%).
  double get passRatePercentage =>
      totalCases == 0 ? 100.0 : (passedCases / totalCases) * 100.0;

  /// Whether the entire suite passed.
  bool get isSuccess => failedCases == 0 && failedScenarios == 0;

  /// Generate a report from an executed [TestSuite].
  factory TestReport.fromSuite({
    required TestSuite suite,
    required DateTime startTime,
    required DateTime endTime,
    required List<RunnerLogEntry> logs,
  }) {
    int totalScenarios = suite.scenarios.length;
    int passedScenarios =
        suite.scenarios.where((s) => s.status == TestStatus.passed).length;
    int failedScenarios =
        suite.scenarios.where((s) => s.status == TestStatus.failed).length;

    int totalCases = suite.totalCaseCount;
    int passedCases = suite.passedCaseCount;
    int failedCases = suite.failedCaseCount;

    int totalSteps = suite.totalStepCount;
    int passedSteps = 0;
    int failedSteps = 0;

    for (final s in suite.scenarios) {
      for (final c in s.cases) {
        for (final st in c.steps) {
          if (st.status == TestStatus.passed) passedSteps++;
          if (st.status == TestStatus.failed) failedSteps++;
        }
      }
    }

    return TestReport(
      suiteName: suite.name,
      startTime: startTime,
      endTime: endTime,
      duration: endTime.difference(startTime),
      totalScenarios: totalScenarios,
      passedScenarios: passedScenarios,
      failedScenarios: failedScenarios,
      totalCases: totalCases,
      passedCases: passedCases,
      failedCases: failedCases,
      totalSteps: totalSteps,
      passedSteps: passedSteps,
      failedSteps: failedSteps,
      scenarios: suite.scenarios.map((s) => s.toJson()).toList(),
      logs: List.from(logs),
    );
  }

  static Map<String, dynamic> _defaultEnvironment() {
    return {
      'platform': kIsWeb ? 'web' : Platform.operatingSystem,
      'isRelease': kReleaseMode,
      'isProfile': kProfileMode,
      'isDebug': kDebugMode,
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'suiteName': suiteName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'durationMs': duration.inMilliseconds,
      'isSuccess': isSuccess,
      'passRatePercentage': passRatePercentage,
      'summary': {
        'totalScenarios': totalScenarios,
        'passedScenarios': passedScenarios,
        'failedScenarios': failedScenarios,
        'totalCases': totalCases,
        'passedCases': passedCases,
        'failedCases': failedCases,
        'totalSteps': totalSteps,
        'passedSteps': passedSteps,
        'failedSteps': failedSteps,
      },
      'environment': environment,
      'scenarios': scenarios,
      'logs': logs.map((l) => l.toJson()).toList(),
    };
  }

  /// Output formatted JSON string.
  String toFormattedJson() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(toJson());
  }

  factory TestReport.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    return TestReport(
      id: json['id'] as String?,
      suiteName: json['suiteName'] as String? ?? 'Test Report',
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
      totalScenarios: summary['totalScenarios'] as int? ?? 0,
      passedScenarios: summary['passedScenarios'] as int? ?? 0,
      failedScenarios: summary['failedScenarios'] as int? ?? 0,
      totalCases: summary['totalCases'] as int? ?? 0,
      passedCases: summary['passedCases'] as int? ?? 0,
      failedCases: summary['failedCases'] as int? ?? 0,
      totalSteps: summary['totalSteps'] as int? ?? 0,
      passedSteps: summary['passedSteps'] as int? ?? 0,
      failedSteps: summary['failedSteps'] as int? ?? 0,
      scenarios: (json['scenarios'] as List?)
              ?.map((s) => Map<String, dynamic>.from(s as Map))
              .toList() ??
          [],
      logs: (json['logs'] as List?)
              ?.map((l) => RunnerLogEntry.fromJson(Map<String, dynamic>.from(l as Map)))
              .toList() ??
          [],
      environment: (json['environment'] as Map<String, dynamic>?) ?? {},
    );
  }
}
