import 'package:flutter/material.dart';
import '../engine/step_execution_engine.dart';
import '../engine/widget_finder_engine.dart';
import '../controller/test_runner_controller.dart';
import '../controller/test_runner_state.dart';
import '../models/test_enums.dart';
import '../models/test_scenario.dart';
import '../models/test_suite.dart';
import '../overlay/visual_overlay_layer.dart';
import '../serialization/test_spec_parser.dart';
import 'floating_badge.dart';
import 'test_runner_dashboard.dart';
import 'theme/runner_theme.dart';

/// Top-level wrapper widget that equips any Flutter application with the interactive visual test runner.
///
/// Can be initialized directly with:
/// - A Dart [TestSuite] or list of [TestScenario]s (.dart)
/// - An asset file path [specPath] pointing to a `.md`, `.txt`, `.yaml`, or `.json` file
/// - A raw markdown or natural language string [specText]
class VisualTestRunner extends StatefulWidget {
  /// The root application widget (e.g. `MaterialApp` or `CupertinoApp`).
  final Widget child;

  /// Optional pre-configured Dart test suite.
  final TestSuite? suite;

  /// Optional asset file path (e.g. `assets/test_specs/tests.md` or `.txt`, `.yaml`, `.json`).
  final String? specPath;

  /// Optional raw markdown or plain text containing test cases.
  final String? specText;

  /// Optional custom controller instance.
  final TestRunnerController? controller;

  /// Whether the visual test runner is enabled (typically disabled in production release builds).
  final bool enabled;

  /// Initial execution speed multiplier (e.g. 1.0, 2.0).
  final double initialSpeed;

  /// Whether to automatically start executing the test suite on application launch.
  final bool autoStart;

  /// Delay before auto-starting the test suite (allows initial UI and animations to settle).
  final Duration autoStartDelay;

  const VisualTestRunner({
    super.key,
    required this.child,
    this.suite,
    this.specPath,
    this.specText,
    this.controller,
    this.enabled = true,
    this.initialSpeed = 1.0,
    this.autoStart = false,
    this.autoStartDelay = const Duration(milliseconds: 600),
  });

  /// Create a runner from a file in Flutter assets (`.md`, `.txt`, `.yaml`, `.json`).
  factory VisualTestRunner.fromAsset({
    Key? key,
    required Widget child,
    required String assetPath,
    bool enabled = true,
    double initialSpeed = 1.0,
    bool autoStart = false,
    Duration autoStartDelay = const Duration(milliseconds: 600),
  }) {
    return VisualTestRunner(
      key: key,
      specPath: assetPath,
      enabled: enabled,
      initialSpeed: initialSpeed,
      autoStart: autoStart,
      autoStartDelay: autoStartDelay,
      child: child,
    );
  }

  /// Create a runner wrapper from a Dart [TestSuite].
  factory VisualTestRunner.fromSuite({
    Key? key,
    required Widget child,
    required TestSuite suite,
    bool enabled = true,
    double initialSpeed = 1.0,
    bool autoStart = false,
    Duration autoStartDelay = const Duration(milliseconds: 600),
  }) {
    return VisualTestRunner(
      key: key,
      suite: suite,
      enabled: enabled,
      initialSpeed: initialSpeed,
      autoStart: autoStart,
      autoStartDelay: autoStartDelay,
      child: child,
    );
  }

  /// Create a runner wrapper from Markdown or plain English text.
  factory VisualTestRunner.fromMarkdown({
    Key? key,
    required Widget child,
    required String markdown,
    String? suiteName,
    bool enabled = true,
    double initialSpeed = 1.0,
    bool autoStart = false,
    Duration autoStartDelay = const Duration(milliseconds: 600),
  }) {
    final suite = TestSuite.fromNaturalLanguage(markdown, name: suiteName);
    return VisualTestRunner(
      key: key,
      suite: suite,
      enabled: enabled,
      initialSpeed: initialSpeed,
      autoStart: autoStart,
      autoStartDelay: autoStartDelay,
      child: child,
    );
  }

