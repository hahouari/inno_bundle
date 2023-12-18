import 'dart:io';

import 'package:inno_setup/utils/cli_logger.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class Config {
  final String id;
  final String name;
  final String description;
  final String version;
  final String publisher;
  final String url;
  final String supportUrl;
  final String updatesUrl;
  final String exeName;
  final String icon;
  final List<String> languages;
  final bool admin;

  Config({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.publisher,
    required this.url,
    required this.supportUrl,
    required this.updatesUrl,
    required this.exeName,
    required this.icon,
    required this.languages,
    required this.admin,
  });

  factory Config.fromJson(Map<String, dynamic> json) {
    final inno = json['inno_setup'] as Map<String, dynamic>?;
    if (inno is! Map<String, dynamic>) {
      CliLogger.error("inno_setup section is missing from pubspec.yaml.");
      exit(1);
    }

    final id = inno['id'] as String?;
    if (id is! String) {
      CliLogger.error("inno_setup.id attribute is missing from pubspec.yaml. "
          "Run `dart run inno_setup:guid` to generate a new one, "
          "then put it in your pubspec.yaml.");
      exit(1);
    } else if (!Uuid.isValidUUID(fromString: id)) {
      CliLogger.error("inno_setup.id from pubspec.yaml is not valid. "
          "Run `dart run inno_setup:guid` to generate a new one, "
          "then put it in your pubspec.yaml.");
      exit(1);
    }

    var name = inno['name'] ?? json['name'] as String?;
    if (name is! String) {
      CliLogger.error("name attribute is missing from pubspec.yaml.");
      exit(1);
    }

    final version = inno['version'] ?? json['version'] as String?;
    if (version is! String) {
      CliLogger.error("version attribute is missing from pubspec.yaml.");
      exit(1);
    }

    final description = inno['description'] ?? json['description'] as String?;
    if (description is! String) {
      CliLogger.error("description attribute is missing from pubspec.yaml.");
      exit(1);
    }

    final publisher = inno['publisher'] ?? json['maintainer'] as String?;
    if (publisher is! String) {
      CliLogger.error("inno_setup.publisher attribute is missing "
          "from pubspec.yaml.");
      exit(1);
    }

    final url = (inno['url'] ?? json['homepage'] ?? "") as String;
    final supportUrl = (inno['support_url'] as String?) ?? url;
    final updatesUrl = (inno['updates_url'] as String?) ?? url;
    // TODO: revise detecting this one
    final exeName = json['name'] + '.exe';
    var icon = inno['icon'] as String?;
    if (icon is! String) {
      CliLogger.error("inno_setup.icon attribute is missing "
          "from pubspec.yaml.");
      exit(1);
    }
    icon = p.fromUri(icon);

    final languages = json['languages'] ?? ['en'];
    var admin = json['admin'] as dynamic;
    if (admin != null && admin is! bool) {
      CliLogger.error("admin attribute is missing or invalid boolean value "
          "from pubspec.yaml");
      exit(1);
    }
    admin = (admin as bool?) ?? true;

    return Config(
      id: id,
      name: name,
      description: description,
      version: version,
      publisher: publisher,
      url: url,
      supportUrl: supportUrl,
      updatesUrl: updatesUrl,
      exeName: exeName,
      icon: icon,
      languages: languages,
      admin: admin,
    );
  }
}
