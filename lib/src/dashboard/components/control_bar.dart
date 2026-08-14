import 'package:flutter/material.dart';
import '../../controller/test_runner_controller.dart';
import '../theme/runner_theme.dart';

/// Interactive execution control bar with Play, Pause, Resume, Step-Over, Speed selector, and Tag filters.
class ControlBar extends StatelessWidget {
  final TestRunnerController controller;

  const ControlBar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;
        final isRunning = state.isRunning;
        final isPaused = state.isPaused;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: RunnerTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Primary Play / Pause / Step Actions
              Row(
                children: [
                  // Play / Run All or Resume
                  if (!isRunning && !isPaused)
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RunnerTheme.neonCyan,
                          foregroundColor: const Color(0xFF090D16),
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                          elevation: 4.0,
                        ),
                        onPressed: () {
                          controller.runAll(context: context);
                        },
                        icon: const Icon(Icons.play_arrow_rounded, size: 20.0),
                        label: const Text(
                          'RUN ALL SUITE',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.0, letterSpacing: 0.5),
                        ),
                      ),
                    )
                  else if (isPaused)
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RunnerTheme.emeraldGreen,
                          foregroundColor: const Color(0xFF090D16),
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                        ),
                        onPressed: controller.resume,
                        icon: const Icon(Icons.play_arrow_rounded, size: 20.0),
                        label: const Text(
                          'RESUME',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.0),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RunnerTheme.amberWarning,
                          foregroundColor: const Color(0xFF090D16),
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                        ),
                        onPressed: controller.pause,
                        icon: const Icon(Icons.pause_rounded, size: 20.0),
                        label: const Text(
                          'PAUSE',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.0),
                        ),
                      ),
                    ),

                  const SizedBox(width: 8.0),

                  // Step Next (Step-over debugger button)
                  IconButton.filledTonal(
                    tooltip: 'Step Next',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      foregroundColor: RunnerTheme.textPrimary,
                    ),
                    onPressed: isPaused ? controller.stepNext : null,
                    icon: const Icon(Icons.skip_next_rounded, size: 20.0),
                  ),

                  const SizedBox(width: 4.0),

                  // Stop
                  IconButton.filledTonal(
                    tooltip: 'Stop Execution',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      foregroundColor: RunnerTheme.crimsonRed,
                    ),
                    onPressed: isRunning || isPaused ? controller.stop : null,
                    icon: const Icon(Icons.stop_rounded, size: 20.0),
                  ),

                  const SizedBox(width: 4.0),

                  // Reset
                  IconButton.filledTonal(
                    tooltip: 'Reset Suite',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      foregroundColor: RunnerTheme.textSecondary,
                    ),
                    onPressed: controller.reset,
                    icon: const Icon(Icons.refresh_rounded, size: 20.0),
                  ),
                ],
              ),

              const SizedBox(height: 12.0),
              const Divider(color: Color(0x1AFFFFFF), height: 1.0),
              const SizedBox(height: 10.0),

              // 2. Speed Multiplier Selection & Step Mode
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12.0,
                runSpacing: 10.0,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'SPEED:',
                        style: TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.w800,
                          color: RunnerTheme.textMuted,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 6.0),
                      Wrap(
                        spacing: 4.0,
                        children: [0.25, 0.5, 1.0, 2.0, 4.0].map((speed) {
                          final isSelected = (state.speedMultiplier - speed).abs() < 0.01;
                          return ChoiceChip(
                            label: Text('${speed}x'),
                            selected: isSelected,
                            onSelected: (_) => controller.setSpeedMultiplier(speed),
                            selectedColor: RunnerTheme.neonCyan,
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            labelStyle: TextStyle(
                              fontSize: 10.0,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? const Color(0xFF090D16) : RunnerTheme.textSecondary,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                            side: BorderSide.none,
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  // Debugger Step-by-step mode toggle
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'STEP MODE',
                        style: TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.w700,
                          color: RunnerTheme.textMuted,
                        ),
                      ),
                      const SizedBox(width: 4.0),
                      Switch(
                        value: state.isStepByStepMode,
                        onChanged: controller.setStepByStepMode,
                        activeThumbColor: RunnerTheme.neonCyan,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
