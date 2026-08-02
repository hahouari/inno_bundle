/// The `inno_bundle` command-line entry point.
///
/// Its role is to turn user-facing command-line flags plus a config file into
/// a finished Windows installer, chaining the app, script and installer
/// builders described in the `builders/` package.
import 'dart:io';

import 'package:inno_bundle/builders/app_builder.dart';
import 'package:inno_bundle/builders/installer_builder.dart';
import 'package:inno_bundle/builders/script_builder.dart';
import 'package:inno_bundle/cli_args_parsers/inno_bundle_cli_args.dart';
import 'package:inno_bundle/models/config.dart';
import 'package:inno_bundle/models/language.dart';
import 'package:inno_bundle/utils/cli_logger.dart';
import 'package:inno_bundle/utils/constants.dart';
import 'package:inno_bundle/utils/functions.dart';
import 'package:inno_bundle/utils/inno_bundle_error.dart';

/// Builds the application using the provided configuration.
///
/// Returns the directory containing the built application files.
Future<Directory> _buildApp(Config config) async {
  final builder = AppBuilder(config);
  return await builder.build();
}

/// Generates the Inno Setup script file for the installer.
///
/// Returns the generated Inno Setup script file.
Future<File> _buildScript(Config config, Directory appDir) async {
  final builder = ScriptBuilder(config, appDir);
  return await builder.build();
}

/// Builds the installer using the provided configuration and Inno Setup script file.
Future<void> _buildInstaller(Config config, File scriptFile) async {
  final builder = InstallerBuilder(config, scriptFile);
  await builder.build();
}

/// Entry point of the `inno_bundle` command.
///
/// Walks the whole build pipeline from the parsed arguments: resolve the
/// config, generate missing essentials, ensure Inno Setup is installed, then
/// produce the app and its installer. Every step is gated by the flags modeled
/// in [InnoBundleCliArgs].
void main(List<String> arguments) async {
  final cliArgs = InnoBundleCliArgs.parse(arguments);

  if (cliArgs.hf) print(START_MESSAGE);

  if (cliArgs.help) {
    print(cliArgs.helpMessage());
    exit(0);
  }

  if (cliArgs.listLanguages) Language.listLanguages();

  const pubspecFilePath = 'pubspec.yaml';
  final pubspecFile = File(pubspecFilePath);
  final defaultConfigFilePath = 'inno_bundle.yaml';
  final defaultConfigFile = File(defaultConfigFilePath);
  final configFilePath = cliArgs.path;

  // if config file points to pubspec file, use same File instance,
  // the intention is to first look up custom config file,
  // if not provided, look up default config file `inno_bundle.yaml`,
  // else, then look up pubspec file.
  final configFile = configFilePath == pubspecFilePath
      ? pubspecFile
      : configFilePath != null
          ? File(configFilePath)
          : defaultConfigFile.existsSync()
              ? defaultConfigFile
              : pubspecFile;

  if (cliArgs.generateAppId || cliArgs.generatePublisher) {
    generateEssentials(pubspecFile, configFile, cliArgs);
  }

  late final Config config;
  try {
    config = Config.fromFile(pubspecFile, configFile, cliArgs);
  } on InnoBundleError catch (e) {
    CliLogger.exitError(e.message);
  }

  if (cliArgs.envs) {
    print(config.toEnvironmentVariables());
    exit(0);
  }

  if (cliArgs.installInnoSetup && cliArgs.installer) {
    await installInnoSetup();
  }

  try {
    final appBuildDir = await _buildApp(config);
    final scriptFile = await _buildScript(config, appBuildDir);
    await _buildInstaller(config, scriptFile);
  } on InnoBundleError catch (e) {
    CliLogger.exitError(e.message);
  }
  CliLogger.flushDeferred();

  if (cliArgs.hf) print(BUILD_END_MESSAGE);
}
