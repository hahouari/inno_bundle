import 'dart:io';

import 'package:inno_bundle/models/config.dart';
import 'package:inno_bundle/utils/constants.dart';
import 'package:inno_bundle/utils/functions.dart';
import 'package:path/path.dart' as p;

class ScriptBuilder {
  final Config config;
  final Directory appDir;

  ScriptBuilder(this.config, this.appDir);

  String _setup() {
    final id = config.id;
    final name = camelCase(config.name);
    final version = config.version;
    final publisher = config.publisher;
    final url = config.url;
    final supportUrl = config.supportUrl;
    final updatesUrl = config.updatesUrl;
    final privileges = config.admin ? 'admin' : 'lowest';
    final installer = '${camelCase(config.name)}-x86_64'
        '-${config.version}-Installer';
    var installerIcon = config.installerIcon;
    final outputDir = p.joinAll([
      Directory.current.path,
      ...installerBuildDir,
      config.type.dirName,
    ]);

    if (installerIcon == defaultInstallerIconPlaceholder) {
      final installerIconDirPath = p.joinAll([
        Directory.systemTemp.absolute.path,
        "${camelCase(config.name)}Installer",
      ]);

      installerIcon = persistDefaultInstallerIcon(installerIconDirPath);
    }

    return '''
[Setup]
AppId=$id
AppName=$name
AppVersion=$version
AppPublisher=$publisher
AppPublisherURL=$url
AppSupportURL=$supportUrl
AppUpdatesURL=$updatesUrl
DefaultDirName={autopf}\\$name
PrivilegesRequired=$privileges
OutputDir=$outputDir
OutputBaseFilename=$installer
SetupIconFile=$installerIcon
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64
DisableDirPage=auto
DisableProgramGroupPage=auto
\n''';
  }

  String _installDelete() {
    return '''
[InstallDelete]
Type: filesandordirs; Name: "{app}\\*"
\n''';
  }

  String _languages() {
    String section = "[Languages]\n";
    for (final language in config.languages) {
      section += '${language.toInnoItem()}\n';
    }
    return '$section\n';
  }

  String _tasks() {
    return '''
[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
\n''';
  }

  String _files() {
    String section = "[Files]\n";

    // adding app files
    final files = appDir.listSync();
    for (final file in files) {
      final filePath = file.absolute.path;
      if (FileSystemEntity.isDirectorySync(filePath)) {
        final fileName = p.basename(file.path);
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

  String _icons() {
    final name = config.name;
    final exeName = config.exeName;
    return '''
[Icons]
Name: "{autoprograms}\\$name"; Filename: "{app}\\$exeName"
Name: "{autodesktop}\\$name"; Filename: "{app}\\$exeName"; Tasks: desktopicon
\n''';
  }

  String _run() {
    final name = config.name;
    final exeName = config.exeName;
    return '''
[Run]
Filename: "{app}\\$exeName"; Description: "{cm:LaunchProgram,{#StringChange('$name', '&', '&&')}}"; Flags: nowait postinstall skipifsilent
\n''';
  }

  Future<File> build() async {
    final script = scriptHeader +
        _setup() +
        _installDelete() +
        _languages() +
        _tasks() +
        _files() +
        _icons() +
        _run();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final scriptPath = p.joinAll([
      Directory.systemTemp.absolute.path,
      "${camelCase(config.name)}Installer",
      config.type.dirName,
      "${config.name}.timestamp-$timestamp.iss",
    ]);
    final scriptFile = File(scriptPath);
    scriptFile.createSync(recursive: true);
    scriptFile.writeAsStringSync(script);
    return scriptFile;
  }
}
