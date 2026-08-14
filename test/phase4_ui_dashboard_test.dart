import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_visual_test_runner/flutter_visual_test_runner.dart';

void main() {
  group('Phase 3 & 4: Visual Overlay & Dashboard UI Tests', () {
    testWidgets('VisualTestRunner wraps app and displays floating badge and overlay',
        (tester) async {
      final suite = TestSuite(
        name: 'UI Demo Suite',
        scenarios: [
          TestScenario(
            name: 'Demo Scenario',
            cases: [
              TestCase(
                name: 'Sample Case',
                steps: [
                  TestStep.tap(target: TargetFinder.byKey('demo_btn')),
                ],
              ),
            ],
          ),
        ],
      );

      final controller = TestRunnerController(initialSuite: suite);

      await tester.pumpWidget(
        MaterialApp(
          home: VisualTestRunner(
            controller: controller,
            child: Scaffold(
              body: Center(
                child: ElevatedButton(
                  key: const Key('demo_btn'),
                  onPressed: () {},
                  child: const Text('Demo Button'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check floating badge is rendered
      expect(find.byType(FloatingBadge), findsOneWidget);

      // Tap floating badge to expand dashboard
      await tester.tap(find.byType(FloatingBadge));
      await tester.pumpAndSettle();

      // Check Dashboard is expanded
      expect(controller.state.isDashboardExpanded, isTrue);
      expect(find.text('VISUAL TEST RUNNER'), findsOneWidget);
      expect(find.text('RUN ALL SUITE'), findsOneWidget);
    });
  });
}
