import 'dart:async';
import '../models/target_finder.dart';
import 'widget_finder_engine.dart';

/// Evaluates test assertions against the live Element tree with adaptive polling and async frame pumping.
class AssertionEngine {
  /// Default timeout for assertion evaluations.
  static Duration defaultTimeout = const Duration(seconds: 4);

  /// Adaptively poll [condition] until it returns true, or throw a timeout exception.
  static Future<void> waitUntil(
    FutureOr<bool> Function() condition, {
    Duration? timeout,
    Duration interval = const Duration(milliseconds: 60),
    String? description,
  }) async {
    final maxTimeout = timeout ?? defaultTimeout;
    final deadline = DateTime.now().add(maxTimeout);

    while (DateTime.now().isBefore(deadline)) {
      try {
        final result = await condition();
        if (result) return;
      } catch (_) {
        // Condition might throw during transitional frame; continue polling
      }
      await Future.delayed(interval);
    }

    // Final attempt
    try {
      final finalCheck = await condition();
      if (finalCheck) return;
    } catch (_) {}

    throw TimeoutException(
      'Assertion timed out after ${maxTimeout.inMilliseconds}ms${description != null ? ": $description" : ""}',
      maxTimeout,
    );
  }

  /// Assert that a widget matching [finder] is present and visible in the Element tree.
  static Future<FoundWidgetResult> expectVisible(
    TargetFinder finder, {
    Duration? timeout,
    bool autoScroll = true,
  }) async {
    FoundWidgetResult? matched;

    await waitUntil(
      () async {
        matched = WidgetFinderEngine.findFirst(finder);
        if (matched != null) {
          if (!matched!.isVisibleInViewport && autoScroll) {
            await WidgetFinderEngine.scrollIntoView(matched!.element);
            matched = WidgetFinderEngine.findFirst(finder);
          }
          return matched != null && matched!.isVisibleInViewport;
        }
        return false;
      },
      timeout: timeout,
      description: 'Expected ${finder.description} to be visible on screen',
    );

    if (matched == null) {
      throw AssertionError(
        'Target widget not found in Element tree: ${finder.description}',
      );
    }

    return matched!;
  }

  /// Assert that a widget matching [finder] is NOT present or hidden.
  static Future<void> expectNotVisible(
    TargetFinder finder, {
    Duration? timeout,
  }) async {
    await waitUntil(
      () {
        final matched = WidgetFinderEngine.findFirst(finder);
        return matched == null || !matched.isVisibleInViewport;
      },
      timeout: timeout,
      description: 'Expected ${finder.description} to NOT be visible',
    );
  }

  /// Assert that a widget matching [finder] has text matching [expectedText].
  static Future<FoundWidgetResult> expectText(
    TargetFinder finder,
    String expectedText, {
    Duration? timeout,
    bool exact = false,
  }) async {
    FoundWidgetResult? matched;
    String? actualText;

    await waitUntil(
      () {
        matched = WidgetFinderEngine.findFirst(finder);
        if (matched != null) {
          actualText = WidgetFinderEngine.extractTextFromElement(matched!.element);
          if (actualText != null) {
            return exact
                ? actualText!.trim() == expectedText.trim()
                : actualText!.toLowerCase().contains(expectedText.toLowerCase());
          }
        }
        return false;
      },
      timeout: timeout,
      description:
          'Expected ${finder.description} to contain text "$expectedText" (actual: "${actualText ?? 'null'}")',
    );

    return matched!;
  }

  /// Assert that exactly [expectedCount] matching widgets are present.
  static Future<List<FoundWidgetResult>> expectWidgetCount(
    TargetFinder finder,
    int expectedCount, {
    Duration? timeout,
  }) async {
    List<FoundWidgetResult> list = [];

    await waitUntil(
      () {
        list = WidgetFinderEngine.findAll(finder);
        return list.length == expectedCount;
      },
      timeout: timeout,
      description:
          'Expected $expectedCount instances of ${finder.description}, found ${list.length}',
    );

    return list;
  }
}
