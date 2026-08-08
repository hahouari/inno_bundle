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
import 'package:inno_bundle/managers/inno_version_manager.dart';
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
///
/// Uses the ISCC executable path carried on [Config.innoExec].
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

  final pubspecFile = File(pubspecFileName);
  final defaultConfigFile = File(defaultConfigFileName);
  final configFile = Config.resolveConfigFile(
    configPath: cliArgs.path,
    pubspecFile: pubspecFile,
    defaultConfigFile: defaultConfigFile,
  );

  // Resolve which Inno Setup will be used (managed or system/Winget install).
  File? innoExec = InnoVersionManager.resolveInnoExec();

  if (cliArgs.installInnoSetup && cliArgs.installer && innoExec == null) {
    final innoVersionManager = InnoVersionManager();
    final error = await innoVersionManager.ensureDefaultVersion(
      githubToken: gitHubToken,
    );
    if (error != null) CliLogger.exitError(error);
    innoExec = File(innoVersionManager.defaultIsccPath);
  }

  if (innoExec == null) {
    CliLogger.exitError('Inno Setup is not detected in your machine, '
        'use --install-inno or run `dart run inno_bundle:setup_versions` to '
        'install it.');
  }

  Language.loadLanguages(innoExec.path);

  if (cliArgs.generateAppId || cliArgs.generatePublisher) {
    generateEssentials(pubspecFile, configFile, cliArgs);
  }

  late final Config config;
  try {
    config = Config.fromFile(pubspecFile, configFile, innoExec, cliArgs);
  } on InnoBundleError catch (e) {
    CliLogger.exitError(e.message);
  }

  if (cliArgs.listLanguages) Language.listLanguages();

  if (cliArgs.envs) {
    print(config.toEnvironmentVariables());
    exit(0);
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
