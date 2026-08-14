import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_visual_test_runner/src/controller/test_runner_controller.dart';
import 'package:flutter_visual_test_runner/src/controller/test_runner_state.dart';
import 'package:flutter_visual_test_runner/src/dsl/natural_language_test_parser.dart';
import 'package:flutter_visual_test_runner/src/models/target_finder.dart';
import 'package:flutter_visual_test_runner/src/models/test_case.dart';
import 'package:flutter_visual_test_runner/src/models/test_enums.dart';
import 'package:flutter_visual_test_runner/src/models/test_scenario.dart';
import 'package:flutter_visual_test_runner/src/models/test_step.dart';
import 'package:flutter_visual_test_runner/src/models/test_suite.dart';

void main() {
  group('Phase 1: TargetFinder & Models Tests', () {
    test('TargetFinder creates and serializes correctly', () {
      final keyFinder = TargetFinder.byKey('submit_btn');
      expect(keyFinder.type, FinderType.byKey);
      expect(keyFinder.value, 'submit_btn');

      final json = keyFinder.toJson();
      final reconstructed = TargetFinder.fromJson(json);
      expect(reconstructed.type, FinderType.byKey);
      expect(reconstructed.value, 'submit_btn');

      final smartFinder = TargetFinder.smart('phone number');
      expect(smartFinder.type, FinderType.smart);
      expect(smartFinder.value, 'phone number');
    });

    test('TestStep serialization and factory helpers', () {
      final step = TestStep.enterText(
        target: TargetFinder.byKey('email_input'),
        text: 'test@example.com',
      );
      expect(step.type, TestStepType.enterText);
      expect(step.text, 'test@example.com');
      expect(step.status, TestStatus.pending);

      final json = step.toJson();
      final fromJson = TestStep.fromJson(json);
      expect(fromJson.type, TestStepType.enterText);
      expect(fromJson.text, 'test@example.com');
    });

    test('TestCase and TestScenario count metrics', () {
      final step1 = TestStep.tap(target: TargetFinder.byText('Login'));
      final step2 =
          TestStep.expectVisible(target: TargetFinder.byText('Dashboard'));

      final testCase = TestCase(
        name: 'Login Case',
        tags: ['@smoke'],
        steps: [step1, step2],
      );
      expect(testCase.totalStepCount, 2);
      expect(testCase.passedStepCount, 0);

      final scenario = TestScenario(
        name: 'Auth Scenario',
        tags: ['@auth'],
        cases: [testCase],
      );
      expect(scenario.totalCaseCount, 1);
      expect(scenario.totalStepCount, 2);
    });
  });

  group('Phase 1: Natural Language Test Parser', () {
    test('Parses plain English markdown/text into scenarios and cases', () {
      const rawText = '''
# Scenario: Phone Number Verification @smoke
## Test: test for required phonenumber length
- Enter "123" into phone number
- Tap "Continue"
- Expect "Phone number must be at least 10 digits" to be visible

## Test: test for successful sign in
- Enter "08012345678" into phone number
- Tap "Continue"
- Enter "1234" into otp
- Tap "Verify"
- Expect "Welcome back" to be visible
''';

      final scenarios = NaturalLanguageTestParser.parse(rawText);
      expect(scenarios.length, 1);

      final scenario = scenarios.first;
      expect(scenario.name, 'Phone Number Verification');
      expect(scenario.tags, contains('@smoke'));
      expect(scenario.cases.length, 2);

      final case1 = scenario.cases[0];
      expect(case1.name, 'test for required phonenumber length');
      expect(case1.steps.length, 3);
      expect(case1.steps[0].type, TestStepType.enterText);
      expect(case1.steps[0].text, '123');
      expect(case1.steps[1].type, TestStepType.tap);
      expect(case1.steps[2].type, TestStepType.expectVisible);

      final case2 = scenario.cases[1];
      expect(case2.name, 'test for successful sign in');
      expect(case2.steps.length, 5);
    });

    test('TestSuite.fromNaturalLanguage creates complete suite', () {
      const text = '''
Scenario: User Onboarding
  Case: Simple Flow
    - Tap "Get Started"
    - Wait 500ms
    - Expect "Choose Plan"
''';
      final suite =
          TestSuite.fromNaturalLanguage(text, name: 'Onboarding Suite');
      expect(suite.name, 'Onboarding Suite');
      expect(suite.scenarios.length, 1);
      expect(suite.totalCaseCount, 1);
      expect(suite.totalStepCount, 3);
    });
  });

  group('Phase 1: TestRunnerController Lifecycle & Speed', () {
    test('Executes test suite and generates TestReport', () async {
      final suite = TestSuite(
        name: 'Mock Suite',
        scenarios: [
          TestScenario(
            name: 'Mock Scenario',
            cases: [
              TestCase(
                name: 'Mock Case',
                steps: [
                  TestStep.wait(const Duration(milliseconds: 10)),
                  TestStep.wait(const Duration(milliseconds: 10)),
                ],
              ),
            ],
          ),
        ],
      );

      final controller = TestRunnerController(
        initialSuite: suite,
        initialSpeed: 4.0,
      );

      expect(controller.executionState, RunnerExecutionState.idle);

      final report = await controller.runAll();
      expect(report, isNotNull);
      expect(report!.isSuccess, isTrue);
      expect(report.passedCases, 1);
      expect(report.passedSteps, 2);
      expect(controller.executionState, RunnerExecutionState.completed);
    });

    test('Speed control adjustment', () {
      final controller = TestRunnerController(initialSpeed: 2.0);
      expect(controller.speedMultiplier, 2.0);

      final adjusted =
          controller.adjustDuration(const Duration(milliseconds: 1000));
      expect(adjusted.inMilliseconds, 500);

      controller.setSpeedMultiplier(4.0);
      expect(controller.speedMultiplier, 4.0);
      final adjusted4x =
          controller.adjustDuration(const Duration(milliseconds: 1000));
      expect(adjusted4x.inMilliseconds, 250);
    });

    test('Tag filtering only runs tagged cases', () async {
      final case1 = TestCase(
        name: 'Smoke Case',
        tags: ['@smoke'],
        steps: [TestStep.wait(const Duration(milliseconds: 10))],
      );
      final case2 = TestCase(
        name: 'Other Case',
        tags: ['@other'],
        steps: [TestStep.wait(const Duration(milliseconds: 10))],
      );

      final suite = TestSuite(
        name: 'Tag Suite',
        scenarios: [
          TestScenario(name: 'Scenario', cases: [case1, case2]),
        ],
      );

      final controller =
          TestRunnerController(initialSuite: suite, initialSpeed: 4.0);
      controller.setFilterTag('@smoke');

      await controller.runAll();

      expect(case1.status, TestStatus.passed);
      expect(case2.status, TestStatus.pending);
    });
  });
}
