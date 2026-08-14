import 'package:flutter/widgets.dart';
import '../models/test_case.dart';
import '../models/test_enums.dart';
import '../models/test_report.dart';
import '../models/test_scenario.dart';
import '../models/test_step.dart';
import '../models/test_suite.dart';
import '../utils/log_entry.dart';

/// Top-level runner execution lifecycle state.
enum RunnerExecutionState {
  idle,
  running,
  paused,
  stopped,
  completed,
}

/// Immutable snapshot representing the visual test runner's state at any point in time.
@immutable
class TestRunnerState {
  final RunnerExecutionState executionState;
  final TestSuite? suite;
  final TestScenario? activeScenario;
  final TestCase? activeCase;
  final TestStep? activeStep;
  final int activeStepIndex;
  final int totalStepCount;
  final Rect? activeTargetRect;
  final Offset? activeTargetPoint;
  final TestStepType? activeActionType;
  final double speedMultiplier;
  final bool isStepByStepMode;
  final bool isOverlayVisible;
  final bool isDashboardExpanded;
  final String? filterTag;
  final TestReport? lastReport;
  final List<RunnerLogEntry> logs;

  const TestRunnerState({
    this.executionState = RunnerExecutionState.idle,
    this.suite,
    this.activeScenario,
    this.activeCase,
    this.activeStep,
    this.activeStepIndex = 0,
    this.totalStepCount = 0,
    this.activeTargetRect,
    this.activeTargetPoint,
    this.activeActionType,
    this.speedMultiplier = 1.0,
    this.isStepByStepMode = false,
    this.isOverlayVisible = true,
    this.isDashboardExpanded = false,
    this.filterTag,
    this.lastReport,
    this.logs = const [],
  });

  /// True if the runner is currently executing steps.
  bool get isRunning => executionState == RunnerExecutionState.running;

  /// True if the runner is paused (waiting for stepNext or resume).
  bool get isPaused => executionState == RunnerExecutionState.paused;

  /// True if execution is idle.
  bool get isIdle => executionState == RunnerExecutionState.idle;

  /// Copy this state with updated properties.
  TestRunnerState copyWith({
    RunnerExecutionState? executionState,
    TestSuite? suite,
    TestScenario? activeScenario,
    TestCase? activeCase,
    TestStep? activeStep,
    int? activeStepIndex,
    int? totalStepCount,
    Rect? activeTargetRect,
    bool clearTargetRect = false,
    Offset? activeTargetPoint,
    bool clearTargetPoint = false,
    TestStepType? activeActionType,
    bool clearActionType = false,
    double? speedMultiplier,
    bool? isStepByStepMode,
    bool? isOverlayVisible,
    bool? isDashboardExpanded,
    String? filterTag,
    bool clearFilterTag = false,
    TestReport? lastReport,
    List<RunnerLogEntry>? logs,
  }) {
    return TestRunnerState(
      executionState: executionState ?? this.executionState,
      suite: suite ?? this.suite,
      activeScenario: activeScenario ?? this.activeScenario,
      activeCase: activeCase ?? this.activeCase,
      activeStep: activeStep ?? this.activeStep,
      activeStepIndex: activeStepIndex ?? this.activeStepIndex,
      totalStepCount: totalStepCount ?? this.totalStepCount,
      activeTargetRect:
          clearTargetRect ? null : (activeTargetRect ?? this.activeTargetRect),
      activeTargetPoint:
          clearTargetPoint ? null : (activeTargetPoint ?? this.activeTargetPoint),
      activeActionType:
          clearActionType ? null : (activeActionType ?? this.activeActionType),
      speedMultiplier: speedMultiplier ?? this.speedMultiplier,
      isStepByStepMode: isStepByStepMode ?? this.isStepByStepMode,
      isOverlayVisible: isOverlayVisible ?? this.isOverlayVisible,
      isDashboardExpanded: isDashboardExpanded ?? this.isDashboardExpanded,
      filterTag: clearFilterTag ? null : (filterTag ?? this.filterTag),
      lastReport: lastReport ?? this.lastReport,
      logs: logs ?? this.logs,
    );
  }
}
