import 'dart:io';

import 'package:args/args.dart';
import 'package:inno_bundle/builders/app_builder.dart';
import 'package:inno_bundle/builders/installer_builder.dart';
import 'package:inno_bundle/builders/script_builder.dart';
import 'package:inno_bundle/models/build_type.dart';
import 'package:inno_bundle/models/cli_config.dart';
import 'package:inno_bundle/models/config.dart';
import 'package:inno_bundle/utils/constants.dart';
import 'package:inno_bundle/utils/functions.dart';

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
    ..addFlag(BuildType.release.name, negatable: false)
    ..addFlag(BuildType.profile.name, negatable: false)
    ..addFlag(BuildType.debug.name, negatable: false, help: 'Default flag')
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
      help: 'Generate a random App ID into pubspec.yaml if non-existent\n'
          'This will use namespace from --app-id-ns if provided',
    )
    ..addOption(
      "app-id-ns",
      help: "Namespace for --gen-app-id\nExample: www.example.com",
    )
    ..addFlag(
      'gen-publisher',
      defaultsTo: true,
      help: 'Generate a publisher name into pubspec.yaml if non-existent\n'
          'This will generate based on username of logged in user in machine\n'
          'and only if maintainer field is not present in pubspec.yaml',
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
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Print help and exit');
  final parsedArgs = parser.parse(arguments);
  final envs = parsedArgs['envs'] as bool;
  final hf = parsedArgs['hf'] as bool;
  final help = parsedArgs['help'] as bool;

  if (hf) print(START_MESSAGE);

  if (help) {
    print("${parser.usage}\n");
    exit(0);
  }

  const filePath = 'pubspec.yaml';
  final pubspecFile = File(filePath);
  final cliConfig = CliConfig.fromArgs(parsedArgs);

  if (cliConfig.generateAppId || cliConfig.generatePublisher) {
    generateEssentials(pubspecFile, cliConfig);
  }

  final config = Config.fromFile(pubspecFile, cliConfig);

  if (envs) {
    print(config.toEnvironmentVariables());
    exit(0);
  }

  if (cliConfig.installInnoSetup && cliConfig.installer) {
    await installInnoSetup();
  }

  final appBuildDir = await _buildApp(config);
  final scriptFile = await _buildScript(config, appBuildDir);
  await _buildInstaller(config, scriptFile);

  if (hf) print(BUILD_END_MESSAGE);
}
