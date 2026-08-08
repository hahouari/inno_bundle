/// Represents the different languages supported by the Inno Setup installer.
///
/// Each language is associated with a specific Inno Setup language file,
/// which defines the localized text and messages for the installer.
///
/// Example usage:
/// ```dart
/// Language.loadLanguages(isccPath);
/// var language = Language("French");
/// print(language.innoEntry); // Outputs: Name: "French"; MessagesFile: "compiler:Languages\\French.isl"
/// ```
///
/// Properties:
/// - [file]: The filename of the language-specific Inno Setup language file.
/// - [name]: The name of the language, derived from the filename, or English for Default.isl.
///
/// Methods:
/// - [loadLanguages]: Populates the language cache from a given Inno Setup install.
/// - [getByNameOrNull]: Retrieves a [Language] instance by its name, or `null` if not found.
/// - [validateConfig]: Validates a configuration option for [Language],
///   ensuring it is a valid string and corresponds to a supported language.
/// - [innoEntry]: Generates the Inno Setup language item for this language,
///   formatted for inclusion in an Inno Setup script.
/// - [all]: Returns all supported languages for the selected Inno Setup install.
library;

import 'dart:io';
import 'package:inno_bundle/utils/inno_bundle_error.dart';
import 'package:inno_bundle/utils/cli_logger.dart';
import 'package:path/path.dart' as p;

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

  /// Cache of supported languages for the selected Inno Setup install.
  static List<Language> _cachedLangs = [];

  /// Loads the supported languages for the given Inno Setup executable path.
  ///
  /// Scans the installation directory containing [innoPath] for
  /// `Default.isl` (English) and every `Languages/*.isl` file, and replaces
  /// the previously cached set. This is the only way to populate [all].
  static void loadLanguages(String innoPath) {
    final innoDir = File(innoPath).parent;
    final languagesDir = Directory(p.join(innoDir.path, "Languages"));
    final languages = <Language>[];

    // for English, the default language.
    if (File(p.join(innoDir.path, "Default.isl")).existsSync()) {
      languages.add(Language._("English", "Default.isl"));
    }
    // rest of the languages are in the Languages directory.
    if (languagesDir.existsSync()) {
      languagesDir
          .listSync()
          .where((file) => file is File && file.path.endsWith(".isl"))
          .forEach((file) {
        final fileName = p.basename(file.path);
        final fileStem = p.basenameWithoutExtension(fileName);
        languages.add(Language._(fileStem, "Languages\\${fileName}"));
      });
    }
    _cachedLangs = languages;
  }

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
      return "an option in inno_bundle.languages attribute is invalid "
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
  /// Expects [loadLanguages] to have been called beforehand.
  static Never listLanguages() {
    final names = all.map((l) => l.name).join(', ');
    print("$names\n");
    exit(0);
  }

  /// All supported languages for the selected Inno Setup install.
  ///
  /// Throws an [InnoBundleError] if [loadLanguages] has not been called yet.
  static List<Language> get all {
    if (_cachedLangs.isEmpty) {
      throw InnoBundleError(
          'Language.loadLanguages() must be called before accessing Language.all.');
    }
    return _cachedLangs;
  }
}
