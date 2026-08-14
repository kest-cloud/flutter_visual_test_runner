import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import '../models/test_suite.dart';

/// Parses test suites from JSON, YAML, or asset files.
class TestSpecParser {
  /// Parse a YAML string into a [TestSuite].
  static TestSuite parseYaml(String yamlContent) {
    final doc = loadYaml(yamlContent);
    if (doc is! Map) {
      throw const FormatException('Invalid YAML test spec: root must be a map');
    }

    final jsonMap = _convertYamlMapToJsonMap(doc);
    return TestSuite.fromJson(jsonMap);
  }

  /// Parse a JSON string into a [TestSuite].
  static TestSuite parseJson(String jsonContent) {
    final decoded = json.decode(jsonContent);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid JSON test spec: root must be a map');
    }
    return TestSuite.fromJson(decoded);
  }

  /// Load and parse a test suite from a Flutter asset file.
  static Future<TestSuite> fromAsset(String assetPath) async {
    final content = await rootBundle.loadString(assetPath);
    if (assetPath.endsWith('.yaml') || assetPath.endsWith('.yml')) {
      return parseYaml(content);
    } else if (assetPath.endsWith('.json')) {
      return parseJson(content);
    } else {
      // Treat as plain natural English text
      return TestSuite.fromNaturalLanguage(content, name: assetPath.split('/').last);
    }
  }

  static Map<String, dynamic> _convertYamlMapToJsonMap(dynamic yamlMap) {
    final result = <String, dynamic>{};

    if (yamlMap is YamlMap || yamlMap is Map) {
      yamlMap.forEach((key, value) {
        result[key.toString()] = _convertYamlNode(value);
      });
    }

    return result;
  }

  static dynamic _convertYamlNode(dynamic node) {
    if (node is YamlMap || node is Map) {
      return _convertYamlMapToJsonMap(node);
    } else if (node is YamlList || node is List) {
      return node.map(_convertYamlNode).toList();
    }
    return node;
  }
}
