import 'dart:io';

import 'package:args/args.dart';
import 'package:inno_bundle/models/app_builder.dart';
import 'package:inno_bundle/models/build_type.dart';
import 'package:inno_bundle/models/config.dart';
import 'package:inno_bundle/models/installer_builder.dart';
import 'package:inno_bundle/models/script_builder.dart';
import 'package:inno_bundle/utils/constants.dart';

Future<Directory> _buildApp(Config config, [skipApp = false]) async {
  final builder = AppBuilder(config, skipApp);
  return await builder.build();
}

Future<File> _buildScript(Config config, Directory appDir) async {
  final builder = ScriptBuilder(config, appDir);
  return await builder.build();
}

Future<void> _buildInstaller(Config config, File scriptFile) async {
  final builder = InstallerBuilder(config, scriptFile);
  await builder.build();
}

/// Run to build installer
void main(List<String> arguments) async {
  print(START_MESSAGE);
  final parser = ArgParser()
    ..addFlag(BuildType.release.name)
    ..addFlag(BuildType.profile.name)
    ..addFlag(BuildType.debug.name)
    ..addFlag('skip-app');
  final parsedArgs = parser.parse(arguments);
  final type = BuildType.fromArgs(parsedArgs);
  final skipApp = parsedArgs['skip-app'] as bool;

  final config = Config.fromFile(type);
  final appBuildDir = await _buildApp(config, skipApp);
  final scriptFile = await _buildScript(config, appBuildDir);
  await _buildInstaller(config, scriptFile);

  print(BUILD_END_MESSAGE);
}
