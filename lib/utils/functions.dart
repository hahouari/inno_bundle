/// Utility functions for handling YAML, string manipulation, file operations, and system environment.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:inno_bundle/models/cli_config.dart';
import 'package:inno_bundle/utils/cli_logger.dart';
import 'package:inno_bundle/utils/constants.dart';
import 'package:inno_bundle/utils/installer_icon.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:yaml/yaml.dart';

/// Convert yaml to map, this prevents some weird behaviors that come with [YamlMap] type.
Map<String, dynamic> yamlToMap(YamlMap yamlMap) {
  final map = <String, dynamic>{};
  for (final entry in yamlMap.entries) {
    if (entry.value is YamlList) {
      final list = <String>[];
      for (final value in entry.value as YamlList) {
        if (value is String) {
          list.add(value);
        }
      }
      map[entry.key as String] = list;
    } else if (entry.value is YamlMap) {
      map[entry.key as String] = yamlToMap(entry.value as YamlMap);
    } else {
      map[entry.key as String] = entry.value;
    }
  }
  return map;
}

/// Converts a string to camelCase.
///
/// Example: `camelCase("hello-world_out there")` returns "helloWorldOutThere".
String camelCase(String value) {
  return value
      .split(RegExp(r'[-_]|\s'))
      .map((word) => capitalize(word))
      .join('');
}

/// Capitalizes the first letter of a string.
///
/// Example: `capitalize("hello")` returns "Hello".
String capitalize(String value) {
  if (value.isEmpty) return "";
  return value[0].toUpperCase() + value.substring(1);
}

/// Persists the default installer icon to a file in the given directory.
///
/// Decodes a Base64-encoded icon string and writes it to a file in the
/// system temp directory.
///
/// Returns the absolute path of the saved icon file.
String persistDefaultInstallerIcon(String dirPath) {
  Directory(dirPath).createSync();
  final iconPath = p.join(dirPath, defaultInstallerIconFileName);
  final file = File(iconPath);
  Uint8List bytes = base64.decode(defaultInstallerIcon);
  file.writeAsBytesSync(bytes);
  return file.absolute.path;
}

/// Retrieves the user's home directory path.
///
/// Uses environment variables to determine the home directory based on the operating system.
String getHomeDir() {
  String home = "";
  Map<String, String> envVars = Platform.environment;
  if (Platform.isMacOS || Platform.isLinux) {
    home = envVars['HOME'] ?? home;
  } else if (Platform.isWindows) {
    home = envVars['UserProfile'] ?? home;
  }
  return home;
}

/// Reads the [pubspecFile] and returns a map of its contents.
/// The [pubspecFile] is passed as a [File] object instead of being hardcoded
/// because in the future, we may support reading multiple files for configuration.
Map<String, dynamic> readPubspec(File pubspecFile) {
  final yamlMap = loadYaml(pubspecFile.readAsStringSync()) as Map;
  // yamlMap has the type YamlMap, which has several unwanted side effects
  var json = yamlToMap(yamlMap as YamlMap);
  return json;
}

/// Generates a new app id (as UUID) for the app, if not already present.
/// The new id is persisted in the pubspec.yaml file.
///
/// The [ns] parameter is used to generate a namespaced UUID, if provided.
void generateEssentials(File pubspecFile, CliConfig cliConfig) {
  // if neither app id nor publisher is to be generated, do nothing
  if (!cliConfig.generateAppId && !cliConfig.generatePublisher) return;

  final json = readPubspec(pubspecFile);
  final inno = json['inno_bundle'] ?? {};

  // if inno_bundle essentials are already present, do nothing
  if (inno['id'] != null || inno['publisher'] != null) return;

  final lines = pubspecFile.readAsLinesSync();
  var innoInsertLine = lines.indexWhere((l) => l.startsWith("inno_bundle:"));

  // if inno_bundle section is not found, add it at the end of the file
  if (innoInsertLine == -1) {
    lines.add("inno_bundle:");
    innoInsertLine = lines.length - 1;
  }

  // this does not check if [id] is type string or if it is valid UUID,
  // at this point it is user's responsibility to make sure [id] is valid.
  if (cliConfig.generateAppId && inno['id'] == null) {
    const uuid = Uuid();
    final appId = cliConfig.appIdNamespace != null
        ? uuid.v5(Namespace.url.value, cliConfig.appIdNamespace)
        : uuid.v1();
    innoInsertLine += 1;
    lines.insert(innoInsertLine, "  id: $appId");
  }

  if (cliConfig.generatePublisher &&
      json['maintainer'] == null &&
      inno['publisher'] == null) {
    innoInsertLine += 1;
    lines.insert(innoInsertLine, "  publisher: ${getSystemUserName()}");
  }

  pubspecFile.writeAsStringSync(lines.join('\n'));
}

/// Checks if Winget is installed on the system, and returns the path to the executable.
Future<String> getWingetExec() async {
  final process = await Process.run('where.exe', ['winget']);

  final exitCode = process.exitCode;
  if (exitCode != 0) {
    CliLogger.error("Winget is not detected in your machine, "
        "Passing --install-inno-setup requires Winget to be installed.\n");
    exit(exitCode);
  }
  return process.stdout.toString().trim();
}

/// Installs Inno Setup into your system if not already installed with Winget.
Future<void> installInnoSetup() async {
  final innoSetupExec = getInnoSetupExec(throwIfNotFound: false);
  if (innoSetupExec != null) {
    CliLogger.info("Inno Setup is already installed.");
    return;
  }

  final wingetExec = await getWingetExec();
  final wingetFile = File(wingetExec);

  final process = await Process.start(
    wingetFile.path,
    innoSetupInstallationSubCommand,
    runInShell: true,
    workingDirectory: Directory.current.path,
    mode: ProcessStartMode.inheritStdio,
  );

  final exitCode = await process.exitCode;
  if (exitCode != 0) exit(exitCode);
}

/// Locates the Inno Setup executable file, ensuring its proper installation.
///
/// Throws a [ProcessException] if Inno Setup is not found or is corrupted.
File? getInnoSetupExec({bool throwIfNotFound = true}) {
  if (!Directory(p.joinAll(innoSysDirPath)).existsSync() &&
      !Directory(p.joinAll(innoUserDirPath)).existsSync()) {
    if (throwIfNotFound) {
      CliLogger.error("Inno Setup is not detected in your machine, "
          "checkout our README on how to correctly install it:\n"
          "${CliLogger.sLink(readmeDownloadStepLink, level: CliLoggerLevel.two)}");
      exit(1);
    }
    return null;
  }

  final sysExec = p.joinAll([...innoSysDirPath, "ISCC.exe"]);
  final sysExecFile = File(sysExec);
  final userExec = p.joinAll([...innoUserDirPath, "ISCC.exe"]);
  final userExecFile = File(userExec);

  if (sysExecFile.existsSync()) return sysExecFile;
  if (userExecFile.existsSync()) return userExecFile;

  if (throwIfNotFound) {
    CliLogger.error("Inno Setup installation in your machine is corrupted "
        "or incomplete, checkout our README on how to correctly install it:\n"
        "${CliLogger.sLink(readmeDownloadStepLink, level: CliLoggerLevel.two)}");
    exit(1);
  }
  return null;
}

/// Get the logged in username in the machine.
String getSystemUserName() =>
    Platform.environment['USER'] ?? // Linux/macOS
    Platform.environment['USERNAME'] ?? // Windows
    'Unknown User';
