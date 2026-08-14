import 'dart:ui';
import 'package:flutter/material.dart';
import '../controller/test_runner_controller.dart';
import '../controller/test_runner_state.dart';
import '../models/test_enums.dart';

/// Floating glassmorphic HUD pill at top of screen displaying active step execution state.
class StepStatusBanner extends StatelessWidget {
  final TestRunnerController controller;

  const StepStatusBanner({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;
        final step = state.activeStep;
        final isRunning = state.isRunning || state.isPaused;

        if (!isRunning || step == null) {
          return const SizedBox.shrink();
        }

        final actionIcon = _getActionIcon(step.type);
        final statusColor = _getStatusColor(state);

        return Positioned(
          top: MediaQuery.of(context).padding.top + 12.0,
          left: 16.0,
          right: 16.0,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutBack,
            builder: (context, val, child) {
              return Transform.scale(
                scale: 0.85 + 0.15 * val,
                alignment: Alignment.topCenter,
                child: Opacity(
                  opacity: val.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: const Color(0xE6101423), // Dark Obsidian Glass
                      borderRadius: BorderRadius.circular(30.0),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.3),
                          blurRadius: 18.0,
                          spreadRadius: 2.0,
                        ),
                        const BoxShadow(
                          color: Colors.black45,
                          blurRadius: 10.0,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. Status Icon / Spinner
                        _buildStatusIndicator(state, statusColor),
                        const SizedBox(width: 8.0),

                        // 2. Action Type Icon
                        Container(
                          padding: const EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(actionIcon, size: 14.0, color: statusColor),
                        ),
                        const SizedBox(width: 8.0),

                        // 3. Step Counter & Description
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (state.activeScenario != null || state.activeCase != null)
                                Text(
                                  '${state.activeScenario?.name ?? ''}${state.activeCase != null ? ' ▸ ${state.activeCase!.name}' : ''}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10.0,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF90CAF9),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              Text(
                                step.description ?? step.type.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10.0),

                        // 4. Step Number Pill & Speed
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 3.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            'Step ${state.activeStepIndex}/${state.totalStepCount}  •  ${state.speedMultiplier}x',
                            style: const TextStyle(
                              fontSize: 10.0,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE0E0E0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIndicator(TestRunnerState state, Color statusColor) {
    if (state.isPaused) {
      return Container(
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.pause, size: 14.0, color: Colors.amber),
      );
    }

    return SizedBox(
      width: 14.0,
      height: 14.0,
      child: CircularProgressIndicator(
        strokeWidth: 2.0,
        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
      ),
    );
  }

  Color _getStatusColor(TestRunnerState state) {
    if (state.isPaused) return const Color(0xFFFFB300); // Amber
    if (state.activeStep?.status == TestStatus.failed) return const Color(0xFFFF5252); // Red
    if (state.activeStep?.status == TestStatus.passed) return const Color(0xFF00E676); // Emerald
    return const Color(0xFF00E5FF); // Neon Cyan
  }

  IconData _getActionIcon(TestStepType type) {
    switch (type) {
      case TestStepType.tap:
        return Icons.touch_app;
      case TestStepType.doubleTap:
        return Icons.gesture;
      case TestStepType.longPress:
        return Icons.pan_tool;
      case TestStepType.enterText:
        return Icons.keyboard;
      case TestStepType.clearText:
        return Icons.backspace;
      case TestStepType.scroll:
        return Icons.swap_vert;
      case TestStepType.drag:
        return Icons.drag_handle;
      case TestStepType.scrollTo:
        return Icons.arrow_downward;
      case TestStepType.expectVisible:
      case TestStepType.expectText:
        return Icons.visibility;
      case TestStepType.expectNotVisible:
        return Icons.visibility_off;
      case TestStepType.dismissKeyboard:
        return Icons.keyboard_hide;
      case TestStepType.wait:
        return Icons.timer;
      case TestStepType.custom:
        return Icons.code;
    }
  }
}
