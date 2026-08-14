import 'dart:ui';
import '../models/target_finder.dart';
import '../models/test_case.dart';
import '../models/test_scenario.dart';
import '../models/test_step.dart';
import 'test_case_converter.dart';

/// Parses natural English text, markdown, or BDD-style lines into structured [TestScenario], [TestCase], and [TestStep] objects.
class NaturalLanguageTestParser {
  /// Parse a full natural language text document into a list of [TestScenario]s.
  static List<TestScenario> parse(String text) {
    final canonicalText = TestCaseConverter.convert(text);
    final lines = canonicalText.split('\n');
    final scenarios = <TestScenario>[];

    TestScenario? currentScenario;
    TestCase? currentCase;

    for (int i = 0; i < lines.length; i++) {
      var rawLine = lines[i].trim();
      if (rawLine.isEmpty || rawLine.startsWith('//')) continue;

      // Check for Scenario header
      if (_isScenarioHeader(rawLine)) {
        final scenarioName = _extractScenarioName(rawLine);
        final tags = _extractTags(rawLine);
        currentScenario = TestScenario(name: scenarioName, tags: tags);
        scenarios.add(currentScenario);
        currentCase = null;
        continue;
      }

      // Check for Test Case header
      if (_isCaseHeader(rawLine)) {
        final caseName = _extractCaseName(rawLine);
        final tags = _extractTags(rawLine);
        currentCase = TestCase(name: caseName, tags: tags);

        // If no scenario active, create a default one
        if (currentScenario == null) {
          currentScenario = TestScenario(name: 'Default Scenario');
          scenarios.add(currentScenario);
        }
        currentScenario.addCase(currentCase);
        continue;
      }

      // Parse step line (bullet or numbered or plain line)
      final step = parseStepLine(rawLine);
      if (step != null) {
        if (currentScenario == null) {
          currentScenario = TestScenario(name: 'Default Scenario');
          scenarios.add(currentScenario);
        }
        if (currentCase == null) {
          currentCase = TestCase(name: 'Default Test Case');
          currentScenario.addCase(currentCase);
        }
        currentCase.addStep(step);
      }
    }

    return scenarios;
  }

  static bool _isScenarioHeader(String line) {
    final lower = line.toLowerCase();
    return line.startsWith('# ') ||
        lower.startsWith('scenario:') ||
        lower.startsWith('feature:') ||
        line.startsWith('===');
  }

  static String _extractScenarioName(String line) {
    var clean = line;
    if (clean.startsWith('# ')) clean = clean.substring(2);
    clean = clean.replaceFirst(RegExp(r'^(scenario|feature):\s*', caseSensitive: false), '');
    clean = clean.replaceAll(RegExp(r'@[\w-]+'), '').trim();
    return clean.isEmpty ? 'Untitled Scenario' : clean;
  }

  static bool _isCaseHeader(String line) {
    final lower = line.toLowerCase();
    return line.startsWith('## ') ||
        lower.startsWith('test:') ||
        lower.startsWith('case:') ||
        lower.startsWith('test for ') ||
        lower.startsWith('should ');
  }

  static String _extractCaseName(String line) {
    var clean = line;
    if (clean.startsWith('## ')) clean = clean.substring(3);
    clean = clean.replaceFirst(RegExp(r'^(test|case):\s*', caseSensitive: false), '');
    clean = clean.replaceAll(RegExp(r'@[\w-]+'), '').trim();
    return clean.isEmpty ? 'Untitled Case' : clean;
  }

  static List<String> _extractTags(String line) {
    final matches = RegExp(r'@[\w-]+').allMatches(line);
    return matches.map((m) => m.group(0)!).toList();
  }

