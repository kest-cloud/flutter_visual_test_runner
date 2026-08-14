/// Flutter Visual Test Runner - In-App Live Test Execution Dashboard.
library;

// Models
export 'src/models/target_finder.dart';
export 'src/models/test_case.dart';
export 'src/models/test_enums.dart';
export 'src/models/test_report.dart';
export 'src/models/test_scenario.dart';
export 'src/models/test_step.dart';
export 'src/models/test_suite.dart';

// Controller & State
export 'src/controller/test_runner_controller.dart';
export 'src/controller/test_runner_state.dart';

// DSL & Natural Language Parser
export 'src/dsl/natural_language_test_parser.dart';
export 'src/dsl/test_case_converter.dart';

// Engines
export 'src/engine/assertion_engine.dart';
export 'src/engine/gesture_simulator.dart';
export 'src/engine/step_execution_engine.dart';
export 'src/engine/widget_finder_engine.dart';

// Overlay & Highlights
export 'src/overlay/ripple_effect_painter.dart';
export 'src/overlay/step_status_banner.dart';
export 'src/overlay/target_highlight_painter.dart';
export 'src/overlay/visual_overlay_layer.dart';

// Dashboard & UI
export 'src/dashboard/components/control_bar.dart';
export 'src/dashboard/components/log_console_view.dart';
export 'src/dashboard/components/scenario_tree_view.dart';
export 'src/dashboard/floating_badge.dart';
export 'src/dashboard/test_runner_dashboard.dart';
export 'src/dashboard/theme/runner_theme.dart';
export 'src/dashboard/visual_test_runner.dart';

// Serialization & Reporting
export 'src/serialization/test_report_exporter.dart';
export 'src/serialization/test_spec_parser.dart';

// Utilities
export 'src/utils/log_entry.dart';