  /// Create a runner wrapper from natural English text or markdown.
  factory VisualTestRunner.fromNaturalLanguage({
    Key? key,
    required Widget child,
    required String text,
    String? suiteName,
    bool enabled = true,
    double initialSpeed = 1.0,
    bool autoStart = false,
    Duration autoStartDelay = const Duration(milliseconds: 600),
  }) {
    final suite = TestSuite.fromNaturalLanguage(text, name: suiteName);
    return VisualTestRunner(
      key: key,
      suite: suite,
      enabled: enabled,
      initialSpeed: initialSpeed,
      autoStart: autoStart,
      autoStartDelay: autoStartDelay,
      child: child,
    );
  }

  /// Create a runner wrapper from a list of [TestScenario]s.
  factory VisualTestRunner.fromScenarios({
    Key? key,
    required Widget child,
    required List<TestScenario> scenarios,
    String suiteName = 'App Test Suite',
    bool enabled = true,
    double initialSpeed = 1.0,
    bool autoStart = false,
    Duration autoStartDelay = const Duration(milliseconds: 600),
  }) {
    final suite = TestSuite(name: suiteName, scenarios: scenarios);
    return VisualTestRunner(
      key: key,
      suite: suite,
      enabled: enabled,
      initialSpeed: initialSpeed,
      autoStart: autoStart,
      autoStartDelay: autoStartDelay,
      child: child,
    );
  }

  @override
  State<VisualTestRunner> createState() => _VisualTestRunnerState();
}

class _VisualTestRunnerState extends State<VisualTestRunner> {
  late TestRunnerController _controller;
  bool _internalController = false;
  final GlobalKey _hostKey = GlobalKey(debugLabel: '__visual_test_runner_host_app__');

  @override
  void initState() {
    super.initState();
    WidgetFinderEngine.hostAppKey = _hostKey;

    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      TestSuite? initialSuite = widget.suite;
      if (initialSuite == null && widget.specText != null) {
        initialSuite = TestSuite.fromNaturalLanguage(widget.specText!);
      }
      _controller = TestRunnerController(
        initialSuite: initialSuite,
        initialSpeed: widget.initialSpeed,
      );
      _internalController = true;
    }

    // Attach step execution engine
    _controller.stepExecutor = StepExecutionEngine.executeStep;

    // Load from asset file asynchronously if specPath is specified
    if (widget.specPath != null && widget.enabled) {
      _loadAssetSpec(widget.specPath!);
    } else if (widget.autoStart && widget.enabled && _controller.suite != null) {
      _scheduleAutoStart();
    }
  }

  Future<void> _loadAssetSpec(String path) async {
    try {
      final loadedSuite = await TestSpecParser.fromAsset(path);
      if (mounted) {
        _controller.setSuite(loadedSuite);
        if (widget.autoStart) {
          _scheduleAutoStart();
        }
      }
    } catch (e, st) {
      _controller.log(
        'Failed to load test spec file from "$path": $e',
        level: RunnerLogLevel.error,
        error: e.toString(),
        stackTrace: st,
      );
    }
  }

  void _scheduleAutoStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(widget.autoStartDelay, () {
        if (mounted &&
            _controller.state.executionState == RunnerExecutionState.idle &&
            _controller.suite != null) {
          _controller.runAll();
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant VisualTestRunner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.suite != null && widget.suite != oldWidget.suite) {
      _controller.setSuite(widget.suite!);
    }
  }

  @override
  void dispose() {
    if (WidgetFinderEngine.hostAppKey == _hostKey) {
      WidgetFinderEngine.hostAppKey = null;
    }
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Localizations(
        locale: const Locale('en', 'US'),
        delegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Theme(
          data: ThemeData.dark().copyWith(
            primaryColor: RunnerTheme.neonCyan,
            scaffoldBackgroundColor: RunnerTheme.background,
          ),
          child: Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) {
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1. Host Application (Isolated under _hostKey)
                      KeyedSubtree(
                        key: _hostKey,
                        child: widget.child,
                      ),

                      // 2. Visual Overlay Layer (Highlights, pointer ripples, HUD banner)
                      VisualOverlayLayer(controller: _controller),

                      // 3. Floating Draggable Badge
                      FloatingBadge(controller: _controller),

                      // 4. Full Dashboard Drawer / Sheet
                      TestRunnerDashboard(controller: _controller),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
