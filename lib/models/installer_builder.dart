import 'dart:io';

import 'package:inno_bundle/models/config.dart';
import 'package:inno_bundle/utils/cli_logger.dart';
import 'package:inno_bundle/utils/constants.dart';
import 'package:path/path.dart' as p;

class InstallerBuilder {
  final Config config;
  final File scriptFile;

  const InstallerBuilder(this.config, this.scriptFile);

  File _getInnoSetupExec() {
    if (!Directory(p.joinAll(innoSysDirPath)).existsSync() &&
        !Directory(p.joinAll(innoUserDirPath)).existsSync()) {
      CliLogger.error("Inno Setup is not installed or detected "
          "in your machine, you either: \n\tDownload and install it from "
          "`$innoDownloadLink`.\n\tUsing winget >>> "
          "`winget install -e --id JRSoftware.InnoSetup`.");
      exit(1);
    }

    final sysExec = p.joinAll([...innoSysDirPath, "ISCC.exe"]);
    final sysExecFile = File(sysExec);
    final userExec = p.joinAll([...innoUserDirPath, "ISCC.exe"]);
    final userExecFile = File(userExec);

    if (sysExecFile.existsSync()) return sysExecFile;
    if (userExecFile.existsSync()) return userExecFile;

    CliLogger.error("Inno Setup installation in your machine "
        "is corrupted or incomplete, you either: \n\tDownload and "
        "re-install it from `$innoDownloadLink`.\n\tUsing winget >>> "
        "`winget install -e --id JRSoftware.InnoSetup`.");
    exit(1);
  }

  Future<Directory> build() async {
    if (!config.installer) {
      CliLogger.info("Skipping installer...");
      return Directory("");
    }

    final execFile = _getInnoSetupExec();

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
