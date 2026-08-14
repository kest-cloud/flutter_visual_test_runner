import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_visual_test_runner/flutter_visual_test_runner.dart';

void main() {
  group('Phase 5: TestSpecParser & TestReportExporter Tests', () {
    test('TestSpecParser parses YAML test specification', () {
      const yamlContent = '''
name: "E-Commerce App Tests"
defaultTimeoutMs: 6000
autoScrollToTarget: true
scenarios:
  - name: "Authentication"
    tags: ["@auth", "@smoke"]
    cases:
      - name: "Successful Sign In"
        steps:
          - type: "enterText"
            target:
              type: "byKey"
              value: "phone_field"
            text: "08012345678"
          - type: "tap"
            target:
              type: "byText"
              value: "Continue"
          - type: "expectVisible"
            target:
              type: "byText"
              value: "Dashboard"
''';

      final suite = TestSpecParser.parseYaml(yamlContent);
      expect(suite.name, 'E-Commerce App Tests');
      expect(suite.defaultTimeout.inSeconds, 6);
      expect(suite.scenarios.length, 1);

      final scenario = suite.scenarios.first;
      expect(scenario.name, 'Authentication');
      expect(scenario.tags, contains('@auth'));
      expect(scenario.cases.length, 1);

      final testCase = scenario.cases.first;
      expect(testCase.name, 'Successful Sign In');
      expect(testCase.steps.length, 3);
      expect(testCase.steps[0].type, TestStepType.enterText);
      expect(testCase.steps[0].text, '08012345678');
      expect(testCase.steps[0].target?.value, 'phone_field');
    });

    test('TestReportExporter generates valid JSON and HTML reports', () {
      final step = TestStep.tap(target: TargetFinder.byText('Sign In'));
      step.status = TestStatus.passed;

      final testCase = TestCase(
        name: 'Login Case',
        steps: [step],
        status: TestStatus.passed,
      );

      final scenario = TestScenario(
        name: 'Auth Scenario',
        cases: [testCase],
        status: TestStatus.passed,
      );

      final suite = TestSuite(
        name: 'Main Suite',
        scenarios: [scenario],
      );

      final report = TestReport.fromSuite(
        suite: suite,
        startTime: DateTime.now().subtract(const Duration(seconds: 2)),
        endTime: DateTime.now(),
        logs: [
          RunnerLogEntry(level: RunnerLogLevel.info, message: 'Starting tests'),
          RunnerLogEntry(level: RunnerLogLevel.success, message: 'All passed'),
        ],
      );

      final jsonStr = TestReportExporter.toJson(report);
      expect(jsonStr, contains('Main Suite'));
      expect(jsonStr, contains('passRatePercentage'));

      final htmlStr = TestReportExporter.toHtml(report);
      expect(htmlStr, contains('<!DOCTYPE html>'));
      expect(htmlStr, contains('Main Suite'));
      expect(htmlStr, contains('PASSED'));
      expect(htmlStr, contains('All passed'));
    });
  });
}
