import 'package:flutter/foundation.dart';
import '../models/test_enums.dart';

/// Represents a single execution log entry in the visual test runner console.
@immutable
class RunnerLogEntry {
  final String id;
  final DateTime timestamp;
  final RunnerLogLevel level;
  final String message;
  final String? scenarioName;
  final String? caseName;
  final String? stepId;
  final String? error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? metadata;

  RunnerLogEntry({
    String? id,
    DateTime? timestamp,
    required this.level,
    required this.message,
    this.scenarioName,
    this.caseName,
    this.stepId,
    this.error,
    this.stackTrace,
    this.metadata,
  })  : id = id ?? UniqueKey().toString(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'level': level.name,
      'message': message,
      'scenarioName': scenarioName,
      'caseName': caseName,
      'stepId': stepId,
      'error': error,
      'stackTrace': stackTrace?.toString(),
      'metadata': metadata,
    };
  }

  factory RunnerLogEntry.fromJson(Map<String, dynamic> json) {
    return RunnerLogEntry(
      id: json['id'] as String?,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
      level: RunnerLogLevel.values.firstWhere(
        (l) => l.name == json['level'],
        orElse: () => RunnerLogLevel.info,
      ),
      message: json['message'] as String? ?? '',
      scenarioName: json['scenarioName'] as String?,
      caseName: json['caseName'] as String?,
      stepId: json['stepId'] as String?,
      error: json['error'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    final tag = level.name.toUpperCase().padRight(7);
    return '[$timeStr] [$tag] $message';
  }
}