  /// Parse a single natural English line into a [TestStep].
  static TestStep? parseStepLine(String line) {
    var clean = line.trim();
    // Strip leading bullets/dashes/numbers
    clean = clean.replaceFirst(RegExp(r'^[-*+]\s+'), '');
    clean = clean.replaceFirst(RegExp(r'^\d+\.\s+'), '');
    clean = clean.trim();

    if (clean.isEmpty) return null;

    final lower = clean.toLowerCase();

    // 1. Enter text / Type / Input:
    // Format: Enter "my text" into phone number
    // Format: Type "alex@test.com" in email field
    final enterMatch = RegExp(
      r'^(enter|type|input|fill)\s+"([^"]+)"\s+(?:in|into|to)\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(clean);
    if (enterMatch != null) {
      final textToEnter = enterMatch.group(2)!;
      final targetStr = _cleanTargetString(enterMatch.group(3)!);
      return TestStep.enterText(
        target: _resolveTargetFinder(targetStr),
        text: textToEnter,
        description: 'Enter "$textToEnter" into $targetStr',
      );
    }

    // 2. Clear text:
    // Format: Clear "email" or Clear text in "phone"
    final clearMatch = RegExp(
      r'^clear\s+(?:text\s+(?:in|from)\s+)?(.+)$',
      caseSensitive: false,
    ).firstMatch(clean);
    if (clearMatch != null) {
      final targetStr = _cleanTargetString(clearMatch.group(1)!);
      return TestStep.clearText(
        target: _resolveTargetFinder(targetStr),
        description: 'Clear text in $targetStr',
      );
    }

    // 3. Double Tap:
    // Format: Double tap "login" or Double click "button"
    final doubleTapMatch = RegExp(
      r'^double\s+(?:tap|click)(?:\s+on)?\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(clean);
    if (doubleTapMatch != null) {
      final targetStr = _cleanTargetString(doubleTapMatch.group(1)!);
      return TestStep.doubleTap(
        target: _resolveTargetFinder(targetStr),
        description: 'Double tap $targetStr',
      );
    }

    // 4. Long press:
    // Format: Long press "button" or Hold "button"
    final longPressMatch = RegExp(
      r'^(?:long\s+press|hold)(?:\s+on)?\s+(.+?)(?:\s+for\s+(\d+)\s*(?:s|seconds|ms|millis))?$',
      caseSensitive: false,
    ).firstMatch(clean);
    if (longPressMatch != null) {
      final targetStr = _cleanTargetString(longPressMatch.group(1)!);
      final durationNum = longPressMatch.group(2);
      Duration dur = const Duration(milliseconds: 700);
      if (durationNum != null) {
        final parsed = int.tryParse(durationNum) ?? 1;
        dur = lower.contains('ms') || lower.contains('milli')
            ? Duration(milliseconds: parsed)
            : Duration(seconds: parsed);
      }
      return TestStep.longPress(
        target: _resolveTargetFinder(targetStr),
        duration: dur,
        description: 'Long press on $targetStr',
      );
    }

    // 5. Tap / Click / Press:
    // Format: Tap "Sign In", Click on "Submit", Press button "Continue"
    final tapMatch = RegExp(
      r'^(?:tap|click|press)(?:\s+on|\s+button)?\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(clean);
    if (tapMatch != null) {
      final targetStr = _cleanTargetString(tapMatch.group(1)!);
      return TestStep.tap(
        target: _resolveTargetFinder(targetStr),
        description: 'Tap on $targetStr',
      );
    }

    // 6. Expect NOT visible:
    // Format: Expect "Error" not visible, Verify "Loading" is not visible, Expect "Dialog" hidden
    final notVisibleMatch = RegExp(
      r'^(?:expect|verify|check|assert)\s+(.+?)\s+(?:is\s+)?(?:not\s+visible|hidden|gone|to\s+disappear)$',
      caseSensitive: false,
    ).firstMatch(clean);
    if (notVisibleMatch != null) {
      final targetStr = _cleanTargetString(notVisibleMatch.group(1)!);
      return TestStep.expectNotVisible(
        target: _resolveTargetFinder(targetStr),
        description: 'Expect $targetStr is not visible',
      );
    }

    // 7. Expect Visible:
    // Format: Expect "Welcome back" to be visible, Verify "Dashboard" is visible, Expect "Welcome"
    final visibleMatch = RegExp(
      r'^(?:expect|verify|check|assert)\s+(.+?)(?:\s+(?:is\s+visible|to\s+be\s+visible|visible|displayed|shown))?$',
      caseSensitive: false,
    ).firstMatch(clean);
    if (visibleMatch != null) {
      final targetStr = _cleanTargetString(visibleMatch.group(1)!);
      return TestStep.expectVisible(
        target: _resolveTargetFinder(targetStr),
        description: 'Expect $targetStr to be visible',
      );
    }

    // 8. Auto-scroll / Scroll to:
    // Format: Scroll to "Item #45", Scroll down to "Sign Up"
    final scrollToMatch = RegExp(
      r'^scroll\s+(?:down\s+to|up\s+to|to)\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(clean);
    if (scrollToMatch != null) {
      final targetStr = _cleanTargetString(scrollToMatch.group(1)!);
      return TestStep.scrollTo(
        target: _resolveTargetFinder(targetStr),
        description: 'Scroll to $targetStr',
      );
    }

    // 9. Scroll delta:
    // Format: Scroll "list" by (0, 300) or Scroll down 300px
    final scrollDeltaMatch = RegExp(
      r'^scroll\s+(?:down|up)?\s*(?:by\s+)?(\d+)(?:px)?$',
      caseSensitive: false,
    ).firstMatch(clean);
    if (scrollDeltaMatch != null) {
      final dy = double.tryParse(scrollDeltaMatch.group(1)!) ?? 200.0;
      final direction = lower.contains('up') ? -dy : dy;
      return TestStep.scroll(
        target: TargetFinder.byType(dynamic, description: 'Scrollable container'),
        offset: Offset(0, direction),
        description: 'Scroll by (0, $direction)',
      );
    }

    // 10. Dismiss keyboard:
    // Format: Dismiss keyboard, Hide keyboard, Close keyboard
    if (lower.contains('keyboard') &&
        (lower.contains('dismiss') ||
            lower.contains('hide') ||
            lower.contains('close'))) {
      return TestStep.dismissKeyboard(description: 'Dismiss soft keyboard');
    }

    // 11. Wait:
    // Format: Wait 2 seconds, Wait 500ms, Sleep 1s
    final waitMatch = RegExp(
      r'^(?:wait|sleep)\s+(\d+)\s*(s|seconds|ms|millis)?$',
      caseSensitive: false,
    ).firstMatch(clean);
    if (waitMatch != null) {
      final numVal = int.tryParse(waitMatch.group(1)!) ?? 1000;
      final unit = waitMatch.group(2)?.toLowerCase() ?? 'ms';
      final isSeconds = unit.startsWith('s');
      final duration =
          isSeconds ? Duration(seconds: numVal) : Duration(milliseconds: numVal);
      return TestStep.wait(duration, description: 'Wait ${duration.inMilliseconds}ms');
    }

    // Fallback: smart tap or expectation
    return TestStep.tap(
      target: TargetFinder.smart(clean),
      description: 'Interact with "$clean"',
    );
  }

  static String _cleanTargetString(String target) {
    var t = target.trim();
    // Remove enclosing quotes if present
    if ((t.startsWith('"') && t.endsWith('"')) ||
        (t.startsWith("'") && t.endsWith("'"))) {
      t = t.substring(1, t.length - 1);
    }
    return t.trim();
  }

  /// Intelligently resolves a target string into the most appropriate [TargetFinder].
  static TargetFinder _resolveTargetFinder(String target) {
    // If explicitly prefixed with key:, text:, type:, tooltip:, etc.
    if (target.startsWith('key:')) {
      return TargetFinder.byKey(target.substring(4).trim());
    }
    if (target.startsWith('text:')) {
      return TargetFinder.byText(target.substring(5).trim());
    }
    if (target.startsWith('type:')) {
      return TargetFinder.byTypeName(target.substring(5).trim());
    }
    if (target.startsWith('tooltip:')) {
      return TargetFinder.byTooltip(target.substring(8).trim());
    }
    if (target.startsWith('hint:')) {
      return TargetFinder.byHint(target.substring(5).trim());
    }
    if (target.startsWith('semantics:')) {
      return TargetFinder.bySemantics(target.substring(10).trim());
    }

    // Default to SmartTargetFinder
    return TargetFinder.smart(target);
  }
}
