import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_visual_test_runner/src/controller/test_runner_controller.dart';
import 'package:flutter_visual_test_runner/src/engine/assertion_engine.dart';
import 'package:flutter_visual_test_runner/src/engine/step_execution_engine.dart';
import 'package:flutter_visual_test_runner/src/engine/widget_finder_engine.dart';
import 'package:flutter_visual_test_runner/src/models/target_finder.dart';
import 'package:flutter_visual_test_runner/src/models/test_case.dart';
import 'package:flutter_visual_test_runner/src/models/test_scenario.dart';
import 'package:flutter_visual_test_runner/src/models/test_step.dart';
import 'package:flutter_visual_test_runner/src/models/test_suite.dart';

void main() {
  group('Phase 2: WidgetFinderEngine & AssertionEngine Tests', () {
    testWidgets('WidgetFinderEngine locates widgets by Key, Text, Type, and Smart query',
        (tester) async {
      final phoneController = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('Welcome to Runner', key: Key('header_text')),
                TextField(
                  key: const Key('phone_input'),
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'Enter phone number',
                  ),
                ),
                ElevatedButton(
                  key: const Key('submit_btn'),
                  onPressed: () {},
                  child: const Text('Submit Now'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        // Find by Key
        final keyResult = WidgetFinderEngine.findFirst(TargetFinder.byKey('header_text'));
        expect(keyResult, isNotNull);
        expect(WidgetFinderEngine.extractTextFromElement(keyResult!.element), 'Welcome to Runner');

        // Find by Text
        final textResult = WidgetFinderEngine.findFirst(TargetFinder.byText('Submit Now'));
        expect(textResult, isNotNull);

        // Smart Lookup for Phone Number
        final smartResult = WidgetFinderEngine.findFirst(TargetFinder.smart('phone number'));
        expect(smartResult, isNotNull);

        // AssertionEngine expectVisible
        final visibleResult = await AssertionEngine.expectVisible(
          TargetFinder.byText('Welcome to Runner'),
        );
        expect(visibleResult, isNotNull);

        // AssertionEngine expectNotVisible
        await AssertionEngine.expectNotVisible(
          TargetFinder.byText('Non Existent Element'),
        );
      });
    });

    testWidgets('StepExecutionEngine runs tap, enterText, and assertion steps',
        (tester) async {
      final emailController = TextEditingController();
      bool buttonTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    TextField(
                      key: const Key('email_field'),
                      controller: emailController,
                      decoration: const InputDecoration(hintText: 'Your Email'),
                    ),
                    ElevatedButton(
                      key: const Key('action_btn'),
                      onPressed: () {
                        setState(() {
                          buttonTapped = true;
                        });
                      },
                      child: const Text('Tap Me'),
                    ),
                    if (buttonTapped)
                      const Text('Action Succeeded!', key: Key('success_label')),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final controller = TestRunnerController(initialSpeed: 4.0);
        controller.stepExecutor = StepExecutionEngine.executeStep;

        // 1. Enter Text Step
        final enterStep = TestStep.enterText(
          target: TargetFinder.byKey('email_field'),
          text: 'hello@world.com',
        );
        await controller.runStep(enterStep);
        expect(emailController.text, 'hello@world.com');

        // 2. Tap Step
        final tapStep = TestStep.tap(target: TargetFinder.byKey('action_btn'));
        await controller.runStep(tapStep);
      });

      await tester.pumpAndSettle();
      expect(buttonTapped, isTrue);

      await tester.runAsync(() async {
        final controller = TestRunnerController(initialSpeed: 4.0);
        controller.stepExecutor = StepExecutionEngine.executeStep;

        // 3. Expect Text Step
        final expectStep = TestStep.expectVisible(
          target: TargetFinder.byKey('success_label'),
        );
        await controller.runStep(expectStep);
        expect(expectStep.status.name, 'passed');
      });
    });

    testWidgets('Complete End-to-End Suite Run via Controller and StepExecutionEngine',
        (tester) async {
      int counter = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                appBar: AppBar(title: const Text('Counter App')),
                body: Center(
                  child: Text('Count: $counter', key: const Key('counter_val')),
                ),
                floatingActionButton: FloatingActionButton(
                  key: const Key('inc_btn'),
                  onPressed: () {
                    setState(() {
                      counter++;
                    });
                  },
                  child: const Icon(Icons.add),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final suite = TestSuite(
        name: 'Counter Suite',
        scenarios: [
          TestScenario(
            name: 'Increment Flow',
            cases: [
              TestCase(
                name: 'Increment counter test',
                steps: [
                  TestStep.expectText(
                    target: TargetFinder.byKey('counter_val'),
                    text: 'Count: 0',
                  ),
                  TestStep.tap(target: TargetFinder.byKey('inc_btn')),
                  TestStep.wait(const Duration(milliseconds: 50)),
                ],
              ),
            ],
          ),
        ],
      );

      await tester.runAsync(() async {
        final controller = TestRunnerController(initialSuite: suite, initialSpeed: 4.0);
        controller.stepExecutor = StepExecutionEngine.executeStep;

        final report = await controller.runAll();
        expect(report, isNotNull);
        expect(report!.isSuccess, isTrue);
        expect(report.passedCases, 1);
      });
    });
  });
}
