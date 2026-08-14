import 'dart:async';
import 'package:flutter/widgets.dart';
import '../models/test_case.dart';
import '../models/test_enums.dart';
import '../models/test_report.dart';
import '../models/test_scenario.dart';
import '../models/test_step.dart';
import '../models/test_suite.dart';
import '../utils/log_entry.dart';
import 'test_runner_state.dart';

/// Signature for executing a single test step in the context of the live widget tree.
typedef StepExecutorCallback = Future<void> Function(
  TestStep step,
  BuildContext? context,
  TestRunnerController controller,
);

/// Central reactive state controller managing test suite lifecycle, execution, stepping, and speed.
class TestRunnerController extends ChangeNotifier {
  TestRunnerState _state;

  /// The step executor engine callback (injected by the engine layer).
  StepExecutorCallback? stepExecutor;

  Completer<void>? _pauseCompleter;
  bool _stopRequested = false;
  DateTime? _suiteStartTime;

  TestRunnerController({
    TestSuite? initialSuite,
    double initialSpeed = 1.0,
    bool initialOverlayVisible = true,
  }) : _state = TestRunnerState(
          suite: initialSuite,
          speedMultiplier: initialSpeed,
          isOverlayVisible: initialOverlayVisible,
        );

  /// Current state snapshot.
  TestRunnerState get state => _state;

  /// Active test suite.
  TestSuite? get suite => _state.suite;

  /// Current execution state.
  RunnerExecutionState get executionState => _state.executionState;

  /// Speed multiplier.
  double get speedMultiplier => _state.speedMultiplier;

  /// Whether runner is currently executing.
  bool get isRunning => _state.isRunning;

  /// Whether runner is paused.
  bool get isPaused => _state.isPaused;

  /// Set or update the active test suite.
  void setSuite(TestSuite suite) {
    _state = _state.copyWith(
      suite: suite,
      executionState: RunnerExecutionState.idle,
      activeScenario: null,
      activeCase: null,
      activeStep: null,
      activeStepIndex: 0,
      totalStepCount: suite.totalStepCount,
      clearTargetRect: true,
      clearTargetPoint: true,
      clearActionType: true,
    );
    log('Loaded test suite: "${suite.name}" with ${suite.scenarios.length} scenarios (${suite.totalCaseCount} test cases)');
    notifyListeners();
  }

  /// Load and parse test suite from a natural English string.
  void loadFromNaturalLanguage(String text, {String? suiteName}) {
    final newSuite = TestSuite.fromNaturalLanguage(text, name: suiteName);
    setSuite(newSuite);
  }

  /// Set the execution speed multiplier (e.g. 0.25x, 0.5x, 1.0x, 2.0x, 4.0x).
  void setSpeedMultiplier(double multiplier) {
    if (multiplier <= 0) return;
    _state = _state.copyWith(speedMultiplier: multiplier);
    log('Speed multiplier set to ${multiplier}x');
    notifyListeners();
  }

  /// Toggle or set step-by-step debugger mode.
  void setStepByStepMode(bool enabled) {
    _state = _state.copyWith(isStepByStepMode: enabled);
    log('Step-by-step mode ${enabled ? "enabled" : "disabled"}');
    notifyListeners();
  }

  /// Toggle visual overlay (highlights, ripple effects).
  void setOverlayVisible(bool visible) {
    _state = _state.copyWith(isOverlayVisible: visible);
    notifyListeners();
  }

  /// Expand or collapse the dashboard drawer/sheet.
  void setDashboardExpanded(bool expanded) {
    _state = _state.copyWith(isDashboardExpanded: expanded);
    notifyListeners();
  }

  /// Set tag filter (e.g. `@smoke`, `@auth`).
  void setFilterTag(String? tag) {
    _state = _state.copyWith(
      filterTag: tag,
      clearFilterTag: tag == null,
    );
    log(tag != null ? 'Filtered test suite by tag: $tag' : 'Cleared tag filter');
    notifyListeners();
  }

  /// Toggle breakpoint on a step.
  void toggleBreakpoint(TestStep step) {
    step.isBreakpoint = !step.isBreakpoint;
    notifyListeners();
  }

