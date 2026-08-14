import 'dart:ui';
import 'package:flutter/material.dart';
import '../controller/test_runner_controller.dart';
import '../controller/test_runner_state.dart';
import 'components/control_bar.dart';
import 'components/log_console_view.dart';
import 'components/scenario_tree_view.dart';
import 'theme/runner_theme.dart';

/// Full interactive glassmorphic dashboard panel.
class TestRunnerDashboard extends StatefulWidget {
  final TestRunnerController controller;

  const TestRunnerDashboard({
    super.key,
    required this.controller,
  });

  @override
  State<TestRunnerDashboard> createState() => _TestRunnerDashboardState();
}

class _TestRunnerDashboardState extends State<TestRunnerDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        if (!state.isDashboardExpanded) {
          return const SizedBox.shrink();
        }

        final size = MediaQuery.of(context).size;
        final safePadding = MediaQuery.of(context).padding;
        final suite = state.suite;

        return Positioned.fill(
          child: Material(
            color: Colors.black54,
            child: Stack(
              children: [
                // Tap outside to collapse
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      widget.controller.setDashboardExpanded(false);
                    },
                    child: Container(color: Colors.transparent),
                  ),
                ),

                // Main Drawer Container
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: (size.height * 0.85).clamp(400.0, 750.0),
                    width: size.width > 700 ? 680.0 : size.width,
                    decoration: const BoxDecoration(
                      color: RunnerTheme.background,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
                      border: Border(
                        top: BorderSide(color: Color(0x3338BDF8), width: 1.5),
                        left: BorderSide(color: Color(0x3338BDF8), width: 1.0),
                        right: BorderSide(color: Color(0x3338BDF8), width: 1.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black87,
                          blurRadius: 30.0,
                          offset: Offset(0, -10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16.0, 12.0, 16.0, safePadding.bottom + 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Header & Drag Handle
                              Center(
                                child: Container(
                                  width: 40.0,
                                  height: 4.0,
                                  decoration: BoxDecoration(
                                    color: Colors.white24,
                                    borderRadius: BorderRadius.circular(2.0),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10.0),

                              Row(
                                children: [
                                  Container(
                                    width: 10.0,
                                    height: 10.0,
                                    decoration: const BoxDecoration(
                                      color: RunnerTheme.neonCyan,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: RunnerTheme.neonCyan,
                                          blurRadius: 8.0,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  const Text(
                                    'VISUAL TEST RUNNER',
                                    style: TextStyle(
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                      color: RunnerTheme.textPrimary,
                                    ),
                                  ),
                                  const Spacer(),

                                  // Overlay Toggle
                                  IconButton(
                                    icon: Icon(
                                      state.isOverlayVisible ? Icons.layers : Icons.layers_clear,
                                      size: 18.0,
                                      color: state.isOverlayVisible ? RunnerTheme.neonCyan : RunnerTheme.textMuted,
                                    ),
                                    tooltip: 'Toggle Visual Highlights',
                                    onPressed: () {
                                      widget.controller.setOverlayVisible(!state.isOverlayVisible);
                                    },
                                  ),

                                  // Close Button
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded, size: 20.0, color: RunnerTheme.textSecondary),
                                    onPressed: () {
                                      widget.controller.setDashboardExpanded(false);
                                    },
                                  ),
                                ],
                              ),

                              if (suite != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    suite.name,
                                    style: const TextStyle(
                                      fontSize: 11.0,
                                      fontWeight: FontWeight.w600,
                                      color: RunnerTheme.textSecondary,
                                    ),
                                  ),
                                ),

                              // 2. Control Bar
                              ControlBar(controller: widget.controller),
                              const SizedBox(height: 10.0),

                              // 3. Tab Navigation
                              TabBar(
                                controller: _tabController,
                                indicatorColor: RunnerTheme.neonCyan,
                                labelColor: RunnerTheme.neonCyan,
                                unselectedLabelColor: RunnerTheme.textMuted,
                                labelStyle: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold),
                                tabs: [
                                  Tab(text: 'SUITE (${suite?.totalCaseCount ?? 0})'),
                                  Tab(text: 'LOGS (${state.logs.length})'),
                                  const Tab(text: 'REPORT'),
                                ],
                              ),
                              const SizedBox(height: 10.0),

                              // 4. Tab Views
                              Expanded(
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    ScenarioTreeView(controller: widget.controller),
                                    LogConsoleView(controller: widget.controller),
                                    _buildReportTab(state),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportTab(TestRunnerState state) {
    final report = state.lastReport;
    final suite = state.suite;

    if (report == null && suite == null) {
      return const Center(
        child: Text('No test report available yet.', style: TextStyle(color: RunnerTheme.textMuted)),
      );
    }

    final totalCases = report?.totalCases ?? suite?.totalCaseCount ?? 0;
    final passedCases = report?.passedCases ?? suite?.passedCaseCount ?? 0;
    final failedCases = report?.failedCases ?? suite?.failedCaseCount ?? 0;
    final passRate = totalCases == 0 ? 0.0 : (passedCases / totalCases) * 100.0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metrics Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard('Pass Rate', '${passRate.toStringAsFixed(1)}%', RunnerTheme.emeraldGreen),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: _buildMetricCard('Passed', '$passedCases / $totalCases', RunnerTheme.neonCyan),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: _buildMetricCard('Failed', '$failedCases', failedCases > 0 ? RunnerTheme.crimsonRed : RunnerTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16.0),

          // Suite Configuration
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: RunnerTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Configuration', style: TextStyle(color: RunnerTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 12.0)),
                const SizedBox(height: 6.0),
                Text('• Default Timeout: ${suite?.defaultTimeout.inSeconds ?? 5}s', style: const TextStyle(color: RunnerTheme.textSecondary, fontSize: 11.0)),
                Text('• Auto-scroll into view: ${suite?.autoScrollToTarget ?? true}', style: const TextStyle(color: RunnerTheme.textSecondary, fontSize: 11.0)),
                Text('• Adaptive polling: ${suite?.adaptiveWait ?? true}', style: const TextStyle(color: RunnerTheme.textSecondary, fontSize: 11.0)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: RunnerTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 10.0, color: RunnerTheme.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4.0),
          Text(value, style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
