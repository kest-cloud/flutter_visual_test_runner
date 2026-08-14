import 'package:flutter/material.dart';
import '../controller/test_runner_controller.dart';
import '../models/test_enums.dart';
import 'ripple_effect_painter.dart';
import 'step_status_banner.dart';
import 'target_highlight_painter.dart';

/// Top-level visual overlay layer that renders animated target widget highlights,
/// pointer ripples, and active step status banners over the running application.
class VisualOverlayLayer extends StatefulWidget {
  final TestRunnerController controller;

  const VisualOverlayLayer({
    super.key,
    required this.controller,
  });

  @override
  State<VisualOverlayLayer> createState() => _VisualOverlayLayerState();
}

class _VisualOverlayLayerState extends State<VisualOverlayLayer>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _rippleController;

  Rect? _lastRect;
  Offset? _lastPoint;
  TestStepType? _lastAction;

  @override
  void initState() {
    super.initState();

    // On-demand pulse for target highlight bounding boxes
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Action ripple animation
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    widget.controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    final state = widget.controller.state;
    if (state.activeTargetPoint != _lastPoint ||
        state.activeActionType != _lastAction ||
        state.activeTargetRect != _lastRect) {
      _lastPoint = state.activeTargetPoint;
      _lastAction = state.activeActionType;
      _lastRect = state.activeTargetRect;

      if (_lastRect != null || _lastPoint != null) {
        if (!_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        }
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }

      if (_lastPoint != null && _lastAction != null) {
        _rippleController.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        if (!state.isOverlayVisible) {
          return const SizedBox.shrink();
        }

        return IgnorePointer(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Target Bounding Box & Crosshair Highlight
              ListenableBuilder(
                listenable: _pulseController,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: TargetHighlightPainter(
                      targetRect: state.activeTargetRect,
                      targetPoint: state.activeTargetPoint,
                      animationProgress: _pulseController.value,
                    ),
                  );
                },
              ),

              // 2. Action Touch Ripple Shockwave
              ListenableBuilder(
                listenable: _rippleController,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size.infinite,
                    painter: RippleEffectPainter(
                      touchPoint: state.activeTargetPoint,
                      actionType: state.activeActionType,
                      animationProgress: _rippleController.value,
                    ),
                  );
                },
              ),

              // 3. Top Floating HUD Step Status Banner
              StepStatusBanner(controller: widget.controller),
            ],
          ),
        );
      },
    );
  }
}
