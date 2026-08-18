/// This file contains the [InstallerBuilder] class, which is responsible for
/// creating the installer for the application using Inno Setup.
///
/// The [InstallerBuilder] class builds the installer based on the provided
/// configuration and script file, using the [Config.innoExec] path for
/// the ISCC executable. It also supports signing the installer if a
/// [SignTool] is configured.
library;

import 'dart:io';

import 'package:inno_bundle/models/config.dart';
import 'package:inno_bundle/utils/cli_logger.dart';

/// A class responsible for building the installer using Inno Setup.
class InstallerBuilder {
  /// The configuration guiding the build process.
  final Config config;

  /// The Inno Setup script file to be used for building the installer.
  final File scriptFile;

  /// Creates an instance of [InstallerBuilder] with the given [config] and [scriptFile].
  const InstallerBuilder(this.config, this.scriptFile);

  /// Builds the installer using Inno Setup and returns the directory containing the output files.
  ///
  /// Skips the build process if [config.installer] is `false`.
  /// Uses [Config.innoExec] to locate ISCC.exe.
  /// Throws a [ProcessException] if the Inno Setup process fails.
  Future<Directory> build() async {
    if (!config.installer) {
      CliLogger.info("Skipping installer...");
      return Directory("");
    }

    final execFile = config.innoExec;
    var params = [scriptFile.path];
    if (config.signTool != null && config.signTool!.command.isNotEmpty) {
      params.add('/S${config.signTool!.name}=${config.signTool!.command}');
    }

    final process = await Process.start(
      execFile.path,
      params,
      runInShell: true,
      workingDirectory: config.baseDir.path,
      mode: ProcessStartMode.inheritStdio,
    );
    final exitCode = await process.exitCode;
    if (exitCode != 0) exit(exitCode);
    return config.baseDir;
  }
}
