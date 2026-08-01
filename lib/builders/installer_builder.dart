/// This file contains the [InstallerBuilder] class, which is responsible for
/// creating the installer for the application using Inno Setup.
///
/// The [InstallerBuilder] class ensures that the Inno Setup executable is properly
/// installed and accessible on the system, and handles the building of the installer
/// based on the provided configuration and script file. It also supports signing
/// the installer if a [SignTool] is configured.
library;

import 'dart:io';

import 'package:inno_bundle/models/config.dart';
import 'package:inno_bundle/utils/cli_logger.dart';
import 'package:inno_bundle/utils/functions.dart';

/// A class responsible for building the installer using Inno Setup.
class InstallerBuilder {
  /// The configuration guiding the build process.
  final Config config;

  /// The Inno Setup script file to be used for building the installer.
  final File scriptFile;

  /// Optional override for the ISCC.exe path.
  ///
  /// When set, bypasses [getInnoSetupExec] auto-detection. Used by tests
  /// to point at a specific versioned installation.
  final String? isccExecutable;

  /// Creates an instance of [InstallerBuilder] with the given [config] and [scriptFile].
  const InstallerBuilder(this.config, this.scriptFile, {this.isccExecutable});

  /// Builds the installer using Inno Setup and returns the directory containing the output files.
  ///
  /// Skips the build process if [config.installer] is `false`.
  /// Throws a [ProcessException] if the Inno Setup process fails.
  Future<Directory> build() async {
    if (!config.installer) {
      CliLogger.info("Skipping installer...");
      return Directory("");
    }

    final execFile = isccExecutable != null
        ? File(isccExecutable!)
        : getInnoSetupExec()!;
    var params = [scriptFile.path];
    if (config.signTool != null && config.signTool!.command.isNotEmpty) {
      params.add('/S${config.signTool!.name}=${config.signTool!.command}');
    }

    final process = await Process.start(
      execFile.path,
      params,
      runInShell: true,
      workingDirectory: Directory.current.path,
      mode: ProcessStartMode.inheritStdio,
    );
    final exitCode = await process.exitCode;
    if (exitCode != 0) exit(exitCode);
    return Directory.current;
  }
}
