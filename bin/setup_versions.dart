import 'dart:io';

import 'package:args/args.dart';
import 'package:inno_bundle/managers/inno_setup_manager.dart';
import 'package:inno_bundle/utils/cli_logger.dart';
import 'package:inno_bundle/utils/constants.dart';
import 'package:inno_bundle/utils/functions.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> arguments) async {
  if (!Platform.isWindows) {
    CliLogger.exitError('This command is only supported on Windows.');
  }

  final parser = ArgParser()
    ..addOption('versions',
        defaultsTo: '6.3.3',
        help: 'Comma-separated Inno Setup versions to install')
    ..addOption('out-root',
        defaultsTo: p.join(getHomeDir(), '.inno_bundle', 'inno'),
        help: 'Root directory for extracted versions')
    ..addFlag('hf', defaultsTo: true, help: 'Print header and footer')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Print help and exit');

  final parsedArgs = parser.parse(arguments);
  final hf = parsedArgs['hf'] as bool;
  final help = parsedArgs['help'] as bool;

  if (hf) print(START_MESSAGE);

  if (help) {
    print("${parser.usage}\n"
        '\nExamples:'
        '\n  dart run inno_bundle:setup_versions'
        '\n  dart run inno_bundle:setup_versions --versions 6.7.3,6.6.1'
        '\n  dart run inno_bundle:setup_versions --versions 6.7.3 --out-root C:\\tools\\inno\n');
    exit(0);
  }

  final versions = (parsedArgs['versions'] as String)
      .split(',')
      .map((v) => v.trim())
      .where((v) => v.isNotEmpty)
      .toList();
  final outRoot = parsedArgs['out-root'] as String;
  final githubToken =
      Platform.environment['GITHUB_TOKEN'] ?? Platform.environment['GH_TOKEN'];

  final manager = InnoSetupManager(versionsDir: outRoot);

  var allSucceeded = true;

  for (final version in versions) {
    CliLogger.info('Setting up Inno Setup $version...');
    final error = await manager.ensureVersion(
      version,
      githubToken: githubToken,
    );
    if (error != null) {
      allSucceeded = false;
      CliLogger.warning('$version failed: $error');
    } else {
      CliLogger.success('Inno Setup $version ready.');
    }
  }

  if (hf && allSucceeded) {
    print(SETUP_VERSIONS_END_MESSAGE);
  }

  if (!allSucceeded) exit(1);
}
