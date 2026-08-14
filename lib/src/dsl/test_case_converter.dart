import '../models/test_suite.dart';

/// Intelligent converter that transforms loose, high-level, or informal user test descriptions
/// (e.g. `test login`, `test dashboard`, `test add to cart`, shorthand commands, or conversational steps)
/// into canonical, structured, and executable Visual Test Runner specifications.
class TestCaseConverter {
  /// User-customizable intent templates for app-specific shortcuts.
  static final Map<Pattern, List<String> Function(Match match)>
      _customTemplates = {};

  /// Register a custom shorthand pattern to expand into structured test steps.
  ///
  /// Example:
  /// ```dart
  /// TestCaseConverter.registerTemplate(
  ///   RegExp(r'checkout with coupon (.+)', caseSensitive: false),
  ///   (m) => [
  ///     '- Enter "${m.group(1)}" into coupon_input',
  ///     '- Tap "Apply Coupon"',
  ///     '- Tap "Checkout"',
  ///     '- Expect "Order Summary" to be visible',
  ///   ],
  /// );
  /// ```
  static void registerTemplate(
    Pattern pattern,
    List<String> Function(Match match) expander,
  ) {
    _customTemplates[pattern] = expander;
  }

  /// Convert informal/loose user text into a canonical formatted test spec markdown string.
  static String convert(
    String looseText, {
    String defaultScenarioName = 'App User Journey Flow',
    String? scenarioTags = '@smoke',
  }) {
    final cleanInput = looseText.trim();
    if (cleanInput.isEmpty) return '';

    final buffer = StringBuffer();
    bool hasScenarioHeader = false;

    final lines = cleanInput.split('\n');
    String? currentTestName;
    final currentSteps = <String>[];

    void ensureScenarioHeader() {
      if (!hasScenarioHeader) {
        buffer
            .writeln('# Scenario: $defaultScenarioName ${scenarioTags ?? ""}');
        buffer.writeln();
        hasScenarioHeader = true;
      }
    }

    void flushCurrentTest() {
      if (currentTestName != null) {
        if (currentSteps.isEmpty) {
          final expanded = _expandBuiltinShortcut(currentTestName!);
          currentSteps.addAll(expanded);
        }
        if (currentSteps.isNotEmpty) {
          ensureScenarioHeader();
          buffer.writeln('## Test: $currentTestName');
          for (final step in currentSteps) {
            buffer.writeln(step.startsWith('- ') ? step : '- $step');
          }
          buffer.writeln();
        }
        currentSteps.clear();
        currentTestName = null;
      }
    }

    for (var rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('//')) continue;

      // Check if line declares a new scenario
      if (line.toLowerCase().startsWith('scenario:') || line.startsWith('# ')) {
        flushCurrentTest();
        var scName = line
            .replaceFirst(
                RegExp(r'^(#+\s*(scenario:)?|scenario:)\s*',
                    caseSensitive: false),
                '')
            .trim();
        buffer.writeln('# Scenario: $scName');
        buffer.writeln();
        hasScenarioHeader = true;
        continue;
      }

      // Check if line is a test case title declaration (e.g. "## Test: ...", "test login", "test dashboard")
      if (_isTestTitle(line)) {
        flushCurrentTest();
        currentTestName = _cleanTestTitle(line);
        continue;
      }

      // Check custom registered templates
      bool matchedCustom = false;
      for (final entry in _customTemplates.entries) {
        final match = entry.key.allMatches(line).firstOrNull;
        if (match != null) {
          final expanded = entry.value(match);
          currentTestName ??= _humanizeTitle(line);
          currentSteps.addAll(expanded);
          matchedCustom = true;
          break;
        }
      }
      if (matchedCustom) continue;

      // Expand natural language shorthand / action line into canonical steps
      final expandedSteps = _expandActionLine(line);
      if (expandedSteps.isNotEmpty) {
        currentTestName ??= _inferTestNameFromStep(line);
        currentSteps.addAll(expandedSteps);
      }
    }

