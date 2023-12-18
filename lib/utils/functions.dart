import 'dart:io';

import 'package:inno_setup/models/config.dart';
import 'package:yaml/yaml.dart';

/// Convert yaml to map
Map<String, dynamic> yamlToMap(YamlMap yamlMap) {
  final map = <String, dynamic>{};
  for (final entry in yamlMap.entries) {
    if (entry.value is YamlList) {
      final list = <String>[];
      for (final value in entry.value as YamlList) {
        if (value is String) {
          list.add(value);
        }
      }
      map[entry.key as String] = list;
    } else if (entry.value is YamlMap) {
      map[entry.key as String] = yamlToMap(entry.value as YamlMap);
    } else {
      map[entry.key as String] = entry.value;
    }
  }
  return map;
}

/// Get config file
Config getConfig({String? configFile}) {
  const filePath = 'pubspec.yaml';
  final yamlMap = loadYaml(File(filePath).readAsStringSync()) as Map;
  // yamlMap has the type YamlMap, which has several unwanted side effects
  final yamlConfig = yamlToMap(yamlMap as YamlMap);
  return Config.fromJson(yamlConfig);
}

String camelCase(String value) {
  return value
      .split(RegExp(r'[-_]'))
      .map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1))
      .join('');
}
