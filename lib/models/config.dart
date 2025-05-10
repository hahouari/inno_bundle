/// This file contains the [Config] class, which represents the configuration
/// for building a Windows installer using Inno Setup.
///
/// The [Config] class holds various attributes necessary for the build process,
/// including application-specific details such as ID, name, description, and version.
/// It also includes build-related settings like the installer icon, languages,
/// administrator mode, and whether to include the app or create an installer file.
///
/// This file provides methods to create a [Config] instance from JSON or directly
/// from the `pubspec.yaml` file, as well as a method to convert the configuration
/// attributes into environment variables for further use.
library;

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'package:inno_bundle/models/admin_mode.dart';
import 'package:inno_bundle/models/build_arch.dart';
import 'package:inno_bundle/models/build_type.dart';
import 'package:inno_bundle/models/cli_config.dart';
import 'package:inno_bundle/models/dll_entry.dart';
import 'package:inno_bundle/models/file_entry.dart';
import 'package:inno_bundle/models/language.dart';
import 'package:inno_bundle/models/sign_tool.dart';
import 'package:inno_bundle/models/vcredist_mode.dart';
import 'package:inno_bundle/utils/cli_logger.dart';
import 'package:inno_bundle/utils/constants.dart';
import 'package:inno_bundle/utils/functions.dart';

/// A class representing the configuration for building a Windows installer using Inno Setup.
class Config {
  /// The unique identifier (UUID) for the app being packaged.
  final String id;

  /// The pubspec file sourced for this configuration.
  final File pubspecFile;

  /// The global pubspec name attribute, same name of the exe generated from flutter build.
  final String pubspecName;

  /// The name of the app after packaging.
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

  /// The path to the text license file.
  final String licenseFile;

  /// The name or commmand to be used to digitally sign the installer.
  final SignTool? signTool;

  /// The supported languages for the installer.
  final List<Language> languages;

  /// Whether the installer requires administrator privileges.
  final AdminMode admin;

  /// The build type (debug or release).
  final BuildType type;

  /// Whether to include the app in the installer.
  final bool app;

  /// Whether to create an installer file.
  final bool installer;

  /// CPU Architecture supported by the app and installer to run on.
  final BuildArch arch;

  /// Arguments to be passed to flutter build.
  final String? buildArgs;

  /// The mode for handling the Visual C++ Redistributable.
  final VcRedistMode vcRedist;

  /// List of dlls to be included in the installer.
  final List<DllEntry> dlls;
  
  /// List of files to be included in the installer.
  final List<FileEntry> files;

  /// Creates a [Config] instance with default values.
  const Config({
    required this.pubspecFile,
    required this.dlls,
    required this.files,
    required this.buildArgs,
    required this.id,
    required this.pubspecName,
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
    required this.licenseFile,
    required this.signTool,
    required this.arch,
    required this.vcRedist,
    this.type = BuildType.debug,
    this.app = true,
    this.installer = true,
  });

  /// The name of the executable file that is created with flutter build.
  String get exePubspecName => "$pubspecName.exe";

  /// The name of the executable file that will be created.
  String get exeName => "$name.exe";