  /// Record a log entry.
  void log(
    String message, {
    RunnerLogLevel level = RunnerLogLevel.info,
    String? error,
    StackTrace? stackTrace,
    String? scenarioName,
    String? caseName,
    String? stepId,
    Map<String, dynamic>? metadata,
  }) {
    final entry = RunnerLogEntry(
      level: level,
      message: message,
      scenarioName: scenarioName ?? _state.activeScenario?.name,
      caseName: caseName ?? _state.activeCase?.name,
      stepId: stepId ?? _state.activeStep?.id,
      error: error,
      stackTrace: stackTrace,
      metadata: metadata,
    );

    final updatedLogs = List<RunnerLogEntry>.from(_state.logs)..add(entry);
    _state = _state.copyWith(logs: updatedLogs);

    // If there's an active step, add to its internal logs
    _state.activeStep?.logs.add(entry);

    notifyListeners();
  }

  /// Clear all execution logs.
  void clearLogs() {
    _state = _state.copyWith(logs: []);
    notifyListeners();
  }

  /// Update active target bounding box for visual highlights and ripples.
  void updateTargetHighlight({
    Rect? rect,
    Offset? point,
    TestStepType? actionType,
  }) {
    _state = _state.copyWith(
      activeTargetRect: rect,
      clearTargetRect: rect == null,
      activeTargetPoint: point ?? rect?.center,
      clearTargetPoint: point == null && rect == null,
      activeActionType: actionType,
      clearActionType: actionType == null,
    );
    notifyListeners();
  }

  /// Clear active target highlight.
  void clearTargetHighlight() {
    _state = _state.copyWith(
      clearTargetRect: true,
      clearTargetPoint: true,
      clearActionType: true,
    );
    notifyListeners();
  }

  /// Calculate adjusted duration according to speed multiplier.
  Duration adjustDuration(Duration baseDuration) {
    final ms = (baseDuration.inMilliseconds / _state.speedMultiplier).round();
    return Duration(milliseconds: ms.clamp(10, 60000));
  }

  /// Execute an adjusted delay according to the speed multiplier.
  Future<void> stepDelay([Duration base = const Duration(milliseconds: 400)]) async {
    final duration = adjustDuration(base);
    await Future.delayed(duration);
  }

  /// Pause current execution.
  void pause() {
    if (_state.executionState == RunnerExecutionState.running) {
      _pauseCompleter = Completer<void>();
      _state = _state.copyWith(executionState: RunnerExecutionState.paused);
      log('Test execution paused', level: RunnerLogLevel.warning);
      notifyListeners();
    }
  }

  /// Resume paused execution.
  void resume() {
    if (_state.executionState == RunnerExecutionState.paused) {
      _state = _state.copyWith(executionState: RunnerExecutionState.running);
      _pauseCompleter?.complete();
      _pauseCompleter = null;
      log('Test execution resumed', level: RunnerLogLevel.info);
      notifyListeners();
    }
  }

  /// Execute the next single step while paused or in step-by-step mode.
  void stepNext() {
    if (_state.executionState == RunnerExecutionState.paused) {
      _pauseCompleter?.complete();
      _pauseCompleter = Completer<void>();
      notifyListeners();
    }
  }

  /// Stop current execution immediately.
  void stop() {
    _stopRequested = true;
    _pauseCompleter?.complete();
    _pauseCompleter = null;
    clearTargetHighlight();
    _state = _state.copyWith(executionState: RunnerExecutionState.stopped);
    log('Test execution stopped by user', level: RunnerLogLevel.warning);
    notifyListeners();
  }

  /// Reset all suite results and state.
  void reset() {
    _stopRequested = false;
    _pauseCompleter?.complete();
    _pauseCompleter = null;
    _suiteStartTime = null;
    clearTargetHighlight();
    _state.suite?.reset();
    _state = _state.copyWith(
      executionState: RunnerExecutionState.idle,
      activeScenario: null,
      activeCase: null,
      activeStep: null,
      activeStepIndex: 0,
      clearTargetRect: true,
      clearTargetPoint: true,
      clearActionType: true,
    );
    log('Test suite reset to initial state');
    notifyListeners();
  }

