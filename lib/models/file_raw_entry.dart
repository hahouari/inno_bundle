import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:inno_bundle/models/dll_entry.dart';

/// Base Class holding the file entry properties.
class FileRawEntry {
  /// The path to the file.
  final String path;

  /// The name for the file. Defaults to the basename of the path.
  final String name;

  /// A flag indicating if the file is required. Defaults to true.
  final bool required;

  const FileRawEntry({
    required this.path,
    required this.name,
    this.required = true,
  });

  /// Get file absolute path.
  String get absolutePath {
    if (p.isAbsolute(path)) return path;
    return p.join(Directory.current.path, path);
  }

  static String? validateConfig(
    dynamic option, {
    required String propertyName,
    required String? requiredExtension,
  }) {
    if (option == null) return null;
    if (option is String) {
      if (requiredExtension != null && !option.toLowerCase().endsWith('.$requiredExtension')) {
        return "path in inno_bundle.$propertyName in pubspec.yaml must point to a $requiredExtension file, "
            "got $option.";
      }
      return null;
    }
    if (option is Map<String, dynamic>) {
      if (option['path'] == null) {
        return "path field is missing from inno_bundle.$propertyName entry in pubspec.yaml, "
            "it must be a string.";
      }
      final path = option['path'];
      if (path is! String) {
        return "path field in inno_bundle.$propertyName entry in pubspec.yaml must be a string.";
      }
      if (requiredExtension != null && !path.toLowerCase().endsWith('.$requiredExtension')) {
        return "path in inno_bundle.$propertyName in pubspec.yaml must point to a $requiredExtension file, "
            "got $path.";
      }
      if (option['name'] != null && option['name'] is! String) {
        return "name field in inno_bundle.$propertyName entry in pubspec.yaml must be a string or null.";
      }
      if (option['required'] != null && option['required'] is! bool) {
        return "required field in inno_bundle.$propertyName entry in pubspec.yaml must be a boolean or null.";
      }
      if (option['source'] != null && (option['source'] is! String || !DllSource.literalValues.contains(option['source']))) {
        return "source field in inno_bundle.$propertyName entry in pubspec.yaml must be "
            "one of ${DllSource.literalValues.join(', ')} or null.";
      }
      return null;
    }

    return "inno_bundle.$propertyName attribute is invalid in pubspec.yaml.";
  }

  factory FileRawEntry.fromJson(dynamic json) {
    assert(json != null);
    if (json is String) {
      return DllEntry(
        path: json,
        name: p.basename(json),
        required: true,
        source: DllSource.project,
      );
    }
    final path = json['path'] as String;
    final name = json['name'] as String? ?? p.basename(path);
    final required = json['required'] as bool? ?? true;

    return FileRawEntry(
      path: path,
      name: name,
      required: required,
    );
  }
}
