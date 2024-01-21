import 'dart:io';
import 'package:inno_bundle/models/build_type.dart';
import 'package:inno_bundle/models/language.dart';
import 'package:inno_bundle/utils/cli_logger.dart';
import 'package:inno_bundle/utils/constants.dart';
import 'package:inno_bundle/utils/functions.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:yaml/yaml.dart';

/// A class representing the configuration for building a Windows installer using Inno Setup.
class Config {
  /// The unique identifier (UUID) for the app being packaged.
  final String id;

  /// The name of the app being packaged.
  final String name;

  /// A description of the app being packaged.
  final String description;

  /// The app's version.
  final String version;

  /// The name of the publisher or maintainer.
  final String publisher;

  /// The app's homepage URL.
  final String url;

  /// The URL for support resources.
  final String supportUrl;

  /// The URL for checking for updates.
  final String updatesUrl;

  /// The path to the installer icon file.
  final String installerIcon;

  /// The supported languages for the installer.
  final List<Language> languages;

  /// Whether the installer requires administrator privileges.
  final bool admin;

  /// The build type (debug or release).
  final BuildType type;

  /// Whether to include the app in the installer.
  final bool app;

  /// Whether to create an installer file.
  final bool installer;

  /// Creates a [Config] instance with default values.
  const Config({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.publisher,
    required this.url,
    required this.supportUrl,
    required this.updatesUrl,
    required this.installerIcon,
    required this.languages,
    required this.admin,
    this.type = BuildType.debug,
    this.app = true,
    this.installer = true,
  });

  /// The name of the executable file that will be created.
  String get exeName => "$name.exe";

  /// Creates a [Config] instance from a JSON map, typically read from `pubspec.yaml`.
  ///
  /// Validates the configuration and exits with an error if invalid values are found.
  factory Config.fromJson(
    Map<String, dynamic> json, {
    BuildType type = BuildType.debug,
    bool app = true,
    bool installer = true,
  }) {
    if (json['inno_bundle'] is! Map<String, dynamic>) {
      CliLogger.error("inno_bundle section is missing from pubspec.yaml.");
      exit(1);
    }
    final Map<String, dynamic> inno = json['inno_bundle'];

    if (inno['id'] is! String) {
      CliLogger.error("inno_bundle.id attribute is missing from pubspec.yaml. "
          "Run `dart run inno_bundle:guid` to generate a new one, "
          "then put it in your pubspec.yaml.");
      exit(1);
    } else if (!Uuid.isValidUUID(fromString: inno['id'])) {
      CliLogger.error("inno_bundle.id from pubspec.yaml is not valid. "
          "Run `dart run inno_bundle:guid` to generate a new one, "
          "then put it in your pubspec.yaml.");
      exit(1);
    }
    final String id = inno['id'];

    if ((inno['name'] ?? json['name']) is! String) {
      CliLogger.error("name attribute is missing from pubspec.yaml.");
      exit(1);
    }
    final String name = inno['name'] ?? json['name'];

    if ((inno['version'] ?? json['version']) is! String) {
      CliLogger.error("version attribute is missing from pubspec.yaml.");
      exit(1);
    }
    final String version = inno['version'] ?? json['version'];

    if ((inno['description'] ?? json['description']) is! String) {
      CliLogger.error("description attribute is missing from pubspec.yaml.");
      exit(1);
    }
    final String description = inno['description'] ?? json['description'];

    if ((inno['publisher'] ?? json['maintainer']) is! String) {
      CliLogger.error("maintainer or inno_bundle.publisher attributes are "
          "missing from pubspec.yaml.");
      exit(1);
    }
    final String publisher = inno['publisher'] ?? json['maintainer'];

    final url = (inno['url'] ?? json['homepage'] ?? "") as String;
    final supportUrl = (inno['support_url'] as String?) ?? url;
    final updatesUrl = (inno['updates_url'] as String?) ?? url;

    if (inno['installer_icon'] != null && inno['installer_icon'] is! String) {
      CliLogger.error("inno_bundle.installer_icon attribute is invalid "
          "in pubspec.yaml.");
      exit(1);
    }
    final installerIcon = inno['installer_icon'] != null
        ? p.join(
            Directory.current.path,
            p.fromUri(inno['installer_icon']),
          )
        : defaultInstallerIconPlaceholder;
    if (installerIcon != defaultInstallerIconPlaceholder &&
        !File(installerIcon).existsSync()) {
      CliLogger.error("inno_bundle.installer_icon attribute value is invalid, "
          "`$installerIcon` file does not exist.");
      exit(1);
    }

    if (inno['languages'] != null && inno['languages'] is! List<String>) {
      CliLogger.error("inno_bundle.languages attribute is invalid "
          "in pubspec.yaml, only a list of strings is allowed.");
      exit(1);
    }
    final languages = (inno['languages'] as List<String>?)?.map((l) {
          final language = Language.getByNameOrNull(l);
          if (language == null) {
            CliLogger.error("error in inno_bundle.languages attribute "
                "in pubspec.yaml, language `$l` is not supported.");
            exit(1);
          }
          return language;
        }).toList(growable: false) ??
        Language.values;

    if (json['admin'] != null && json['admin'] is! bool) {
      CliLogger.error("admin attribute is invalid boolean value "
          "in pubspec.yaml");
      exit(1);
    }
    final bool admin = json['admin'] ?? true;

    return Config(
      id: id,
      name: name,
      description: description,
      version: version,
      publisher: publisher,
      url: url,
      supportUrl: supportUrl,
      updatesUrl: updatesUrl,
      installerIcon: installerIcon,
      languages: languages,
      admin: admin,
      type: type,
      app: app,
      installer: installer,
    );
  }

  /// Creates a [Config] instance directly from the `pubspec.yaml` file.
  ///
  /// Provides a convenient way to load configuration without manual JSON parsing.
  factory Config.fromFile({
    BuildType type = BuildType.debug,
    bool app = true,
    bool installer = true,
  }) {
    const filePath = 'pubspec.yaml';
    final yamlMap = loadYaml(File(filePath).readAsStringSync()) as Map;
    // yamlMap has the type YamlMap, which has several unwanted side effects
    final yamlConfig = yamlToMap(yamlMap as YamlMap);
    return Config.fromJson(
      yamlConfig,
      type: type,
      app: app,
      installer: installer,
    );
  }
}