  /// Run all scenarios in the active suite.
  Future<TestReport?> runAll({BuildContext? context}) async {
    final suite = _state.suite;
    if (suite == null || suite.scenarios.isEmpty) {
      log('No test suite loaded to run', level: RunnerLogLevel.warning);
      return null;
    }

    _stopRequested = false;
    _suiteStartTime = DateTime.now();
    suite.reset();

    _state = _state.copyWith(
      executionState: RunnerExecutionState.running,
      totalStepCount: suite.totalStepCount,
      activeStepIndex: 0,
    );
    notifyListeners();

    log('==================================================');
    log('▶ Starting Test Suite: "${suite.name}"', level: RunnerLogLevel.info);
    log('==================================================');

    final filterTag = _state.filterTag;
    final scenariosToRun = filterTag == null
        ? suite.scenarios
        : suite.scenarios
            .where((s) =>
                s.tags.contains(filterTag) ||
                s.cases.any((c) => c.tags.contains(filterTag)))
            .toList();

    for (final scenario in scenariosToRun) {
      if (_stopRequested) break;
      await _executeScenario(scenario, context: context);
    }

    clearTargetHighlight();

    final endTime = DateTime.now();
    final report = TestReport.fromSuite(
      suite: suite,
      startTime: _suiteStartTime ?? endTime,
      endTime: endTime,
      logs: _state.logs,
    );

    _state = _state.copyWith(
      executionState:
          _stopRequested ? RunnerExecutionState.stopped : RunnerExecutionState.completed,
      lastReport: report,
      activeScenario: null,
      activeCase: null,
      activeStep: null,
    );

    log('==================================================');
    if (report.isSuccess) {
      log(
        '✔ Test Suite COMPLETED: All ${report.passedCases}/${report.totalCases} cases passed in ${report.duration.inMilliseconds}ms',
        level: RunnerLogLevel.success,
      );
    } else {
      log(
        '✖ Test Suite FAILED: ${report.failedCases}/${report.totalCases} cases failed',
        level: RunnerLogLevel.error,
      );
    }
    log('==================================================');

    notifyListeners();
    return report;
  }

  /// Run a single scenario.
  Future<void> runScenario(
    TestScenario scenario, {
    BuildContext? context,
  }) async {
    _stopRequested = false;
    _state = _state.copyWith(
      executionState: RunnerExecutionState.running,
      activeScenario: scenario,
    );
    notifyListeners();

    await _executeScenario(scenario, context: context);

    clearTargetHighlight();
    _state = _state.copyWith(
      executionState:
          _stopRequested ? RunnerExecutionState.stopped : RunnerExecutionState.completed,
    );
    notifyListeners();
  }

  /// Run a single test case.
  Future<void> runCase(
    TestCase testCase, {
    BuildContext? context,
    TestScenario? parentScenario,
  }) async {
    _stopRequested = false;
    _state = _state.copyWith(
      executionState: RunnerExecutionState.running,
      activeScenario: parentScenario,
      activeCase: testCase,
    );
    notifyListeners();

    await _executeCase(testCase, context: context, parentScenario: parentScenario);

    clearTargetHighlight();
    _state = _state.copyWith(
      executionState:
          _stopRequested ? RunnerExecutionState.stopped : RunnerExecutionState.completed,
    );
    notifyListeners();
  }

  /// Run an individual test step.
  Future<void> runStep(
    TestStep step, {
    BuildContext? context,
  }) async {
    _stopRequested = false;
    _state = _state.copyWith(
      executionState: RunnerExecutionState.running,
      activeStep: step,
    );
    notifyListeners();

    await _executeStep(step, context: context);

    clearTargetHighlight();
    _state = _state.copyWith(
      executionState:
          _stopRequested ? RunnerExecutionState.stopped : RunnerExecutionState.completed,
    );
    notifyListeners();
  }

  Future<void> _executeScenario(
    TestScenario scenario, {
    BuildContext? context,
  }) async {
    scenario.status = TestStatus.running;
    scenario.startTime = DateTime.now();
    _state = _state.copyWith(activeScenario: scenario);
    log('▶ Scenario: "${scenario.name}"', level: RunnerLogLevel.info);
    notifyListeners();

    final filterTag = _state.filterTag;
    final casesToRun = filterTag == null
        ? scenario.cases
        : scenario.cases.where((c) => c.tags.contains(filterTag)).toList();

    for (final testCase in casesToRun) {
      if (_stopRequested) {
        testCase.status = TestStatus.skipped;
        continue;
      }
      await _executeCase(testCase, context: context, parentScenario: scenario);
    }

    scenario.endTime = DateTime.now();
    scenario.status = scenario.cases.any((c) => c.status == TestStatus.failed)
        ? TestStatus.failed
        : TestStatus.passed;

    if (scenario.status == TestStatus.passed) {
      log('✔ Scenario "${scenario.name}" PASSED (${scenario.duration.inMilliseconds}ms)',
          level: RunnerLogLevel.success);
    } else {
      log('✖ Scenario "${scenario.name}" FAILED', level: RunnerLogLevel.error);
    }
    notifyListeners();
  }

