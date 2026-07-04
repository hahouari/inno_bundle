/// Represents the different languages supported by the Inno Setup installer.
///
/// Each language is associated with a specific Inno Setup language file,
/// which defines the localized text and messages for the installer.
///
/// Example usage:
/// ```dart
/// var language = Language("French");
/// print(language.innoEntry); // Outputs: Name: "French"; MessagesFile: "compiler:Languages\\French.isl"
/// ```
///
/// Properties:
/// - [file]: The filename of the language-specific Inno Setup language file.
/// - [name]: The name of the language, derived from the filename, or English for Default.isl.
///
/// Methods:
/// - [getByNameOrNull]: Retrieves a [Language] instance by its name, or `null` if not found.
/// - [validateConfig]: Validates a configuration option for [Language],
///   ensuring it is a valid string and corresponds to a supported language.
/// - [innoEntry]: Generates the Inno Setup language item for this language,
///   formatted for inclusion in an Inno Setup script.
/// - [all]: Returns a list of all supported languages by scanning the Inno Setup installation directory.
library;

import 'dart:io';
import 'package:inno_bundle/utils/cli_logger.dart';
import 'package:path/path.dart' as p;

import 'package:inno_bundle/utils/functions.dart';

/// A language supported by the Inno Setup installer.
class Language {
  /// Creates a [Language] instance with the associated [file].
  const Language._(this.name, this.file);

  /// Creates a [Language] instance with the associated [name].
  factory Language(String name) {
    final language = getByNameOrNull(name);
    if (language == null) {
      throw ArgumentError("Language not found: $name");
    }
    return language;
  }

  /// The filename of the language-specific Inno Setup language file.
  final String file;

  /// The name of the language, derived from the filename, or English for Default.isl.
  final String name;

  /// Cache for all supported languages to avoid repeated directory scans.
  static List<Language> _cachedLangs = [];

  // const Language(this.file);

  /// Retrieves a [Language] instance by its name, or `null` if not found.
  static Language? getByNameOrNull(String name) {
    for (final lang in all) {
      final langName = lang.name;
      if (langName.toLowerCase() == name.toLowerCase()) {
        return lang;
      }
    }
    final index = all.indexWhere((l) => l.name == name);
    return index != -1 ? all[index] : null;
  }

  /// Generates the Inno Setup language item for this language.
  String get innoEntry {
    return "Name: \"$name\"; MessagesFile: \"compiler:$file\"";
  }

  /// Validate configuration option for [Language].
  static String? validateConfig(dynamic option, {required String configName}) {
    if (option == null) return null;
    if (option is! String) {
      return "an entry in inno_bundle.languages attribute is invalid "
          "in $configName, expected a string, got $option.";
    }
    final language = Language.getByNameOrNull(option);
    if (language == null) {
      return "an entry in inno_bundle.languages attribute is invalid "
          "in $configName, language `$option` is not supported.";
    }

    // If the name does not match exactly,
    // we need to notify the user of the partial match.
    if (language.name != option) {
      CliLogger.info("Language `$option` is not an exact match, "
          "it will be replaced with `${language.name}`.");
    }
    return null;
  }

  /// Prints all supported language names separated by `, ` and exits.
  ///
  /// Shows the Inno Setup installation directory used for discovery.
  static Never listLanguages() {
    final innoDir = getInnoSetupExec()!.parent;
    final names = all.map((l) => l.name).join(', ');
    CliLogger.info('Languages discovered from ${innoDir.path}:');
    print("$names\n");
    exit(0);
  }

  /// Returns a list of all supported languages by scanning the Inno Setup installation directory.
  static List<Language> get all {
    if (_cachedLangs.isNotEmpty) return _cachedLangs;
    final innoDir = getInnoSetupExec()!.parent;
    final languagesDir = Directory(p.join(innoDir.path, "Languages"));
    final languages = <Language>[];

    // for English, the default language.
    if (File(p.join(innoDir.path, "Default.isl")).existsSync()) {
      languages.add(Language._("English", "Default.isl"));
    }
    // rest of the languages are in the Languages directory.
    languagesDir
        .listSync()
        .where((file) => file is File && file.path.endsWith(".isl"))
        .forEach((file) {
      final fileName = p.basename(file.path);
      final fileStem = p.basenameWithoutExtension(fileName);
      languages.add(Language._(fileStem, "Languages\\${fileName}"));
    });
    _cachedLangs = languages;
    return languages;
  }
}
