import 'dart:io';

import 'package:inno_setup/models/config.dart';
import 'package:inno_setup/utils/cli_logger.dart';
import 'package:inno_setup/utils/constants.dart';
import 'package:path/path.dart' as p;

class InstallerBuilder {
  final Config config;
  final File scriptFile;

  const InstallerBuilder(this.config, this.scriptFile);

  Future<Directory> build() async {
    final exec = p.joinAll([...innoDirPath, "ISCC.exe"]);
    final execFile = File(exec);
    if (!Directory(p.joinAll(innoDirPath)).existsSync()) {
      CliLogger.error("Inno Setup is not installed or detected "
          "in your machine. Download and install it from "
          "`$innoDownloadLink`.");
      exit(1);
    }
    if (!execFile.existsSync()) {
      CliLogger.error("Inno Setup installation in your machine "
          "is corrupted or incomplete. Download and re-install it from "
          "`$innoDownloadLink`.");
      exit(1);
    }
    final process = await Process.start(
      execFile.path,
      [scriptFile.path],
      runInShell: true,
      workingDirectory: Directory.current.path,
      mode: ProcessStartMode.inheritStdio,
    );
    final exitCode = await process.exitCode;
    if (exitCode != 0) exit(exitCode);
    return Directory.current;
  }
}
