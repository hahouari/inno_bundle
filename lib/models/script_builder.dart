import 'package:inno_setup/models/config.dart';
import 'package:inno_setup/utils/functions.dart';
import 'package:path/path.dart' as p;

class ScriptBuilder {
  final Config config;

  ScriptBuilder(this.config);

  String setup() {
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
    final icon = p.join("{#SourcePath}", config.icon);
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
OutputDir=/tmp/${name}Installer
OutputBaseFilename=$installer
SetupIconFile=$icon
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64
DisableDirPage=auto
DisableProgramGroupPage=auto
\n''';
  }

  String installDelete() {
    return '''
[InstallDelete]
Type: filesandordirs; Name: "{app}\\*"
\n''';
  }

  String languages() {
    return '''
[Languages]
Name: "french"; MessagesFile: "compiler:Languages\\French.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"
\n''';
  }

  String tasks() {
    return '''
[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
\n''';
  }

  String files() {
    return '''
[Files]
Source: "{#SourcePath}\\build\\windows\\runner\\Release\\${config.exeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourcePath}\\build\\windows\\runner\\Release\\flutter_acrylic_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourcePath}\\build\\windows\\runner\\Release\\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourcePath}\\build\\windows\\runner\\Release\\pdfium.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourcePath}\\build\\windows\\runner\\Release\\printing_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourcePath}\\build\\windows\\runner\\Release\\realm_dart.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourcePath}\\build\\windows\\runner\\Release\\realm_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourcePath}\\build\\windows\\runner\\Release\\screen_retriever_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourcePath}\\build\\windows\\runner\\Release\\system_theme_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourcePath}\\build\\windows\\runner\\Release\\window_manager_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourcePath}\\build\\windows\\runner\\Release\\url_launcher_windows_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourcePath}\\build\\windows\\runner\\Release\\data\\*"; DestDir: "{app}\\data"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "{#SourcePath}\\build\\windows\\runner\\Release\\msvcp140.dll"; DestDir: "{app}";
Source: "{#SourcePath}\\build\\windows\\runner\\Release\\vcruntime140.dll"; DestDir: "{app}";
Source: "{#SourcePath}\\build\\windows\\runner\\Release\\vcruntime140_1.dll"; DestDir: "{app}";
\n''';
  }

  String icons() {
    return '''
[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
\n''';
  }

  String run() {
    return '''
[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
\n''';
  }

  void build() {
    final scriptFileContent =
        setup() + installDelete() + languages() + tasks() + files() + icons();
    print(scriptFileContent);
  }
}
