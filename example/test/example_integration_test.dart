import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_visual_test_runner/flutter_visual_test_runner.dart';
import 'package:flutter_visual_test_runner_example/main.dart';
import 'package:flutter_visual_test_runner_example/test_suites/app_test_scenarios.dart';

void main() {
  group('Example App End-to-End Visual Test Run', () {
    testWidgets('Executes full example suite through VisualTestRunner',
        (tester) async {
      final controller = TestRunnerController(
        initialSuite: exampleAppTestSuite,
        initialSpeed: 4.0,
      );

      await tester.pumpWidget(
        VisualTestRunner(
          controller: controller,
          child: const ExampleEcommerceApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Check Login screen is shown
      expect(find.text('Welcome Back'), findsOneWidget);

      await tester.runAsync(() async {
        // Step 1: Enter invalid phone number
        final step1 = TestStep.enterText(
          target: TargetFinder.byKey('phone_input'),
          text: '123',
        );
        await controller.runStep(step1);
      });
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        // Step 2: Tap Sign In
        final step2 = TestStep.tap(target: TargetFinder.byKey('login_btn'));
        await controller.runStep(step2);
      });
      await tester.pumpAndSettle();

      // Verify validation error
      expect(find.text('Phone number must be at least 10 digits'), findsOneWidget);

      await tester.runAsync(() async {
        // Step 3: Enter valid phone number
        final step3 = TestStep.enterText(
          target: TargetFinder.byKey('phone_input'),
          text: '08012345678',
        );
        await controller.runStep(step3);
      });
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        // Step 4: Enter password
        final step4 = TestStep.enterText(
          target: TargetFinder.byKey('password_input'),
          text: 'SecretPass123!',
        );
        await controller.runStep(step4);
      });
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        // Step 5: Tap Sign In
        final step5 = TestStep.tap(target: TargetFinder.byKey('login_btn'));
        await controller.runStep(step5);
      });
      await tester.pumpAndSettle();

      // Check navigation to Dashboard
      expect(find.text('Store Dashboard'), findsOneWidget);

      await tester.runAsync(() async {
        // Step 6: Tap Add to Cart for Item #1
        final step6 = TestStep.tap(target: TargetFinder.byKey('add_btn_1'));
        await controller.runStep(step6);
      });
      await tester.pumpAndSettle();

      expect(find.text('1'), findsWidgets); // Cart badge
    });
  });
}

