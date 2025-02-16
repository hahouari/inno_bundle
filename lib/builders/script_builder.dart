/// This file contains the [ScriptBuilder] class, which is responsible for generating
/// the Inno Setup Script (ISS) file for creating the installer of an application.
///
/// The [ScriptBuilder] class takes a [Config] object and an [appDir] directory as inputs
/// and generates the ISS script based on the provided configuration. This script defines
/// various sections like setup, files, icons, tasks, and languages, among others.
///
/// Key methods:
/// - [_setup]: Generates the `[Setup]` section of the ISS script.
/// - [_installDelete]: Generates the `[InstallDelete]` section.
/// - [_languages]: Generates the `[Languages]` section.
/// - [_tasks]: Generates the `[Tasks]` section.
/// - [_files]: Generates the `[Files]` section.
/// - [_icons]: Generates the `[Icons]` section.
/// - [_run]: Generates the `[Run]` section.
///
/// The [build] method is the main method of this class, which combines all the sections and writes
/// the complete ISS script to a file. It returns the generated script file.
library;

import 'dart:io';

import 'package:inno_bundle/models/config.dart';
import 'package:inno_bundle/models/admin_mode.dart';
import 'package:inno_bundle/utils/cli_logger.dart';
import 'package:inno_bundle/utils/constants.dart';
import 'package:inno_bundle/utils/functions.dart';
import 'package:path/path.dart' as p;

/// A class responsible for generating the Inno Setup Script (ISS) file for the installer.
class ScriptBuilder {
  /// The configuration guiding the script generation process.
  final Config config;

  /// The directory containing the application files to be included in the installer.
  final Directory appDir;

  /// Creates a [ScriptBuilder] instance with the given [config] and [appDir].
  ScriptBuilder(this.config, this.appDir);

  /// Generates the `[Setup]` section of the ISS script, containing metadata and
  /// configuration for the installer.
  String _setup() {
    final outputDir = p.joinAll([
      Directory.current.path,
      ...installerBuildDir,
      config.type.dirName,
    ]);

    var installerIcon = config.installerIcon;
    // save default icon into temp directory to use its path.
    if (installerIcon == defaultInstallerIconPlaceholder) {
      final installerIconDirPath = p.joinAll([
        Directory.systemTemp.absolute.path,
        "${camelCase(config.name)}Installer",
      ]);
      installerIcon = persistDefaultInstallerIcon(installerIconDirPath);
    }

    return '''
[Setup]
AppId=${config.id}
AppName=${config.name}
UninstallDisplayName=${config.name}
UninstallDisplayIcon={app}\\${config.exePubspecName}
AppVersion=${config.version}
AppPublisher=${config.publisher}
AppPublisherURL=${config.url}
AppSupportURL=${config.supportUrl}
AppUpdatesURL=${config.updatesUrl}
LicenseFile=${config.licenseFile}
DefaultDirName={autopf}\\${config.name}
PrivilegesRequired=${config.admin == AdminMode.nonAdmin ? 'lowest' : 'admin'}
PrivilegesRequiredOverridesAllowed=${config.admin == AdminMode.auto ? "dialog commandline" : ""}
OutputDir=$outputDir
OutputBaseFilename=${camelCase(config.name)}-${config.arch.cpu}-${config.version}-Installer
SetupIconFile=$installerIcon
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=${config.arch.value}
ArchitecturesInstallIn64BitMode=${config.arch.value}
DisableDirPage=auto
DisableProgramGroupPage=auto
${config.signTool != null ? config.signTool?.toInnoCode() : ""}
\n''';
  }

  /// Generates the `[InstallDelete]` section for specifying files to delete during uninstallation.
  String _installDelete() {
    return '''
[InstallDelete]
Type: filesandordirs; Name: "{app}\\*"
\n''';
  }

  /// Generates the `[Languages]` section, defining the languages supported by the installer.
  String _languages() {
    String section = "[Languages]\n";
    for (final language in config.languages) {
      section += '${language.toInnoItem()}\n';
    }
    return '$section\n';
  }

  /// Generates the `[Tasks]` section, defining additional installation tasks such as creating desktop icons.
  String _tasks() {
    return '''
[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}";
\n''';
  }

  /// Generates the `[Files]` section, specifying the files and directories to include in the installer.
  String _files() {
    var section = "[Files]\n";

    // adding app build files
    final files = appDir.listSync();
    for (final file in files) {
      final filePath = file.absolute.path;
      if (FileSystemEntity.isDirectorySync(filePath)) {
        final fileName = p.basename(filePath);
        section += "Source: \"$filePath\\*\"; DestDir: \"{app}\\$fileName\"; "
            "Flags: ignoreversion recursesubdirs createallsubdirs\n";
      } else {
        section += "Source: \"$filePath\"; DestDir: \"{app}\"; "
            "Flags: ignoreversion\n";
      }
    }

    // adding optional DLL files from System32 (if they are available),
    // so that the end user is not required to install
    // MS Visual C++ redistributable to run the app.
    final scriptDirPath = p.joinAll([
      Directory.systemTemp.absolute.path,
      "${camelCase(config.name)}Installer",
      config.type.dirName,
    ]);
    Directory(scriptDirPath).createSync(recursive: true);
    for (final fileName in vcDllFiles) {
      final file = File(p.joinAll([...system32, fileName]));
      if (!file.existsSync()) continue;
      final fileNewPath = p.join(scriptDirPath, p.basename(file.path));
      file.copySync(fileNewPath);
      section += "Source: \"$fileNewPath\"; DestDir: \"{app}\";\n";
    }

    return '$section\n';
  }

  /// Generates the `[Icons]` section, defining the shortcuts for the installed application.
  String _icons() {
    return '''
[Icons]
Name: "{autoprograms}\\${config.name}"; Filename: "{app}\\${config.exePubspecName}"
Name: "{autodesktop}\\${config.name}"; Filename: "{app}\\${config.exePubspecName}"; Tasks: desktopicon
\n''';
  }

  /// Generates the `[Run]` section, specifying actions to perform after the installation is complete.
  String _run() {
    return '''
[Run]
Filename: "{app}\\${config.exePubspecName}"; Description: "{cm:LaunchProgram,{#StringChange('${config.name}', '&', '&&')}}"; Flags: nowait postinstall skipifsilent
\n''';
  }

  /// Generates the ISS script file and returns its path.
  Future<File> build() async {
    CliLogger.info("Generating ISS script...");
    final script = scriptHeader +
        _setup() +
        _installDelete() +
        _languages() +
        _tasks() +
        _files() +
        _icons() +
        _run();
    final relScriptPath = p.joinAll([
      ...installerBuildDir,
      config.type.dirName,
      "inno-script.iss",
    ]);
    final absScriptPath = p.join(Directory.current.path, relScriptPath);
    final scriptFile = File(absScriptPath);
    scriptFile.createSync(recursive: true);
    scriptFile.writeAsStringSync(script);
    CliLogger.success("Script generated $relScriptPath");
    return scriptFile;
  }
}
