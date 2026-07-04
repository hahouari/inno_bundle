/// A class that represents a file entry for use in Inno Setup.
///
/// The [FileEntry] class encapsulates the path to the file, an optional name,
/// a flag indicating if the file is required, and the source of the file
/// (either the project or the system32 directory).
///
/// Example usage:
/// ```dart
/// var fileEntry = FileEntry(
///   path: "mydll.dll",
///   required: true,
///   source: FileSource.project,
/// );
///
/// print(fileEntry.path); // Outputs: mydll.dll
/// print(fileEntry.name); // Outputs: mydll.dll
/// print(fileEntry.required); // Outputs: true
/// print(fileEntry.source); // Outputs: FileSource.project
/// ```
///
/// Properties:
/// - [path]: The path to the file.
/// - [name]: The name for the file. Defaults to the basename of the path.
/// - [required]: A flag indicating if the file is required. Defaults to true.
/// - [source]: An enum indicating the source of the file. Defaults to FileSource.project.
/// - [destination]: The destination directory for the file.
library;

import 'dart:io';

import 'package:inno_bundle/utils/constants.dart';
import 'package:path/path.dart' as p;

/// Enum representing the source of the extra files to be included with the app bundle.
enum FileSource {
  /// The files is located in the project directory.
  project,

  /// The files is located in the system32 directory.
  system32;

  /// Return string array of literal values.
  static List<String> get literalValues => values.map((e) => e.name).toList();
}

class FileEntry {
  /// The path to the file.
  final String path;

  /// The name for the file. Defaults to the basename of the path.
  final String name;

  /// A flag indicating if the file is required. Defaults to true.
  final bool required;

  /// An enum indicating the source of the file. Defaults to FileSource.project.
  final FileSource source;

  /// Destination directory for the file.
  final String? destination;

  /// Create a [FileEntry] instance with the given properties.
  const FileEntry({
    required this.path,
    required this.name,
    this.required = true,
    this.source = FileSource.project,
    this.destination,
  });

  /// Validate configuration option for [FileEntry].
  static String? validateConfig(dynamic option, {required String configName}) {
    if (option == null) return null;
    if (option is String) {
      return null;
    }
    if (option is Map<String, dynamic>) {
      if (option['path'] == null) {
        return "path field is missing from inno_bundle.files entry in $configName, "
            "it must be a string.";
      }
      final path = option['path'];
      if (path is! String) {
        return "path field in inno_bundle.files entry in $configName must be a string.";
      }
      if (option['name'] != null && option['name'] is! String) {
        return "name field in inno_bundle.files entry in $configName must be a string or null.";
      }
      if (option['required'] != null && option['required'] is! bool) {
        return "required field in inno_bundle.files entry in $configName must be a boolean or null.";
      }
      if (option['source'] != null &&
          (option['source'] is! String ||
              !FileSource.literalValues.contains(option['source']))) {
        return "source field in inno_bundle.files entry in $configName must be "
            "one of ${FileSource.literalValues.join(', ')} or null.";
      }
      return null;
    }

    return "inno_bundle.files attribute is invalid in $configName.";
  }

  /// Parse [FileSource] from string or null, default to [FileSource.project]
  static FileSource _parseSource(dynamic source, String path) {
    // if source is null, we assume project as a base to the path
    if (source == null) return FileSource.project;
    if (source is! String) throw ArgumentError('Invalid FileSource: $source');
    switch (source.toLowerCase()) {
      case 'project':
        return FileSource.project;
      case 'system32':
        return FileSource.system32;
      default:
        throw ArgumentError('Invalid FileSource: $source');
    }
  }

  /// Creates a [FileEntry] instance from a JSON map (or String)
  factory FileEntry.fromJson(dynamic json) {
    assert(json != null);
    if (json is String) {
      return FileEntry(
        path: json,
        name: p.basename(json),
        required: true,
        source: FileSource.project,
        destination: null,
      );
    }
    final path = json['path'] as String;
    final name = json['name'] as String? ?? p.basename(path);
    final required = json['required'] as bool? ?? true;
    final source = _parseSource(json['source'], path);
    final destination = json['destination'] as String?;
    return FileEntry(
      path: path,
      name: name,
      required: required,
      source: source,
      destination: destination,
    );
  }

  /// Get file absolute path.
  String get absolutePath {
    if (p.isAbsolute(path)) return path;
    if (source == FileSource.project) {
      return p.join(Directory.current.path, path);
    }
    if (source == FileSource.system32) return p.joinAll([...system32, path]);
    // this package is not supposed to arrive to this line, but just in case.
    throw ArgumentError('Invalid FileSource: $source');
  }

  /// Get dll files entries for vc redistributable DLLs.
  static List<FileEntry> get vcEntries => vcDllFiles
      .map((file) => FileEntry(
            path: file,
            name: p.basename(file),
            required: false,
            source: FileSource.system32,
          ))
      .toList(growable: false);
}
