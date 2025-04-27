import 'dart:core';

class DirEntry {
  final String name;
  final String permission;

  DirEntry({required this.name, required this.permission});

  static String? validateConfig(dynamic option) {
    if (option == null) return null;
    if (option is Map<String, dynamic>) {
      if (option['name'] != null && option['name'] is! String) {
        return "name field in inno_bundle.dirs entry in pubspec.yaml must be a string or null.";
      }
      if (option['permission'] != null && option['permission'] is! String) {
        return "permission field in inno_bundle.dirs entry in pubspec.yaml must be a string or null.";
      }
      return null;
    }

    return "inno_bundle.dirs attribute is invalid in pubspec.yaml.";
  }

  factory DirEntry.fromJson(dynamic json) {
    assert(json != null);

    final permission = json['permission'] as String;
    final name = json['name'] as String;

    return DirEntry(
      name: name,
      permission: permission,
    );
  }
}
