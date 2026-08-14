import 'package:flutter/material.dart';
import '../../controller/test_runner_controller.dart';
import '../../models/test_case.dart';
import '../../models/test_enums.dart';
import '../../models/test_scenario.dart';
import '../../models/test_step.dart';
import '../theme/runner_theme.dart';

/// Collapsible tree view showing scenarios, cases, and steps with status icons and breakpoint controls.
class ScenarioTreeView extends StatefulWidget {
  final TestRunnerController controller;

  const ScenarioTreeView({
    super.key,
    required this.controller,
  });

  @override
  State<ScenarioTreeView> createState() => _ScenarioTreeViewState();
}

class _ScenarioTreeViewState extends State<ScenarioTreeView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final suite = widget.controller.state.suite;
        if (suite == null || suite.scenarios.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 48.0, color: RunnerTheme.textMuted.withValues(alpha: 0.5)),
                const SizedBox(height: 12.0),
                const Text(
                  'No Test Scenarios Loaded',
                  style: TextStyle(color: RunnerTheme.textSecondary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }

        final filteredScenarios = suite.scenarios.where((scenario) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return scenario.name.toLowerCase().contains(q) ||
              scenario.cases.any((c) => c.name.toLowerCase().contains(q));
        }).toList();

        return Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: TextField(
                style: const TextStyle(fontSize: 12.0, color: RunnerTheme.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search scenarios, test cases...',
                  hintStyle: const TextStyle(fontSize: 12.0, color: RunnerTheme.textMuted),
                  prefixIcon: const Icon(Icons.search, size: 16.0, color: RunnerTheme.textMuted),
                  filled: true,
                  fillColor: RunnerTheme.surfaceElevated,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
            ),

            // Scenario List
            Expanded(
              child: ListView.separated(
                itemCount: filteredScenarios.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8.0),
                itemBuilder: (context, index) {
                  final scenario = filteredScenarios[index];
                  return _buildScenarioCard(scenario);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildScenarioCard(TestScenario scenario) {
    return Container(
      decoration: BoxDecoration(
        color: RunnerTheme.cardGlass,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 2.0),
          leading: _buildStatusIcon(scenario.status),
          title: Text(
            scenario.name,
            style: const TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.w700,
              color: RunnerTheme.textPrimary,
            ),
          ),
          subtitle: scenario.tags.isNotEmpty
              ? Wrap(
                  spacing: 4.0,
                  children: scenario.tags
                      .map((t) => Container(
                            margin: const EdgeInsets.only(top: 2.0),
                            padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 1.0),
                            decoration: BoxDecoration(
                              color: RunnerTheme.neonCyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              t,
                              style: const TextStyle(
                                fontSize: 9.0,
                                fontWeight: FontWeight.bold,
                                color: RunnerTheme.neonCyan,
                              ),
                            ),
                          ))
                      .toList(),
                )
              : null,
          trailing: IconButton(
            icon: const Icon(Icons.play_circle_outline, size: 20.0, color: RunnerTheme.neonCyan),
            tooltip: 'Run Scenario',
            onPressed: () {
              widget.controller.runScenario(scenario, context: context);
            },
          ),
          children: scenario.cases.map((testCase) => _buildCaseCard(scenario, testCase)).toList(),
        ),
      ),
    );
  }

  Widget _buildCaseCard(TestScenario parentScenario, TestCase testCase) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16.0, 0.0, 8.0, 6.0),
      decoration: BoxDecoration(
        color: RunnerTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0.0),
        leading: _buildStatusIcon(testCase.status, isSmall: true),
        title: Text(
          testCase.name,
          style: const TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            color: RunnerTheme.textPrimary,
          ),
        ),
        subtitle: testCase.duration > Duration.zero
            ? Text(
                '${testCase.duration.inMilliseconds}ms',
                style: const TextStyle(fontSize: 10.0, color: RunnerTheme.textMuted),
              )
            : null,
        trailing: IconButton(
          icon: const Icon(Icons.play_arrow_outlined, size: 18.0, color: RunnerTheme.emeraldGreen),
          tooltip: 'Run Case',
          onPressed: () {
            widget.controller.runCase(testCase, context: context, parentScenario: parentScenario);
          },
        ),
        children: testCase.steps.map((step) => _buildStepRow(step)).toList(),
      ),
    );
  }

  Widget _buildStepRow(TestStep step) {
    final isActive = widget.controller.state.activeStep?.id == step.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: isActive ? RunnerTheme.neonCyan.withValues(alpha: 0.1) : Colors.transparent,
      ),
      child: Row(
        children: [
          // Breakpoint Toggle Circle
          GestureDetector(
            onTap: () {
              widget.controller.toggleBreakpoint(step);
            },
            child: Container(
              width: 10.0,
              height: 10.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: step.isBreakpoint ? RunnerTheme.crimsonRed : Colors.transparent,
                border: Border.all(
                  color: step.isBreakpoint ? RunnerTheme.crimsonRed : Colors.white30,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10.0),

          // Status Icon
          _buildStatusIcon(step.status, isSmall: true),
          const SizedBox(width: 8.0),

          // Step Description
          Expanded(
            child: Text(
              step.description ?? step.type.name,
              style: TextStyle(
                fontSize: 11.0,
                color: isActive ? RunnerTheme.neonCyan : RunnerTheme.textSecondary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),

          // Step Duration
          if (step.executionDuration > Duration.zero)
            Text(
              '${step.executionDuration.inMilliseconds}ms',
              style: const TextStyle(fontSize: 9.0, color: RunnerTheme.textMuted),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(TestStatus status, {bool isSmall = false}) {
    final size = isSmall ? 14.0 : 18.0;

    switch (status) {
      case TestStatus.passed:
        return Icon(Icons.check_circle_rounded, size: size, color: RunnerTheme.emeraldGreen);
      case TestStatus.failed:
        return Icon(Icons.cancel_rounded, size: size, color: RunnerTheme.crimsonRed);
      case TestStatus.running:
        return SizedBox(
          width: size,
          height: size,
          child: const CircularProgressIndicator(strokeWidth: 2.0, valueColor: AlwaysStoppedAnimation(RunnerTheme.neonCyan)),
        );
      case TestStatus.paused:
        return Icon(Icons.pause_circle_rounded, size: size, color: RunnerTheme.amberWarning);
      case TestStatus.skipped:
        return Icon(Icons.next_plan_outlined, size: size, color: RunnerTheme.textMuted);
      case TestStatus.pending:
        return Icon(Icons.radio_button_unchecked, size: size, color: Colors.white24);
    }
  }
}
