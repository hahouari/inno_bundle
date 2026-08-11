import 'dart:io';

import 'package:inno_bundle/models/cli_configs/setup_versions_cli_config.dart';
import 'package:inno_bundle/managers/inno_version_manager.dart';
import 'package:inno_bundle/utils/cli_logger.dart';
import 'package:inno_bundle/utils/constants.dart';
import 'package:inno_bundle/utils/functions.dart';

Future<void> main(List<String> arguments) async {
  assertOsWindows();

  final cliConfig = SetupVersionsCliConfig.parse(arguments);

  if (cliConfig.hf) print(START_MESSAGE);

  if (cliConfig.help) {
    print(cliConfig.helpMessage());
    exit(0);
  }

  final manager = InnoVersionManager();

  var allSucceeded = true;

  for (final version in cliConfig.versions) {
    CliLogger.info('Setting up Inno Setup $version...');
    final error = await manager.ensureVersion(
      version,
      githubToken: gitHubToken,
    );
    if (error != null) {
      allSucceeded = false;
      CliLogger.warning('$version failed: $error');
    } else {
      CliLogger.success('Inno Setup $version ready.');
    }
  }

  if (!allSucceeded) exit(1);

  if (cliConfig.hf) {
    print(SETUP_VERSIONS_END_MESSAGE);
  }
}
