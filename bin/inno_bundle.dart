import 'dart:io';

import 'package:args/args.dart';
import 'package:inno_bundle/builders/app_builder.dart';
import 'package:inno_bundle/builders/installer_builder.dart';
import 'package:inno_bundle/builders/script_builder.dart';
import 'package:inno_bundle/models/build_type.dart';
import 'package:inno_bundle/models/cli_config.dart';
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

/// Run to build installer
void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag(BuildType.release.name, negatable: false, help: 'Default flag')
    ..addFlag(BuildType.profile.name, negatable: false)
    ..addFlag(BuildType.debug.name, negatable: false)
    ..addFlag('app', defaultsTo: true, help: 'Build app')
    ..addFlag('installer', defaultsTo: true, help: 'Build installer')
    ..addFlag(
      'install-inno',
      defaultsTo: true,
      help: 'Install Inno Setup into your system if not already installed\n'
          'This requires Winget to be already available on the system',
    )
    ..addFlag(
      'gen-app-id',
      defaultsTo: true,
      help: 'Generate a random App ID into your config file if non-existent\n'
          'This will use namespace from --app-id-ns if provided',
    )
    ..addOption(
      'path',
      help: 'Path to custom config file. Default: pubspec.yaml',
    )
    ..addOption(
      "app-id-ns",
      help: "Namespace for --gen-app-id\nExample: www.example.com",
    )
    ..addFlag(
      'gen-publisher',
      defaultsTo: true,
      help: 'Generate a publisher name into config file if non-existent\n'
          'This will generate based on username of logged in user in machine\n'
          'and only if maintainer field is not present in config file',
    )
    ..addOption("build-args", help: "Append args to \"flutter build ...\"")
    ..addOption("app-version", help: "Override app version")
    ..addOption("sign-tool-name", help: "Override sign tool name")
    ..addOption("sign-tool-command", help: "Override sign tool command")
    ..addOption("sign-tool-params", help: "Override sign tool params")
    ..addFlag(
      'envs',
      defaultsTo: false,
      negatable: false,
      help: "Print env variables and exit",
    )
    ..addFlag('hf', defaultsTo: true, help: 'Print header and footer')
    ..addFlag('list-languages',
        negatable: false, help: 'List all supported languages and exit')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Print help and exit');
  final parsedArgs = parser.parse(arguments);
  final envs = parsedArgs['envs'] as bool;
  final hf = parsedArgs['hf'] as bool;
  final help = parsedArgs['help'] as bool;
  final listLanguages = parsedArgs['list-languages'] as bool;

  if (hf) print(START_MESSAGE);

  if (help) {
    print("${parser.usage}\n");
    exit(0);
  }

  if (listLanguages) Language.listLanguages();

  const pubspecFilePath = 'pubspec.yaml';
  final pubspecFile = File(pubspecFilePath);
  final defaultConfigFilePath = 'inno_bundle.yaml';
  final defaultConfigFile = File(defaultConfigFilePath);
  final configFilePath = parsedArgs['path'] as String?;
  final cliConfig = CliConfig.fromArgs(parsedArgs);

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

  if (cliConfig.generateAppId || cliConfig.generatePublisher) {
    generateEssentials(pubspecFile, configFile, cliConfig);
  }

  late final Config config;
  try {
    config = Config.fromFile(pubspecFile, configFile, cliConfig);
  } on InnoBundleError catch (e) {
    CliLogger.exitError(e.message);
  }

  if (envs) {
    print(config.toEnvironmentVariables());
    exit(0);
  }

  if (cliConfig.installInnoSetup && cliConfig.installer) {
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

  if (hf) print(BUILD_END_MESSAGE);
}
