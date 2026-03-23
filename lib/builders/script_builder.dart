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

import 'package:path/path.dart' as p;

import 'package:inno_bundle/models/admin_mode.dart';
import 'package:inno_bundle/models/config.dart';
import 'package:inno_bundle/models/file_entry.dart';
import 'package:inno_bundle/models/vcredist_mode.dart';
import 'package:inno_bundle/utils/cli_logger.dart';
import 'package:inno_bundle/utils/constants.dart';
import 'package:inno_bundle/utils/functions.dart';

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
${config.includedFileExts.isNotEmpty || config.excludedFileExts.isNotEmpty ? "ChangesAssociations=yes" : ""}
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
      section += '${language.innoEntry}\n';
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
    final appFiles = appDir.listSync();

    for (final appFile in appFiles) {
      final filePath = appFile.absolute.path;
      if (FileSystemEntity.isDirectorySync(filePath)) {
        final fileName = p.basename(filePath);
        section += 'Source: "$filePath\\*"; DestDir: "{app}\\$fileName"; '
            'Flags: ignoreversion recursesubdirs createallsubdirs\n';
      } else {
        section += 'Source: "$filePath"; DestDir: "{app}"; '
            'Flags: ignoreversion\n';
      }
    }

    // adding optional files from System32 (if they are available),
    // so that the end user is not required to install
    // MS Visual C++ redistributable to run the app.
    final files = config.files.toList();
    if (config.vcRedist == VcRedistMode.bundle) {
      files.addAll(FileEntry.vcEntries);
    }

    // copy all the files to the installer build directory
    final scriptDirPath = p.joinAll([
      Directory.systemTemp.absolute.path,
      "${camelCase(config.name)}Installer",
      config.type.dirName,
    ]);
    Directory(scriptDirPath).createSync(recursive: true);

    for (final f in files) {
      final file = File(f.absolutePath);
      if (!file.existsSync()) {
        // if the file is not required, skip it, otherwise exit with error.
        if (!f.required) continue;
        CliLogger.exitError("Required file ${file.path} does not exist.");
      }

      final fPath = p.join(scriptDirPath, p.basename(file.path));
      final fName = f.name;
      file.copySync(fPath);
      final destDir = p.join("{app}", f.destination ?? "");
      section += 'Source: "$fPath"; DestDir: "$destDir"; '
          'DestName: "$fName"; Flags: ignoreversion\n';
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

  /// Generates the `[DownloadVcRedist]` section for downloading the Visual C++ Redistributable.
  /// This section will create a checkbox on the last page of the installer, checked it by default,
  /// if left checked after user click finish,
  /// the installer will open default browser and download the Visual C++ Redistributable
  String _downloadVcRedist() {
    if (config.vcRedist != VcRedistMode.download) return '';
    return '''
; This section will create a checkbox on the last page of the installer, checked it by default,
; if left checked after user click finish,
; the installer will open default browser and download the Visual C++ Redistributable
[Code]
var
  RunList: TNewCheckListBox;
  VCCheckBox: TNewCheckBox;

// Repositions the VCCheckBox relative to the RunList's current position when the window is resized
procedure OnWizardFormResize(Sender: TObject);
begin
  if (VCCheckBox <> nil) and (RunList <> nil) and WizardForm.FinishedPage.Visible then
  begin
    // Reposition the checkbox relative to the RunList's current position
    VCCheckBox.SetBounds(
      RunList.Left + 4,
      RunList.Top + 25,
      VCCheckBox.Width,
      VCCheckBox.Height
    );
  end;
end;

// Create checkbox on the last page of the installer to download VC Runtime.
procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = wpFinished then
  begin
    // The RunList is a TNewCheckListBox that contains checkboxes for [Run] entries
    // It's created automatically when you have [Run] entries with postinstall flag
    RunList := WizardForm.RunList;
    
    if RunList <> nil then
    begin
      // Create our custom checkbox below the RunList
      VCCheckBox := TNewCheckBox.Create(WizardForm);
      VCCheckBox.Parent := WizardForm.FinishedPage;
      
      // Position it below the RunList
      VCCheckBox.SetBounds(
        RunList.Left + 4,
        RunList.Top + 25,
        RunList.Width,
        ScaleY(17)
      );
      
      // Set the checkbox properties
      VCCheckBox.Caption := 'Download and install required Visual C++ runtime (recommended)';
      VCCheckBox.Checked := True; // Default checked
      VCCheckBox.Font.Assign(WizardForm.FinishedLabel.Font);
      
      // Make sure it's visible
      VCCheckBox.Visible := True;
            
      // Assign the resize event handler
      WizardForm.OnResize := @OnWizardFormResize;
    end
  end;
end;

// This runs *after* the user clicks "Finish" on the last page
procedure CurStepChanged(CurStep: TSetupStep);
var
  ErrCode: Integer;
begin
  if (CurStep = ssDone) and VCCheckBox.Checked then
  begin
      ShellExec('', 'https://aka.ms/vs/17/release/vc_redist.x64.exe', '', '', SW_SHOWNORMAL, ewNoWait, ErrCode);
  end;
end;
\n''';
  }

  (
    String ext,
    String dotExt,
    String regLocationName,
  ) _extCommandParts(String maybeDotExt) {
    final name = config.name;

    String dotExt;
    String ext;
    if (maybeDotExt.startsWith('.')) {
      dotExt = maybeDotExt;
      ext = maybeDotExt.substring(1);
    } else {
      dotExt = '.$maybeDotExt';
      ext = maybeDotExt;
    }
    final regLocationName = '$name$dotExt';
    return (ext, dotExt, regLocationName);
  }

  String _removeOldExtCommand(String fileExt) {
    final (_, __, regLocationName) = _extCommandParts(fileExt);
    return 'Root: HKA; Subkey: "Software\\Classes\\$regLocationName"; Flags: deletekey';
  }

  String _addExtCommand(String fileExt) {
    final name = config.name;
    final (ext, dotExt, regLocationName) = _extCommandParts(fileExt);
    return '''
Root: HKA; Subkey: "Software\\${name}\\Capability\\FileAssociations"; ValueType: string; ValueName: "$dotExt"; ValueData: "$regLocationName"; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\\Classes\\$dotExt\\OpenWithProgids"; ValueType: string; ValueName: "$regLocationName"; ValueData: ""; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\\Classes\\$regLocationName"; ValueType: string; ValueName: ""; ValueData: "${ext.toUpperCase()} File"; Flags: uninsdeletekey
Root: HKA; Subkey: "Software\\Classes\\$regLocationName\\DefaultIcon"; ValueType: string; ValueName: ""; ValueData: "{app}\\${config.exePubspecName},0"
Root: HKA; Subkey: "Software\\Classes\\$regLocationName\\shell\\open\\command"; ValueType: string; ValueName: ""; ValueData: """{app}\\${config.exePubspecName}"" ""%1"""
Root: HKA; Subkey: "Software\\Classes\\Applications\\${name}\\SupportedTypes"; ValueType: string; ValueName: "$dotExt"; ValueData: ""
''';
  }

  String _fileExtsRegistry() {
    if (config.includedFileExts.isEmpty && config.excludedFileExts.isEmpty) {
      return '';
    }
    final name = config.name;
    final createCapabilityKeyCommand = '''
Root: HKA; Subkey: "Software\\${name}"; Flags: uninsdeletekeyifempty
Root: HKA; Subkey: "Software\\${name}\\Capability"; ValueType: string; ValueName: "ApplicationName"; ValueData: "${name}"; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\\${name}\\Capability"; ValueType: string; ValueName: "ApplicationDescription"; ValueData: "${config.description}"; Flags: uninsdeletevalue
Root: HKA; Subkey: "Software\\RegisteredApplications"; ValueType: string; ValueName: "${name}"; ValueData: "Software\\${name}\\Capability"; Flags: uninsdeletevalue
''';

    final removedExtsCommands =
        config.excludedFileExts.map(_removeOldExtCommand).join('\n');
    final addedExtsCommands =
        config.includedFileExts.map(_addExtCommand).join('\n');

    return '''
[Registry]

$createCapabilityKeyCommand
$removedExtsCommands
$addedExtsCommands
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
        _fileExtsRegistry() +
        _icons() +
        _run() +
        _downloadVcRedist();
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