    flushCurrentTest();

    return buffer.toString().trim();
  }

  /// Directly convert loose user text into an executable [TestSuite].
  static TestSuite toTestSuite(
    String looseText, {
    String suiteName = 'App Test Suite',
    String? scenarioTags = '@smoke',
  }) {
    final canonicalMarkdown = convert(
      looseText,
      defaultScenarioName: suiteName,
      scenarioTags: scenarioTags,
    );
    return TestSuite.fromNaturalLanguage(canonicalMarkdown, name: suiteName);
  }

  static bool _isTestTitle(String line) {
    final lower = line.toLowerCase();
    return line.startsWith('## ') ||
        lower.startsWith('test:') ||
        lower.startsWith('case:') ||
        lower.startsWith('test ') ||
        lower.startsWith('should ') ||
        lower == 'test login' ||
        lower == 'test dashboard' ||
        lower == 'test add to cart' ||
        lower == 'test cart';
  }

  static String _cleanTestTitle(String line) {
    var title = line;
    if (title.startsWith('## ')) title = title.substring(3);
    title = title.replaceFirst(
        RegExp(r'^(test|case):\s*', caseSensitive: false), '');
    title = title.trim();
    if (!title.toLowerCase().startsWith('test ') &&
        !title.toLowerCase().startsWith('should ')) {
      title = 'test $title';
    }
    return title;
  }

  static String _humanizeTitle(String line) {
    final clean = line.replaceAll(RegExp(r'^[-*0-9.]+\s*'), '').trim();
    return clean.isNotEmpty ? 'test $clean' : 'test flow';
  }

  static String _inferTestNameFromStep(String line) {
    final lower = line.toLowerCase();
    if (lower.contains('login') || lower.contains('sign in')) {
      return 'test authentication flow';
    }
    if (lower.contains('cart') || lower.contains('product')) {
      return 'test shopping cart flow';
    }
    if (lower.contains('dashboard') || lower.contains('home')) {
      return 'test dashboard view';
    }
    return 'test ${_cleanTargetToken(line)}';
  }

  /// Expands built-in high-level intent shortcuts (e.g. `test login`, `test add to cart`).
  static List<String> _expandBuiltinShortcut(String title) {
    final lower = title.toLowerCase();

    // 1. Full Login with Credentials: e.g. "test login with phone 080... and password Secret123"
    final loginCredsMatch = RegExp(
      r'login\s+with\s+(?:phone|number|email|user)?\s*([^\s]+)\s+and\s+(?:password|pass)?\s*([^\s]+)',
      caseSensitive: false,
    ).firstMatch(lower);
    if (loginCredsMatch != null) {
      final phone = loginCredsMatch.group(1)!;
      final pass = loginCredsMatch.group(2)!;
      return [
        '- Enter "$phone" into phone_input',
        '- Enter "$pass" into password_input',
        '- Tap "Sign In"',
        '- Expect "Store Dashboard" to be visible',
        '- Expect "Welcome back" to be visible',
      ];
    }

    // 2. Generic "test login" or "test sign in"
    if (lower == 'test login' ||
        lower == 'test sign in' ||
        lower == 'login flow') {
      return [
        '- Enter "08012345678" into phone_input',
        '- Enter "Secret123" into password_input',
        '- Tap "Sign In"',
        '- Expect "Store Dashboard" to be visible',
        '- Expect "Welcome back, Alex!" to be visible',
      ];
    }

    // 3. Short / Invalid Phone Negative Test: e.g. "test short phone validation"
    if (lower.contains('short phone') || lower.contains('invalid phone')) {
      return [
        '- Enter "123" into phone_input',
        '- Tap "Sign In"',
        '- Expect "Phone number must be at least 10 digits" to be visible',
      ];
    }

    // 4. Missing Password Negative Test: e.g. "test missing password"
    if (lower.contains('missing password') ||
        lower.contains('empty password')) {
      return [
        '- Enter "08012345678" into phone_input',
        '- Tap "Sign In"',
        '- Expect "Password is required" to be visible',
      ];
    }

    // 5. Generic "test dashboard"
    if (lower == 'test dashboard' ||
        lower == 'test store dashboard' ||
        lower == 'dashboard metrics') {
      return [
        '- Expect "Store Dashboard" to be visible',
        '- Expect "Revenue" to be visible',
        '- Expect "Product Catalog" to be visible',
        '- Expect "Product Item #1" to be visible',
      ];
    }

    // 6. Generic "test add to cart" or "test cart"
    if (lower == 'test add to cart' ||
        lower == 'test cart' ||
        lower == 'add to cart flow') {
      return [
        '- Tap "add_btn_1"',
        '- Expect "Added ✓" to be visible',
        '- Expect "cart_badge" to be visible',
        '- Tap "add_btn_2"',
        '- Expect "cart_badge" to be visible',
      ];
    }

    return [];
  }

  /// Converts an individual unstructured user line into canonical step(s).
  static List<String> _expandActionLine(String line) {
    var clean = line.replaceAll(RegExp(r'^[-*0-9.]+\s*'), '').trim();
    if (clean.isEmpty) return [];

    final lower = clean.toLowerCase();

    // 1. Enter / Type: "enter 123 into phone", "type alex@test.com in email"
    final enterMatch = RegExp(
      r'^(?:enter|type|input|fill)\s+(?:"([^"]+)"|([^\s]+))\s+(?:in|into|to)\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(clean);
    if (enterMatch != null) {
      final val = enterMatch.group(1) ?? enterMatch.group(2)!;
      final target = _cleanTargetToken(enterMatch.group(3)!);
      return ['- Enter "$val" into $target'];
    }

    // 2. Tap / Click / Press: "click login button", "tap sign in", "press on continue"
    final tapMatch = RegExp(
      r'^(?:tap|click|press|hit)(?:\s+on|\s+button)?\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(clean);
    if (tapMatch != null) {
      final target = _cleanTargetToken(tapMatch.group(1)!);
      return ['- Tap "$target"'];
    }

    // 3. Expect / Verify / Check / See: "see welcome back", "verify dashboard is visible", "check cart badge"
    final expectMatch = RegExp(
      r'^(?:expect|verify|check|see|assert|ensure)(?:\s+that)?\s+(.+?)(?:\s+(?:is\s+visible|to\s+be\s+visible|visible|shown))?$',
      caseSensitive: false,
    ).firstMatch(clean);
    if (expectMatch != null) {
      final target = _cleanTargetToken(expectMatch.group(1)!);
      return ['- Expect "$target" to be visible'];
    }

    // 4. Scroll: "scroll down 300px", "scroll up"
    if (lower.contains('scroll')) {
      final numMatch = RegExp(r'\d+').firstMatch(lower);
      final px = numMatch != null ? int.parse(numMatch.group(0)!) : 250;
      final direction = lower.contains('up') ? 'up' : 'down';
      return ['- Scroll $direction ${px}px'];
    }

    // 5. Wait: "wait 2 seconds", "sleep 1s"
    if (lower.startsWith('wait') || lower.startsWith('sleep')) {
      final numMatch = RegExp(r'\d+').firstMatch(lower);
      final dur = numMatch != null ? int.parse(numMatch.group(0)!) : 1;
      final isSeconds = !lower.contains('ms') && !lower.contains('milli');
      return ['- Wait $dur${isSeconds ? "s" : "ms"}'];
    }

    // 6. Dismiss keyboard
    if (lower.contains('keyboard')) {
      return ['- Dismiss soft keyboard'];
    }

    // Fallback: smart tap
    return ['- Tap "$clean"'];
  }

  static String _cleanTargetToken(String raw) {
    var target = raw.trim();
    if ((target.startsWith('"') && target.endsWith('"')) ||
        (target.startsWith("'") && target.endsWith("'"))) {
      target = target.substring(1, target.length - 1);
    }
    return target.trim();
  }
}
