import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controller/test_runner_controller.dart';
import '../../models/test_enums.dart';
import '../../utils/log_entry.dart';
import '../theme/runner_theme.dart';

/// Real-time live log console with log level filters, search, and expandable stack traces.
class LogConsoleView extends StatefulWidget {
  final TestRunnerController controller;

  const LogConsoleView({
    super.key,
    required this.controller,
  });

  @override
  State<LogConsoleView> createState() => _LogConsoleViewState();
}

class _LogConsoleViewState extends State<LogConsoleView> {
  final ScrollController _scrollController = ScrollController();
  RunnerLogLevel? _selectedLevel;
  final String _searchFilter = '';
  final bool _autoScroll = true;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final logs = widget.controller.state.logs;

        final filteredLogs = logs.where((l) {
          if (_selectedLevel != null && l.level != _selectedLevel) return false;
          if (_searchFilter.isNotEmpty) {
            final query = _searchFilter.toLowerCase();
            return l.message.toLowerCase().contains(query) ||
                (l.error?.toLowerCase().contains(query) ?? false);
          }
          return true;
        }).toList();

        // Auto scroll to bottom on new logs
        if (_autoScroll && _scrollController.hasClients) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
            }
          });
        }

        return Column(
          children: [
            // Controls & Filter Bar
            Container(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  // Filter Chips
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildLevelChip(null, 'ALL (${logs.length})'),
                          const SizedBox(width: 4.0),
                          _buildLevelChip(RunnerLogLevel.error, 'ERRORS'),
                          const SizedBox(width: 4.0),
                          _buildLevelChip(RunnerLogLevel.warning, 'WARNINGS'),
                          const SizedBox(width: 4.0),
                          _buildLevelChip(RunnerLogLevel.info, 'INFO'),
                          const SizedBox(width: 4.0),
                          _buildLevelChip(RunnerLogLevel.success, 'SUCCESS'),
                        ],
                      ),
                    ),
                  ),

                  // Copy Logs
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16.0, color: RunnerTheme.textSecondary),
                    tooltip: 'Copy all logs',
                    onPressed: () {
                      final allText = logs.map((l) => l.toString()).join('\n');
                      Clipboard.setData(ClipboardData(text: allText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logs copied to clipboard'), duration: Duration(seconds: 1)),
                      );
                    },
                  ),

                  // Clear Logs
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16.0, color: RunnerTheme.textSecondary),
                    tooltip: 'Clear logs',
                    onPressed: widget.controller.clearLogs,
                  ),
                ],
              ),
            ),

            // Log Console Window
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF070A10),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: filteredLogs.isEmpty
                    ? const Center(
                        child: Text(
                          'No logs recorded yet.',
                          style: TextStyle(color: RunnerTheme.textMuted, fontSize: 11.0),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: filteredLogs.length,
                        itemBuilder: (context, index) {
                          final entry = filteredLogs[index];
                          return _buildLogEntryRow(entry);
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLevelChip(RunnerLogLevel? level, String label) {
    final isSelected = _selectedLevel == level;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedLevel = level;
        });
      },
      selectedColor: RunnerTheme.neonCyan,
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      labelStyle: TextStyle(
        fontSize: 9.0,
        fontWeight: FontWeight.w700,
        color: isSelected ? const Color(0xFF090D16) : RunnerTheme.textSecondary,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.0)),
      side: BorderSide.none,
    );
  }

  Widget _buildLogEntryRow(RunnerLogEntry entry) {
    final color = _getLogColor(entry.level);
    final timeStr =
        '${entry.timestamp.hour.toString().padLeft(2, '0')}:${entry.timestamp.minute.toString().padLeft(2, '0')}:${entry.timestamp.second.toString().padLeft(2, '0')}.${entry.timestamp.millisecond.toString().padLeft(3, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '[$timeStr] ',
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 10.0,
                  color: RunnerTheme.textMuted,
                ),
              ),
              Expanded(
                child: Text(
                  entry.message,
                  style: TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 10.5,
                    color: color,
                    fontWeight: entry.level == RunnerLogLevel.error ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
          if (entry.error != null)
            Container(
              margin: const EdgeInsets.only(left: 12.0, top: 4.0),
              padding: const EdgeInsets.all(6.0),
              decoration: BoxDecoration(
                color: RunnerTheme.crimsonRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(color: RunnerTheme.crimsonRed.withValues(alpha: 0.3)),
              ),
              child: Text(
                entry.error!,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 10.0,
                  color: Color(0xFFFF8A80),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getLogColor(RunnerLogLevel level) {
    switch (level) {
      case RunnerLogLevel.error:
        return RunnerTheme.crimsonRed;
      case RunnerLogLevel.warning:
        return RunnerTheme.amberWarning;
      case RunnerLogLevel.success:
        return RunnerTheme.emeraldGreen;
      case RunnerLogLevel.info:
        return RunnerTheme.textPrimary;
      case RunnerLogLevel.debug:
        return RunnerTheme.textMuted;
    }
  }
}
