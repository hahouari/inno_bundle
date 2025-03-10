/// A class that represents a DLL entry for use in Inno Setup.
///
/// The [DllEntry] class encapsulates the path to the DLL, an optional name,
/// a flag indicating if the DLL is required, and the source of the DLL
/// (either the project or the system32 directory).
///
/// Example usage:
/// ```dart
/// var dllEntry = DllEntry(
///   path: "mydll.dll",
///   required: true,
///   source: DllSource.project,
/// );
///
/// print(dllEntry.path); // Outputs: mydll.dll
/// print(dllEntry.name); // Outputs: mydll.dll
/// print(dllEntry.required); // Outputs: true
/// print(dllEntry.source); // Outputs: DllSource.project
/// ```
///
/// Properties:
/// - [path]: The path to the DLL file.
/// - [name]: The name for the DLL. Defaults to the basename of the path.
/// - [required]: A flag indicating if the DLL is required. Defaults to true.
/// - [source]: An enum indicating the source of the DLL. Defaults to DllSource.project.
library;

import 'dart:io';

import 'package:inno_bundle/utils/constants.dart';
import 'package:path/path.dart' as p;

/// Enum representing the source of the DLL.
enum DllSource {
  /// The DLL is located in the project directory.
  project,

  /// The DLL is located in the system32 directory.
  system32;

  /// Return string array of literal values.
  static List<String> get literalValues => values.map((e) => e.name).toList();
}

/// Class holding the DLL entry properties.
class DllEntry {
  /// The path to the DLL file.
  final String path;

  /// The name for the DLL. Defaults to the basename of the path.
  final String name;

  /// A flag indicating if the DLL is required. Defaults to true.
  final bool required;

  /// An enum indicating the source of the DLL. Defaults to DllSource.project.
  final DllSource source;

  DllEntry({
    required this.path,
    required this.name,
    this.required = true,
    this.source = DllSource.project,
  });

  static String? validateConfig(dynamic option) {
    if (option == null) return null;
    if (option is String) {
      if (!option.toLowerCase().endsWith('.dll')) {
        return "path in inno_bundle.dlls in pubspec.yaml must point to a DLL file, "
            "got $option.";
      }
      return null;
    }
    if (option is Map<String, dynamic>) {
      if (option['path'] == null) {
        return "path field is missing from inno_bundle.dlls entry in pubspec.yaml, "
            "it must be a string.";
      }
      final path = option['path'];
      if (path is! String) {
        return "path field in inno_bundle.dlls entry in pubspec.yaml must be a string.";
      }
      if (!path.toLowerCase().endsWith('.dll')) {
        return "path in inno_bundle.dlls in pubspec.yaml must point to a DLL file, "
            "got $path.";
      }
      if (option['name'] != null && option['name'] is! String) {
        return "name field in inno_bundle.dlls entry in pubspec.yaml must be a string or null.";
      }
      if (option['required'] != null && option['required'] is! bool) {
        return "required field in inno_bundle.dlls entry in pubspec.yaml must be a boolean or null.";
      }
      if (option['source'] != null &&
          (option['source'] is! String ||
              !DllSource.literalValues.contains(option['source']))) {
        return "source field in inno_bundle.dlls entry in pubspec.yaml must be "
            "one of ${DllSource.literalValues.join(', ')} or null.";
      }
      return null;
    }

    return "inno_bundle.dlls attribute is invalid in pubspec.yaml.";
  }

  factory DllEntry.fromJson(dynamic json) {
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
    final source = _parseDllSource(json['source'], path);

    return DllEntry(
      path: path,
      name: name,
      required: required,
      source: source,
    );
  }

  static DllSource _parseDllSource(dynamic source, String path) {
    // if source is null, we assume project as a base to the path
    if (source == null) return DllSource.project;
    if (source is String) {
      switch (source.toLowerCase()) {
        case 'project':
          return DllSource.project;
        case 'system32':
          return DllSource.system32;
        default:
          throw ArgumentError('Invalid DllSource: $source');
      }
    }
    throw ArgumentError('Invalid DllSource: $source');
  }

  /// Get dll file absolute path.
  String get absolutePath {
    if (p.isAbsolute(path)) return path;
    if (source == DllSource.project) {
      return p.join(Directory.current.path, path);
    }
    if (source == DllSource.system32) return p.joinAll([...system32, path]);
    // this package is not supposed to arrive to this line, but just in case.
    throw ArgumentError('Invalid DllSource: $source');
  }

  /// Get dll entries for vc redistributable dll files.
  static List<DllEntry> get vcEntries => vcDllFiles
      .map((dllFile) => DllEntry(
            path: dllFile,
            name: p.basename(dllFile),
            required: false,
            source: DllSource.system32,
          ))
      .toList(growable: false);
}