  /// Creates a [Config] instance from a JSON map, typically read from `pubspec.yaml`.
  ///
  /// Validates the configuration and exits with an error if invalid values are found.
  factory Config.fromJson(
    Map<String, dynamic> json, {
    required CliConfig cliConfig,
    required File pubspecFile,
  }) {
    if (json['inno_bundle'] is! Map<String, dynamic>) {
      CliLogger.exitError("inno_bundle section is missing from pubspec.yaml.");
    }
    final Map<String, dynamic> inno = json['inno_bundle'];

    if (inno['id'] is! String) {
      CliLogger.exitError(
          "inno_bundle.id attribute is missing from pubspec.yaml. "
          "Run `dart run inno_bundle:guid` to generate a new one, "
          "then put it in your pubspec.yaml.");
    } else if (!Uuid.isValidUUID(fromString: inno['id'])) {
      CliLogger.exitError("inno_bundle.id from pubspec.yaml is not valid. "
          "Run `dart run inno_bundle:guid` to generate a new one, "
          "then put it in your pubspec.yaml.");
    }
    final String id = inno['id'];

    if (json['name'] is! String) {
      CliLogger.exitError("name attribute is missing from pubspec.yaml.");
    }
    final String pubspecName = json['name'];

    if (inno['name'] != null && !validFilenameRegex.hasMatch(inno['name'])) {
      CliLogger.exitError("inno_bundle.name from pubspec.yaml is not valid. "
          "`${inno['name']}` is not a valid file name.");
    }
    final String name = inno['name'] ?? pubspecName;

    if ((cliConfig.appVersion ?? inno['version'] ?? json['version'])
        is! String) {
      CliLogger.exitError("version attribute is missing from pubspec.yaml.");
    }
    final String version =
        cliConfig.appVersion ?? inno['version'] ?? json['version'];

    if ((inno['description'] ?? json['description']) is! String) {
      CliLogger.exitError(
          "description attribute is missing from pubspec.yaml.");
    }
    final String description = inno['description'] ?? json['description'];

    if ((inno['publisher'] ?? json['maintainer']) is! String) {
      CliLogger.exitError("maintainer or inno_bundle.publisher attributes are "
          "missing from pubspec.yaml.");
    }
    final String publisher = inno['publisher'] ?? json['maintainer'];

    final url = (inno['url'] ?? json['homepage'] ?? "") as String;
    final supportUrl = (inno['support_url'] as String?) ?? url;
    final updatesUrl = (inno['updates_url'] as String?) ?? url;

    if (inno['installer_icon'] != null && inno['installer_icon'] is! String) {
      CliLogger.exitError("inno_bundle.installer_icon attribute is invalid "
          "in pubspec.yaml.");
    }
    final installerIcon = inno['installer_icon'] != null
        ? p.join(
            Directory.current.path,
            p.fromUri(inno['installer_icon']),
          )
        : defaultInstallerIconPlaceholder;
    if (installerIcon != defaultInstallerIconPlaceholder &&
        !File(installerIcon).existsSync()) {
      CliLogger.exitError(
          "inno_bundle.installer_icon attribute value is invalid, "
          "`$installerIcon` file does not exist.");
    }

    if (inno['languages'] != null && inno['languages'] is! List) {
      CliLogger.exitError("inno_bundle.languages attribute is invalid "
          "in pubspec.yaml, only a list of strings is allowed.");
    }
    final languages = (inno['languages'] as List?)
            ?.map((l) {
              final languageError = Language.validateConfig(l);
              if (languageError != null) CliLogger.exitError(languageError);
              final language = Language.getByNameOrNull(l);
              if (language == null) return null;
              return language;
            })
            .whereType<Language>()
            .toList(growable: false) ??
        Language.values;

    if (inno['admin'] != null &&
        inno['admin'] is! bool &&
        inno['admin'] != "auto") {
      CliLogger.exitError("inno_bundle.admin attribute is invalid value "
          "in pubspec.yaml");
    }
    final admin = AdminMode.fromOption(inno['admin'] ?? true);

    if (inno['license_file'] != null && inno['license_file'] is! String) {
      CliLogger.exitError("inno_bundle.license_file attribute is invalid "
          "in pubspec.yaml.");
    }

    final licenseFilePath = p.join(
      Directory.current.path,
      inno['license_file'] != null
          ? p.fromUri(inno['license_file'])
          : 'LICENSE',
    );
    final licenseFile =
        File(licenseFilePath).existsSync() ? licenseFilePath : '';

    final signToolError = SignTool.validateConfig(
      inno["sign_tool"],
      signToolName: cliConfig.signToolName,
      signToolCommand: cliConfig.signToolCommand,
      signToolParams: cliConfig.signToolParams,
    );
    if (signToolError != null) CliLogger.exitError(signToolError);
    final signTool = SignTool.fromOption(
      inno['sign_tool'],
      signToolName: cliConfig.signToolName,
      signToolCommand: cliConfig.signToolCommand,
      signToolParams: cliConfig.signToolParams,
    );

    final archError = BuildArch.validateConfig(inno['arch']);
    if (archError != null) CliLogger.exitError(archError);
    final arch = BuildArch.fromOption(inno['arch']);

    if (inno['vc_redist'] != null &&
        inno['vc_redist'] is! bool &&
        inno['vc_redist'] != "download") {
      CliLogger.exitError("inno_bundle.vc_redist attribute is invalid value "
          "in pubspec.yaml");
    }
    final vcRedist = VcRedistMode.fromOption(inno['vc_redist'] ?? true);

    if (inno['dlls'] != null && inno['dlls'] is! List) {
      CliLogger.exitError("inno_bundle.dlls attribute is invalid "
          "in pubspec.yaml, only a list of dll entries is allowed.");
    }
    final dlls = ((inno['dlls'] ?? []) as List)
        .map((d) {
          if (d == null) return null;

          final dllError = DllEntry.validateConfig(d);
          if (dllError != null) CliLogger.exitError(dllError);

          return DllEntry.fromJson(d);
        })
        .whereType<DllEntry>()
        .toList(growable: false);

    final files = ((inno['files'] ?? []) as List)
        .map((d) {
          if (d == null) return null;

          final dllError = FileEntry.validateConfig(d);
          if (dllError != null) CliLogger.exitError(dllError);

          return FileEntry.fromJson(d);
        })
        .whereType<FileEntry>()
        .toList(growable: false);

    return Config(
      pubspecFile: pubspecFile,
      buildArgs: cliConfig.buildArgs,
      id: id,
      pubspecName: pubspecName,
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
      type: cliConfig.type,
      app: cliConfig.app,
      installer: cliConfig.installer,
      licenseFile: licenseFile,
      signTool: signTool,
      arch: arch,
      vcRedist: vcRedist,
      dlls: dlls,
      files: files,
    );
  }

  /// Creates a [Config] instance directly from the `pubspec.yaml` file.
  ///
  /// Provides a convenient way to load configuration without manual JSON parsing.
  factory Config.fromFile(File pubspecFile, CliConfig cliConfig) {
    final json = readPubspec(pubspecFile);

    return Config.fromJson(
      json,
      cliConfig: cliConfig,
      pubspecFile: pubspecFile,
    );
  }

  /// Returns a string containing the config attributes as environment variables.
  String toEnvironmentVariables() {
    final variables = <String, String>{
      'APP_ID': id,
      'PUBSPEC_NAME': pubspecName,
      'APP_NAME': name,
      'APP_NAME_CAMEL_CASE': camelCase(name),
      'APP_DESCRIPTION': description,
      'APP_VERSION': version,
      'APP_PUBLISHER': publisher,
      'APP_URL': url,
      'APP_SUPPORT_URL': supportUrl,
      'APP_UPDATES_URL': updatesUrl,
      'APP_INSTALLER_ICON': installerIcon,
      'APP_LANGUAGES': languages.map((l) => l.name).join(','),
      'APP_ADMIN': admin.toString(),
      'APP_VCREDIST': vcRedist.toString(),
      'APP_TYPE': type.name,
      'APP_BUILD_APP': app.toString(),
      'APP_BUILD_INSTALLER': installer.toString(),
    };

    return variables.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('\n');
  }
}
