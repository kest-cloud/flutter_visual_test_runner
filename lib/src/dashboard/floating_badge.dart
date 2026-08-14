import 'dart:ui';
import 'package:flutter/material.dart';
import '../controller/test_runner_controller.dart';
import 'theme/runner_theme.dart';

/// Draggable floating badge allowing quick monitoring and one-tap expansion of dashboard.
class FloatingBadge extends StatefulWidget {
  final TestRunnerController controller;

  const FloatingBadge({
    super.key,
    required this.controller,
  });

  @override
  State<FloatingBadge> createState() => _FloatingBadgeState();
}

class _FloatingBadgeState extends State<FloatingBadge> {
  Offset? _position;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        if (state.isDashboardExpanded) {
          return const SizedBox.shrink();
        }

        final screenSize = MediaQuery.of(context).size;
        final safePadding = MediaQuery.of(context).padding;

        // Default position: top right
        _position ??= Offset(
          screenSize.width - 170.0,
          safePadding.top + 50.0,
        );

        final suite = state.suite;
        final passedCount = suite?.passedCaseCount ?? 0;
        final failedCount = suite?.failedCaseCount ?? 0;
        final isRunning = state.isRunning;
        final isPaused = state.isPaused;

        final badgeBorderColor = failedCount > 0
            ? RunnerTheme.crimsonRed
            : isRunning
                ? RunnerTheme.neonCyan
                : isPaused
                    ? RunnerTheme.amberWarning
                    : passedCount > 0
                        ? RunnerTheme.emeraldGreen
                        : const Color(0xFF38BDF8);

        return Positioned(
          left: _position!.dx.clamp(8.0, screenSize.width - 180.0),
          top: _position!.dy.clamp(safePadding.top + 8.0, screenSize.height - 70.0),
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _position = _position! + details.delta;
              });
            },
            onTap: () {
              widget.controller.setDashboardExpanded(true);
            },
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: const Color(0xE60B0F19),
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(color: badgeBorderColor.withValues(alpha: 0.7), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: badgeBorderColor.withValues(alpha: 0.3),
                          blurRadius: 14.0,
                          spreadRadius: 1.0,
                        ),
                        const BoxShadow(
                          color: Colors.black54,
                          blurRadius: 8.0,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. Status Icon
                        if (isRunning)
                          const SizedBox(
                            width: 14.0,
                            height: 14.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(RunnerTheme.neonCyan),
                            ),
                          )
                        else if (isPaused)
                          const Icon(Icons.pause_circle_filled, size: 16.0, color: RunnerTheme.amberWarning)
                        else if (failedCount > 0)
                          const Icon(Icons.cancel, size: 16.0, color: RunnerTheme.crimsonRed)
                        else if (passedCount > 0)
                          const Icon(Icons.check_circle, size: 16.0, color: RunnerTheme.emeraldGreen)
                        else
                          const Icon(Icons.play_circle_fill, size: 16.0, color: RunnerTheme.neonCyan),
                        const SizedBox(width: 8.0),

                        // 2. Pass / Fail Pill Counters
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$passedCount',
                              style: const TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w800,
                                color: RunnerTheme.emeraldGreen,
                              ),
                            ),
                            const Text(
                              ' ✓  ',
                              style: TextStyle(
                                fontSize: 10.0,
                                fontWeight: FontWeight.bold,
                                color: RunnerTheme.emeraldGreen,
                              ),
                            ),
                            Text(
                              '$failedCount',
                              style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w800,
                                color: failedCount > 0 ? RunnerTheme.crimsonRed : RunnerTheme.textMuted,
                              ),
                            ),
                            Text(
                              ' ✗',
                              style: TextStyle(
                                fontSize: 10.0,
                                fontWeight: FontWeight.bold,
                                color: failedCount > 0 ? RunnerTheme.crimsonRed : RunnerTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8.0),

                        // 3. Mini chevron
                        const Icon(
                          Icons.open_in_full,
                          size: 11.0,
                          color: RunnerTheme.textSecondary,
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
}