  Future<void> _executeCase(
    TestCase testCase, {
    BuildContext? context,
    TestScenario? parentScenario,
  }) async {
    testCase.status = TestStatus.running;
    testCase.startTime = DateTime.now();
    _state = _state.copyWith(activeCase: testCase);
    log('  ├─ Case: "${testCase.name}"', level: RunnerLogLevel.info);
    notifyListeners();

    // Run setup hook if defined
    if (testCase.setup != null && context != null) {
      try {
        await testCase.setup!(context);
      } catch (e, st) {
        log('Setup hook error in "${testCase.name}": $e',
            level: RunnerLogLevel.error, error: e.toString(), stackTrace: st);
      }
    }

    for (final step in testCase.steps) {
      if (_stopRequested) {
        step.status = TestStatus.skipped;
        continue;
      }

      final currentContext = (context != null && context.mounted) ? context : null;
      // ignore: use_build_context_synchronously
      await _executeStep(step, context: currentContext);

      if (step.status == TestStatus.failed) {
        testCase.status = TestStatus.failed;
        testCase.errorMessage = step.errorMessage;
        break;
      }
    }

    // Run teardown hook if defined
    if (testCase.teardown != null && context != null && context.mounted) {
      try {
        await testCase.teardown!(context);
      } catch (e, st) {
        log('Teardown hook error in "${testCase.name}": $e',
            level: RunnerLogLevel.error, error: e.toString(), stackTrace: st);
      }
    }

    testCase.endTime = DateTime.now();
    if (testCase.status != TestStatus.failed) {
      testCase.status = TestStatus.passed;
      log('  └─ ✔ Case "${testCase.name}" PASSED (${testCase.duration.inMilliseconds}ms)',
          level: RunnerLogLevel.success);
    } else {
      log('  └─ ✖ Case "${testCase.name}" FAILED: ${testCase.errorMessage}',
          level: RunnerLogLevel.error);
    }
    notifyListeners();
  }

  Future<void> _executeStep(
    TestStep step, {
    BuildContext? context,
  }) async {
    step.status = TestStatus.running;
    step.startTime = DateTime.now();
    _state = _state.copyWith(
      activeStep: step,
      activeStepIndex: _state.activeStepIndex + 1,
    );
    notifyListeners();

    // Check breakpoint or step-by-step mode
    if (step.isBreakpoint || _state.isStepByStepMode) {
      pause();
      log('Breakpoint hit at step: "${step.description}"',
          level: RunnerLogLevel.warning);
      await _pauseCompleter?.future;
    }

    // Check if stopped during pause
    if (_stopRequested) {
      step.status = TestStatus.skipped;
      return;
    }

    try {
      final validContext = (context != null && context.mounted) ? context : null;
      if (step.type == TestStepType.wait && step.duration != null) {
        await stepDelay(step.duration!);
      } else if (step.type == TestStepType.custom && step.customAction != null) {
        if (validContext != null && validContext.mounted) {
          await step.customAction!(validContext);
        }
      } else if (stepExecutor != null) {
        // ignore: use_build_context_synchronously
        await stepExecutor!(step, validContext, this);
      } else {
        // Default simulated fallback if executor not yet attached
        await stepDelay(const Duration(milliseconds: 300));
      }

      step.status = TestStatus.passed;
      log('     ✔ ${step.description}', level: RunnerLogLevel.info);
    } catch (e, st) {
      step.status = TestStatus.failed;
      step.errorMessage = e.toString();
      step.stackTrace = st;
      log(
        '     ✖ Failed: ${step.description}\n       Error: $e',
        level: RunnerLogLevel.error,
        error: e.toString(),
        stackTrace: st,
      );
    } finally {
      step.endTime = DateTime.now();
      await stepDelay(const Duration(milliseconds: 150));
      notifyListeners();
    }
  }
}
