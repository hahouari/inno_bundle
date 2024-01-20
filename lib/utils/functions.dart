import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:inno_bundle/utils/installer_icon.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;

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

String persistDefaultInstallerIcon(String dirPath) {
  final iconPath = p.join(dirPath, defaultInstallerIconFileName);
  File file = File(iconPath);
  Uint8List bytes = base64.decode(defaultInstallerIcon);
  file.writeAsBytesSync(bytes);
  return file.absolute.path;
}
