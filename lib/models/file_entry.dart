import 'package:inno_bundle/models/file_raw_entry.dart';

class FileEntry extends FileRawEntry {
  final String? destinationDir;

  const FileEntry({
    this.destinationDir,
    required super.path,
    required super.name,
    super.required = true,
  });

  static String? validateConfig(dynamic option) {
    return FileRawEntry.validateConfig(
      option,
      propertyName: 'files',
      requiredExtension: null,
    );
  }

  factory FileEntry.fromJson(dynamic json) {
    final e = FileRawEntry.fromJson(json);

    String? destinationDir;
    if (json is Map) {
      destinationDir = json['destination'] as String?;
    }

    return FileEntry(
      path: e.path,
      name: e.name,
      required: e.required,
      destinationDir: destinationDir,
    );
  }
}
