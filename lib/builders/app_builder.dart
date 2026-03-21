/// This file contains the [AppBuilder] class, which is responsible for
/// orchestrating the build process of the app using a provided configuration.
///
/// The [AppBuilder] class uses the [Config] model to determine the build
/// parameters and executes the Flutter build command accordingly. It also
/// manages conditions such as skipping the build if a valid build already
/// exists.
library;

import 'dart:io';

import 'package:inno_bundle/models/config.dart';
import 'package:inno_bundle/utils/constants.dart';
import 'package:path/path.dart' as p;
import 'package:inno_bundle/utils/cli_logger.dart';

/// A class responsible for building the app based on the provided configuration.
class AppBuilder {
  /// Configuration guiding the build process.
  final Config config;

  /// Creates an instance of [AppBuilder] with the given [config].
  AppBuilder(this.config);

  /// Builds the app using Flutter and returns the path to the build directory.
  ///
  /// If [config.app] is `false` and a valid build already exists, it skips the
  /// build process and returns the existing directory. Otherwise, it executes
  /// the Flutter build command and returns the newly generated build directory.
  Future<Directory> build() async {
    final buildDirPath = p.joinAll([
      Directory.current.path,
      ...appBuildDir,
      config.type.dirName,
    ]);
    final buildDir = Directory(buildDirPath);
    final versionParts = config.version.split("+");
    final buildName = versionParts[0];
    final buildNumber =
        versionParts.length == 1 ? "1" : versionParts.sublist(1).join("+");

    if (!config.app) {
      if (!buildDir.existsSync() || buildDir.listSync().isEmpty) {
        CliLogger.warning(
          "${config.type.dirName} build is not available, "
          "--no-app is ignored.",
        );
      } else {
        CliLogger.info("Skipping app...");
        return buildDir;
      }
    }

    final process = await Process.start(
      "flutter",
      [
        'build',
        'windows',
        './lib/main.dart',
        '--${config.type.name}',
        '--obfuscate',
        '--split-debug-info=build/obfuscate',
        '--build-name',
        buildName,
        '--build-number',
        buildNumber,
        config.buildArgs ?? "",
      ],
      runInShell: true,
      workingDirectory: Directory.current.path,
      mode: ProcessStartMode.inheritStdio,
    );

    final exitCode = await process.exitCode;

    if (exitCode != 0) exit(exitCode);
    return buildDir;
  }
}
