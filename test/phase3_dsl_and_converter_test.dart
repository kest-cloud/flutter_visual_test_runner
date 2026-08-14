import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_visual_test_runner/flutter_visual_test_runner.dart';

void main() {
  group('TestCaseConverter & Loose Intent Parser Tests', () {
    test('Converts ultra-simple shorthand test names into full canonical test steps', () {
      const looseInput = '''
test login
test dashboard
test add to cart
''';

      final canonical = TestCaseConverter.convert(looseInput);
      expect(canonical, contains('## Test: test login'));
      expect(canonical, contains('- Enter "08012345678" into phone_input'));
      expect(canonical, contains('- Enter "Secret123" into password_input'));
      expect(canonical, contains('- Tap "Sign In"'));
      expect(canonical, contains('## Test: test dashboard'));
      expect(canonical, contains('- Expect "Store Dashboard" to be visible'));
      expect(canonical, contains('## Test: test add to cart'));
      expect(canonical, contains('- Tap "add_btn_1"'));

      final suite = TestCaseConverter.toTestSuite(looseInput);
      expect(suite.scenarios, isNotEmpty);
      expect(suite.totalCaseCount, 3);
    });

    test('Converts parameterized informal commands into canonical steps', () {
      const looseInput = '''
# Scenario: Custom Flow
## Test: customized auth
type "1234567890" in phone_input
type "MyPassword" in password_input
click Sign In
see Store Dashboard
''';

      final canonical = TestCaseConverter.convert(looseInput);
      expect(canonical, contains('- Enter "1234567890" into phone_input'));
      expect(canonical, contains('- Enter "MyPassword" into password_input'));
      expect(canonical, contains('- Tap "Sign In"'));
      expect(canonical, contains('- Expect "Store Dashboard" to be visible'));
    });

    test('Supports registering custom domain-specific templates', () {
      TestCaseConverter.registerTemplate(
        RegExp(r'checkout with coupon (.+)', caseSensitive: false),
        (m) => [
          '- Enter "${m.group(1)}" into coupon_input',
          '- Tap "Apply Coupon"',
          '- Tap "Checkout"',
          '- Expect "Order Summary" to be visible',
        ],
      );

      const input = '''
## Test: checkout flow
checkout with coupon SAVE50
''';

      final canonical = TestCaseConverter.convert(input);
      expect(canonical, contains('- Enter "SAVE50" into coupon_input'));
      expect(canonical, contains('- Tap "Apply Coupon"'));
      expect(canonical, contains('- Tap "Checkout"'));
      expect(canonical, contains('- Expect "Order Summary" to be visible'));
    });
  });
}
