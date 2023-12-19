import 'dart:io';

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

String camelCase(String value) {
  return value
      .split(RegExp(r'[-_]'))
      .map((word) => word.isEmpty ? '' : capitalize(word))
      .join('');
}

String capitalize(String value) {
  return value[0].toUpperCase() + value.substring(1);
}

String getTempDir() {
  return Process.runSync('cmd', ['/C', 'echo %Temp%']).stdout;
}
