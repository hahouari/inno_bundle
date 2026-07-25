import 'dart:io';

import 'package:args/args.dart';
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
        '\n  dart run inno_bundle:setup_versions --versions 6.2.2,6.3.3'
        '\n  dart run inno_bundle:setup_versions --versions 6.3.3 --out-root C:\\tools\\inno\n');
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

  var allSucceeded = true;

  for (final version in versions) {
    final success = await _setupVersion(
      version,
      outRoot,
      githubToken: githubToken,
    );
    if (!success) {
      allSucceeded = false;
      CliLogger.warning('$version failed to set up.');
    }
  }

  if (hf && allSucceeded) {
    print(SETUP_VERSIONS_END_MESSAGE);
  }

  if (!allSucceeded) exit(1);
}

Future<bool> _setupVersion(
  String version,
  String outRoot, {
  String? githubToken,
}) async {
  final dest = p.join(outRoot, version);
  final isccPath = p.join(dest, 'ISCC.exe');

  if (File(isccPath).existsSync()) {
    CliLogger.info('Inno Setup $version already present at $dest, skipping.');
    return true;
  }

  final versionTag = version.replaceAll('.', '_');
  final apiUrl =
      'https://api.github.com/repos/jrsoftware/issrc/releases/tags/is-$versionTag';

  CliLogger.info('Fetching release info for Inno Setup $version...');

  final releaseData = await fetchGitHubJson(apiUrl, githubToken: githubToken);
  if (releaseData == null) {
    CliLogger.error('Failed to fetch release info for version $version — '
        'check that the version exists.');
    if (githubToken == null) {
      CliLogger.info(
          'Tip: Set GITHUB_TOKEN (or GH_TOKEN) env var to avoid GitHub API rate limits.',
          level: CliLoggerLevel.two);
    }
    return false;
  }

  final assetName = 'innosetup-$version.exe';
  final assets = releaseData['assets'] as List<dynamic>?;
  Map<String, dynamic>? asset;
  if (assets != null) {
    for (final a in assets) {
      if (a is Map<String, dynamic> && a['name'] == assetName) {
        asset = a;
        break;
      }
    }
  }

  if (asset == null) {
    CliLogger.error('Asset $assetName not found for version $version.');
    return false;
  }

  final downloadUrl = asset['browser_download_url'] as String;
  final digest = asset['digest'] as String;
  final expectedHash =
      digest.startsWith('sha256:') ? digest.substring(7) : digest;

  final tempDir = Directory.systemTemp;
  final installerPath = p.join(tempDir.path, assetName);

  var installerFileCached = false;
  if (File(installerPath).existsSync()) {
    CliLogger.info(
        'Found cached installer for $version, verifying checksum...');
    final cachedHash = await sha256HashFile(installerPath);
    if (cachedHash != null &&
        cachedHash.toLowerCase() == expectedHash.toLowerCase()) {
      CliLogger.success(
          'Cached installer checksum verified, skipping download.');
      installerFileCached = true;
    } else {
      CliLogger.info(
          'Cached installer missing or checksum mismatch, re-downloading...');
    }
  }

  if (!installerFileCached) {
    CliLogger.info('Downloading Inno Setup $version...');
    try {
      await downloadFile(downloadUrl, installerPath);
    } catch (e) {
      CliLogger.error('Failed to download $version: $e');
      return false;
    }

    CliLogger.info('Verifying SHA256 checksum...');
    final actualHash = await sha256HashFile(installerPath);
    if (actualHash == null ||
        actualHash.toLowerCase() != expectedHash.toLowerCase()) {
      CliLogger.error('Checksum mismatch for $version.\n'
          '  Expected: $expectedHash\n'
          '  Actual:   $actualHash');
      File(installerPath).deleteSync();
      return false;
    }
    CliLogger.success('Checksum verified.');
  }

  CliLogger.info('Extracting to $dest...');
  Directory(dest).createSync(recursive: true);

  final result = await Process.run(
      installerPath,
      [
        '/VERYSILENT',
        '/SUPPRESSMSGBOXES',
        '/NORESTART',
        '/CURRENTUSER',
        '/DIR=$dest',
      ],
      runInShell: true);

  File(installerPath).deleteSync();

  if (result.exitCode != 0) {
    CliLogger.error(
        'Installer for $version exited with code ${result.exitCode}.');
    return false;
  }

  if (!File(isccPath).existsSync()) {
    CliLogger.error('ISCC.exe not found after extracting $version.');
    return false;
  }

  CliLogger.success('Inno Setup $version ready at $dest');
  return true;
}
