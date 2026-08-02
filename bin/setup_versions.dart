import 'dart:io';

import 'package:inno_bundle/cli_args_parsers/setup_versions_cli_args.dart';
import 'package:inno_bundle/managers/inno_setup_manager.dart';
import 'package:inno_bundle/utils/cli_logger.dart';
import 'package:inno_bundle/utils/constants.dart';
import 'package:inno_bundle/utils/functions.dart';

Future<void> main(List<String> arguments) async {
  assertOsWindows();

  final cliArgs = SetupVersionsCliArgs.parse(arguments);

  if (cliArgs.hf) print(START_MESSAGE);

  if (cliArgs.help) {
    print(cliArgs.helpMessage());
    exit(0);
  }

  final manager = InnoSetupManager(versionsDir: cliArgs.outRoot);

  var allSucceeded = true;

  for (final version in cliArgs.versions) {
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

  if (cliArgs.hf) {
    print(SETUP_VERSIONS_END_MESSAGE);
  }
}
