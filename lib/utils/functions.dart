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

/// Convert yaml list to list, this prevents some weird behaviors that come with [YamlList] type.
List<dynamic> yamlToList(YamlList yamlList) {
  final list = <dynamic>[];
  for (final value in yamlList) {
    if (value is YamlMap) {
      list.add(yamlToMap(value));
    } else if (value is YamlList) {
      list.add(yamlToList(value));
    } else {
      list.add(value);
    }
  }
  return list;
}

/// Convert yaml to map, this prevents some weird behaviors that come with [YamlMap] type.
Map<String, dynamic> yamlToMap(YamlMap yamlMap) {
  final map = <String, dynamic>{};
  for (final entry in yamlMap.entries) {
    if (entry.value is YamlList) {
      map[entry.key as String] = yamlToList(entry.value as YamlList);
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

/// Reads the [yamlFile] and returns a map of its contents.
/// The [yamlFile] is passed as a [File] object instead of being hardcoded
/// because in the future, we may support reading multiple files for configuration.
Map<String, dynamic> readYaml(File yamlFile) {
  final yamlMap = (loadYaml(yamlFile.readAsStringSync()) ?? YamlMap()) as Map;
  // yamlMap has the type YamlMap, which has several unwanted side effects
  var json = yamlToMap(yamlMap as YamlMap);
  return json;
}

/// Generates a new app id (as UUID) for the app, if not already present.
/// The new id is persisted in the config file.
///
/// The [ns] parameter is used to generate a namespaced UUID, if provided.
void generateEssentials(
  File pubspecFile,
  File configFile,
  CliConfig cliConfig,
) {
  // if neither app id nor publisher is to be generated, do nothing
  if (!cliConfig.generateAppId && !cliConfig.generatePublisher) return;

  final pubspecJson = readYaml(pubspecFile);

  if (!configFile.existsSync()) {
    CliLogger.exitError('The CLI param --path has an invalid value, '
        'the given path does not exist.');
  }

  // if config file is a custom one, read 'inno_bundle' section from it,
  // otherwise, read 'inno_bundle' section from pubspec.yaml.
  final configJson =
      configFile == pubspecFile ? pubspecJson : readYaml(configFile);
  final inno = configJson['inno_bundle'] ?? {};

  // if inno_bundle essentials are already present, do nothing
  if (inno['id'] != null || inno['publisher'] != null) return;

  final lines = configFile.readAsLinesSync();
  var innoInsertLine = lines.indexWhere((l) => l.startsWith("inno_bundle:"));

  // if inno_bundle section is not found, add it at the end of the file
  if (innoInsertLine == -1) {
    // if the last line is not empty, add an empty line before the new section
    if (lines.last.trim().isNotEmpty) lines.add("");

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
      pubspecJson['maintainer'] == null &&
      inno['publisher'] == null) {
    innoInsertLine += 1;
    final publisher = getSystemUserName() ?? "Unknown Publisher";
    lines.insert(innoInsertLine, "  publisher: $publisher");
  }

  configFile.writeAsStringSync(lines.join('\n'));
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
      CliLogger.exitError("Inno Setup 6 is not detected in your machine, "
          "checkout our docs on how to correctly install it:\n"
          "${CliLogger.sLink(innoDownloadStepLink, level: CliLoggerLevel.two)}");
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
    CliLogger.exitError("Inno Setup installation in your machine is corrupted "
        "or incomplete, checkout our docs on how to correctly install it:\n"
        "${CliLogger.sLink(innoDownloadStepLink, level: CliLoggerLevel.two)}");
  }
  return null;
}

/// Get the logged in username in the machine.
String? getSystemUserName() =>
    Platform.environment['USER'] ?? // Linux/macOS
    Platform.environment['USERNAME']; // Windows
