import 'dart:io';

import 'package:inno_setup/utils/cli_logger.dart';
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
Map<String, dynamic> getConfig({String? configFile}) {
  String filePath;
  if (configFile != null) {
    if (File(configFile).existsSync()) {
      filePath = configFile;
    } else {
      CliLogger.error('The config file `$configFile` was not found.');
      exit(1);
    }
  } else {
    filePath = 'pubspec.yaml';
  }

  final yamlMap = loadYaml(File(filePath).readAsStringSync()) as Map;

  if (yamlMap['inno_setup'] is! Map) {
    CliLogger.error("Your $filePath file does not contain a 'inno_setup' section.");
    exit(1);
  }

  // yamlMap has the type YamlMap, which has several unwanted side effects
  return yamlToMap(yamlMap['inno_setup'] as YamlMap);
}