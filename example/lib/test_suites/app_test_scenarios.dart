import 'package:flutter_visual_test_runner/flutter_visual_test_runner.dart';

/// Central single-file test suite definition for the example application.
final exampleAppTestSuite = TestSuite(
  name: 'E-Commerce Mobile App Test Suite',
  description: 'Full visual verification suite for Auth, Form Validation, and Catalog Auto-Scrolling',
  defaultTimeout: const Duration(seconds: 5),
  autoScrollToTarget: true,
  adaptiveWait: true,
  scenarios: [
    // -------------------------------------------------------------
    // Scenario 1: Authentication & Form Validation
    // -------------------------------------------------------------
    TestScenario(
      name: 'Authentication & Form Validation',
      tags: ['@smoke', '@auth'],
      cases: [
        TestCase(
          name: 'test for required phonenumber length',
          description: 'Validates that short phone numbers show an error message',
          tags: ['@auth', '@validation'],
          steps: [
            // 1. Enter invalid short phone number
            TestStep.enterText(
              target: TargetFinder.byKey('phone_input', description: 'Phone Number Field'),
              text: '123',
              description: 'Enter "123" into phone number',
            ),

            // 2. Tap Sign In
            TestStep.tap(
              target: TargetFinder.byKey('login_btn', description: 'Sign In Button'),
              description: 'Tap "Sign In"',
            ),

            // 3. Verify validation error message is visible
            TestStep.expectVisible(
              target: TargetFinder.byText(
                'Phone number must be at least 10 digits',
                description: 'Validation Error Message',
              ),
              description: 'Expect "Phone number must be at least 10 digits" to be visible',
            ),
          ],
        ),
        TestCase(
          name: 'test for successful sign in',
          description: 'Validates complete login flow and navigation to Dashboard',
          tags: ['@auth', '@smoke'],
          steps: [
            // 1. Enter valid phone number
            TestStep.enterText(
              target: TargetFinder.byKey('phone_input', description: 'Phone Number Field'),
              text: '08012345678',
              description: 'Enter "08012345678" into phone number',
            ),

            // 2. Enter password
            TestStep.enterText(
              target: TargetFinder.byKey('password_input', description: 'Password Field'),
              text: 'SecretPass123!',
              description: 'Enter password',
            ),

            // 3. Tap Sign In
            TestStep.tap(
              target: TargetFinder.byKey('login_btn', description: 'Sign In Button'),
              description: 'Tap "Sign In"',
            ),

            // 4. Verify Dashboard header is visible
            TestStep.expectVisible(
              target: TargetFinder.byText('Store Dashboard'),
              timeout: const Duration(seconds: 4),
              description: 'Expect "Store Dashboard" to be visible',
            ),
          ],
        ),
      ],
    ),

    // -------------------------------------------------------------
    // Scenario 2: Catalog Auto-Scroll & Cart Interaction
    // -------------------------------------------------------------
    TestScenario(
      name: 'Catalog Auto-Scroll & Cart Interaction',
      tags: ['@catalog', '@cart'],
      cases: [
        TestCase(
          name: 'Add Off-Screen Item #12 to Cart',
          description: 'Tests that the runner automatically scrolls down to off-screen Item #12 and taps it',
          tags: ['@catalog'],
          steps: [
            // Runner is intelligent: Item #12 is offscreen, so it automatically scrolls into view!
            TestStep.tap(
              target: TargetFinder.byKey('add_btn_12', description: 'Item #12 Add Button'),
              description: 'Tap Add to Cart for Product #12',
            ),

            // Verify Cart Badge updates to 1
            TestStep.expectVisible(
              target: TargetFinder.byKey('cart_badge'),
              description: 'Verify Cart Badge is visible',
            ),
            TestStep.expectText(
              target: TargetFinder.byKey('cart_badge'),
              text: '1',
              description: 'Expect cart badge count is "1"',
            ),
          ],
        ),
        TestCase(
          name: 'Add Deep Off-Screen Item #18 to Cart',
          description: 'Tests deep scroll down the catalog list to Item #18',
          tags: ['@catalog'],
          steps: [
            TestStep.tap(
              target: TargetFinder.byKey('add_btn_18', description: 'Item #18 Add Button'),
              description: 'Tap Add to Cart for Product #18',
            ),

            // Verify Cart Badge updates to 2
            TestStep.expectText(
              target: TargetFinder.byKey('cart_badge'),
              text: '2',
              description: 'Expect cart badge count is "2"',
            ),
          ],
        ),
      ],
    ),
  ],
);
