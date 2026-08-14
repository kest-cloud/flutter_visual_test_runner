import 'package:flutter/widgets.dart';
import '../controller/test_runner_controller.dart';
import '../models/test_enums.dart';
import '../models/test_step.dart';
import 'assertion_engine.dart';
import 'gesture_simulator.dart';
import 'widget_finder_engine.dart';

/// Orchestrates live step execution by combining finder lookup, gesture simulation, assertions, and highlight notifications.
class StepExecutionEngine {
  /// Execute an individual [TestStep] on the live widget tree.
  static Future<void> executeStep(
    TestStep step,
    BuildContext? context,
    TestRunnerController controller,
  ) async {
    final targetFinder = step.target;

    switch (step.type) {
      case TestStepType.tap:
        if (targetFinder == null) throw ArgumentError('Tap step requires a target');
        final found = await _resolveTargetWithRetry(targetFinder, controller);
        controller.updateTargetHighlight(
          rect: found.globalRect,
          point: found.centerPoint,
          actionType: TestStepType.tap,
        );
        await controller.stepDelay(const Duration(milliseconds: 200));
        await GestureSimulator.tap(found.centerPoint, element: found.element);
        break;

      case TestStepType.doubleTap:
        if (targetFinder == null) throw ArgumentError('DoubleTap step requires a target');
        final found = await _resolveTargetWithRetry(targetFinder, controller);
        controller.updateTargetHighlight(
          rect: found.globalRect,
          point: found.centerPoint,
          actionType: TestStepType.doubleTap,
        );
        await controller.stepDelay(const Duration(milliseconds: 200));
        await GestureSimulator.doubleTap(found.centerPoint, element: found.element);
        break;

      case TestStepType.longPress:
        if (targetFinder == null) throw ArgumentError('LongPress step requires a target');
        final found = await _resolveTargetWithRetry(targetFinder, controller);
        controller.updateTargetHighlight(
          rect: found.globalRect,
          point: found.centerPoint,
          actionType: TestStepType.longPress,
        );
        await controller.stepDelay(const Duration(milliseconds: 200));
        await GestureSimulator.longPress(
          found.centerPoint,
          duration: step.duration ?? const Duration(milliseconds: 700),
        );
        break;

      case TestStepType.enterText:
        if (targetFinder == null) throw ArgumentError('EnterText step requires a target');
        final found = await _resolveTargetWithRetry(targetFinder, controller);
        controller.updateTargetHighlight(
          rect: found.globalRect,
          point: found.centerPoint,
          actionType: TestStepType.enterText,
        );
        await controller.stepDelay(const Duration(milliseconds: 150));
        await GestureSimulator.enterText(
          found.element,
          step.text ?? '',
          clearFirst: step.clearFirst,
        );
        break;

      case TestStepType.clearText:
        if (targetFinder == null) throw ArgumentError('ClearText step requires a target');
        final found = await _resolveTargetWithRetry(targetFinder, controller);
        controller.updateTargetHighlight(
          rect: found.globalRect,
          point: found.centerPoint,
          actionType: TestStepType.clearText,
        );
        await controller.stepDelay(const Duration(milliseconds: 150));
        await GestureSimulator.clearText(found.element);
        break;

      case TestStepType.scroll:
        final offset = step.offset ?? const Offset(0, 250);
        FoundWidgetResult? found;
        if (targetFinder != null) {
          found = WidgetFinderEngine.findFirst(targetFinder);
        }
        final center = found?.centerPoint ?? _getScreenCenter();
        controller.updateTargetHighlight(
          rect: found?.globalRect,
          point: center,
          actionType: TestStepType.scroll,
        );
        await GestureSimulator.scroll(center, offset, duration: step.duration ?? const Duration(milliseconds: 300));
        break;

      case TestStepType.drag:
        if (targetFinder == null) throw ArgumentError('Drag step requires a target');
        final found = await _resolveTargetWithRetry(targetFinder, controller);
        final endPoint = found.centerPoint + (step.offset ?? const Offset(0, 200));
        controller.updateTargetHighlight(
          rect: found.globalRect,
          point: found.centerPoint,
          actionType: TestStepType.drag,
        );
        await GestureSimulator.drag(
          found.centerPoint,
          endPoint,
          duration: step.duration ?? const Duration(milliseconds: 350),
        );
        break;

      case TestStepType.scrollTo:
        if (targetFinder == null) throw ArgumentError('ScrollTo step requires a target');
        final found = await _resolveTargetWithRetry(targetFinder, controller, autoScroll: true);
        controller.updateTargetHighlight(
          rect: found.globalRect,
          point: found.centerPoint,
          actionType: TestStepType.scrollTo,
        );
        break;

      case TestStepType.expectVisible:
        if (targetFinder == null) throw ArgumentError('ExpectVisible step requires a target');
        final found = await AssertionEngine.expectVisible(
          targetFinder,
          timeout: step.timeout ?? controller.suite?.defaultTimeout,
          autoScroll: controller.suite?.autoScrollToTarget ?? true,
        );
        controller.updateTargetHighlight(
          rect: found.globalRect,
          point: found.centerPoint,
          actionType: TestStepType.expectVisible,
        );
        break;

      case TestStepType.expectNotVisible:
        if (targetFinder == null) throw ArgumentError('ExpectNotVisible step requires a target');
        controller.clearTargetHighlight();
        await AssertionEngine.expectNotVisible(
          targetFinder,
          timeout: step.timeout ?? controller.suite?.defaultTimeout,
        );
        break;

      case TestStepType.expectText:
        if (targetFinder == null) throw ArgumentError('ExpectText step requires a target');
        final found = await AssertionEngine.expectText(
          targetFinder,
          step.text ?? '',
          timeout: step.timeout ?? controller.suite?.defaultTimeout,
        );
        controller.updateTargetHighlight(
          rect: found.globalRect,
          point: found.centerPoint,
          actionType: TestStepType.expectText,
        );
        break;

      case TestStepType.dismissKeyboard:
        GestureSimulator.dismissKeyboard();
        await controller.stepDelay(const Duration(milliseconds: 200));
        break;

      case TestStepType.wait:
        if (step.duration != null) {
          await controller.stepDelay(step.duration!);
        }
        break;

      case TestStepType.custom:
        if (step.customAction != null && context != null) {
          await step.customAction!(context);
        }
        break;
    }
  }

  /// Resolves target with adaptive waiting and auto-scrolling if needed.
  static Future<FoundWidgetResult> _resolveTargetWithRetry(
    dynamic targetFinder,
    TestRunnerController controller, {
    bool autoScroll = true,
  }) async {
    FoundWidgetResult? found;

    await AssertionEngine.waitUntil(
      () async {
        found = WidgetFinderEngine.findFirst(targetFinder);
        if (found != null) {
          if (!found!.isVisibleInViewport && autoScroll) {
            await WidgetFinderEngine.scrollIntoView(found!.element);
            found = WidgetFinderEngine.findFirst(targetFinder);
          }
          return found != null;
        }
        return false;
      },
      timeout: controller.suite?.defaultTimeout ?? const Duration(seconds: 4),
      description: 'Find target widget: ${targetFinder.description}',
    );

    if (found == null) {
      throw AssertionError('Widget not found: ${targetFinder.description}');
    }

    return found!;
  }

  static Offset _getScreenCenter() {
    final view = WidgetsBinding.instance.platformDispatcher.views.firstOrNull;
    if (view == null) return const Offset(200, 300);
    final size = view.physicalSize / view.devicePixelRatio;
    return size.center(Offset.zero);
  }
}
