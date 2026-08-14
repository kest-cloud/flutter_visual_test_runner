import 'dart:convert';
import '../models/test_report.dart';

/// Exports [TestReport] into standalone JSON and HTML report files.
class TestReportExporter {
  /// Export report as JSON string.
  static String toJson(TestReport report, {bool formatted = true}) {
    if (formatted) {
      return report.toFormattedJson();
    }
    return json.encode(report.toJson());
  }

  /// Export report as a standalone, styled, responsive HTML document.
  static String toHtml(TestReport report) {
    final passRate = report.passRatePercentage.toStringAsFixed(1);
    final statusColor = report.isSuccess ? '#00E676' : '#FF5252';
    final statusText = report.isSuccess ? 'PASSED' : 'FAILED';

    final scenariosHtml = report.scenarios.map((s) {
      final sName = s['name'] ?? 'Scenario';
      final sStatus = s['status'] ?? 'pending';
      final sDuration = s['durationMs'] ?? 0;
      final cases = (s['cases'] as List?) ?? [];

      final casesHtml = cases.map((c) {
        final cName = c['name'] ?? 'Case';
        final cStatus = c['status'] ?? 'pending';
        final cDuration = c['durationMs'] ?? 0;
        final cError = c['errorMessage'];
        final steps = (c['steps'] as List?) ?? [];

        final stepsHtml = steps.map((st) {
          final stType = st['type'] ?? '';
          final stDesc = st['description'] ?? stType;
          final stStatus = st['status'] ?? 'pending';
          final stDuration = st['executionDurationMs'] ?? 0;
          final isStepPass = stStatus == 'passed';
          final isStepFail = stStatus == 'failed';

          final badgeColor = isStepPass
              ? '#00E676'
              : (isStepFail ? '#FF5252' : '#9CA3AF');

          return '''
            <div class="step-row">
              <span class="status-badge" style="color: $badgeColor; border-color: $badgeColor;">$stStatus</span>
              <span class="step-desc">$stDesc</span>
              <span class="step-dur">${stDuration}ms</span>
            </div>
          ''';
        }).join('\n');

        return '''
          <div class="case-card">
            <div class="case-header">
              <span class="case-name">$cName</span>
              <span class="case-meta">${cDuration}ms • <strong>$cStatus</strong></span>
            </div>
            ${cError != null ? '<div class="error-box">$cError</div>' : ''}
            <div class="steps-list">
              $stepsHtml
            </div>
          </div>
        ''';
      }).join('\n');

      return '''
        <div class="scenario-card">
          <div class="scenario-header">
            <h3>$sName</h3>
            <span class="scenario-meta">${sDuration}ms • <strong>$sStatus</strong></span>
          </div>
          $casesHtml
        </div>
      ''';
    }).join('\n');

    final logsHtml = report.logs.map((l) {
      final lvl = l.level.name.toUpperCase();
      final msg = l.message;
      final err = l.error != null ? '<div class="log-err">${l.error}</div>' : '';
      return '<div class="log-line"><span class="log-lvl lvl-${l.level.name}">[$lvl]</span> $msg $err</div>';
    }).join('\n');

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Test Execution Report - ${report.suiteName}</title>
  <style>
    :root {
      --bg: #0B0F19;
      --surface: #111827;
      --surface-elevated: #1A2234;
      --cyan: #00E5FF;
      --emerald: #00E676;
      --crimson: #FF5252;
      --text: #F9FAFB;
      --text-muted: #9CA3AF;
      --border: rgba(255, 255, 255, 0.08);
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
      background: var(--bg);
      color: var(--text);
      padding: 32px 16px;
      line-height: 1.5;
    }
    .container { max-width: 900px; margin: 0 auto; }
    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      padding-bottom: 24px;
      border-bottom: 1px solid var(--border);
      margin-bottom: 24px;
    }
    .status-pill {
      background: rgba(255, 255, 255, 0.05);
      border: 2px solid $statusColor;
      color: $statusColor;
      font-weight: 900;
      padding: 6px 16px;
      border-radius: 20px;
      font-size: 14px;
      letter-spacing: 1px;
    }
    .metrics-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
      gap: 16px;
      margin-bottom: 32px;
    }
    .metric-card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 16px;
      text-align: center;
    }
    .metric-val { font-size: 24px; font-weight: 800; color: var(--cyan); margin-top: 4px; }
    .scenario-card {
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 14px;
      padding: 20px;
      margin-bottom: 20px;
    }
    .scenario-header {
      display: flex;
      justify-content: space-between;
      margin-bottom: 16px;
      padding-bottom: 8px;
      border-bottom: 1px solid var(--border);
    }
    .case-card {
      background: var(--surface-elevated);
      border-radius: 10px;
      padding: 14px;
      margin-bottom: 12px;
    }
    .case-header {
      display: flex;
      justify-content: space-between;
      font-weight: 700;
      font-size: 14px;
      margin-bottom: 8px;
    }
    .step-row {
      display: flex;
      align-items: center;
      padding: 6px 0;
      font-size: 12px;
      border-bottom: 1px solid rgba(255, 255, 255, 0.04);
    }
    .status-badge {
      font-size: 9px;
      font-weight: 800;
      padding: 2px 6px;
      border-radius: 4px;
      border: 1px solid;
      margin-right: 10px;
      text-transform: uppercase;
    }
    .step-desc { flex: 1; }
    .step-dur { color: var(--text-muted); font-size: 11px; }
    .error-box {
      background: rgba(255, 82, 82, 0.1);
      border-left: 3px solid var(--crimson);
      color: #FF8A80;
      padding: 8px 12px;
      font-size: 12px;
      margin-bottom: 10px;
      font-family: monospace;
    }
    .console-box {
      background: #070A10;
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 16px;
      font-family: monospace;
      font-size: 11px;
      max-height: 400px;
      overflow-y: auto;
    }
    .log-line { padding: 2px 0; }
    .log-lvl { font-weight: bold; margin-right: 6px; }
    .lvl-error { color: var(--crimson); }
    .lvl-warning { color: #FFB300; }
    .lvl-success { color: var(--emerald); }
    .lvl-info { color: var(--text); }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <div>
        <h1>${report.suiteName}</h1>
        <p style="color: var(--text-muted); font-size: 13px; margin-top: 4px;">
          Executed on ${report.startTime.toLocal()} • Duration: ${report.duration.inMilliseconds}ms
        </p>
      </div>
      <div class="status-pill">$statusText</div>
    </div>

    <div class="metrics-grid">
      <div class="metric-card">
        <div>Pass Rate</div>
        <div class="metric-val" style="color: $statusColor;">$passRate%</div>
      </div>
      <div class="metric-card">
        <div>Total Cases</div>
        <div class="metric-val">${report.totalCases}</div>
      </div>
      <div class="metric-card">
        <div>Passed</div>
        <div class="metric-val" style="color: var(--emerald);">${report.passedCases}</div>
      </div>
      <div class="metric-card">
        <div>Failed</div>
        <div class="metric-val" style="color: ${report.failedCases > 0 ? 'var(--crimson)' : 'var(--text-muted)'};">${report.failedCases}</div>
      </div>
    </div>

    <h2 style="margin-bottom: 16px;">Scenarios & Test Execution</h2>
    $scenariosHtml

    <h2 style="margin: 32px 0 16px;">Execution Console Logs</h2>
    <div class="console-box">
      $logsHtml
    </div>
  </div>
</body>
</html>
    ''';
  }
}
