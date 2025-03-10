/// Represents the different languages supported by the Inno Setup installer.
///
/// Each language is associated with a specific Inno Setup language file,
/// which defines the localized text and messages for the installer.
///
/// Example usage:
/// ```dart
/// var language = Language.french;
/// print(language.toInnoItem()); // Outputs: Name: "french"; MessagesFile: "compiler:Languages\\French.isl"
/// ```
///
/// Properties:
/// - [file]: The filename of the language-specific Inno Setup language file.
///
/// Methods:
/// - [getByNameOrNull]: Retrieves a [Language] instance by its name, or `null` if not found.
/// - [toInnoItem]: Generates the Inno Setup language item for this language,
///   formatted for inclusion in an Inno Setup script.
library;

/// Language enum holding every supported language that comes shipped with Inno Setup.
enum Language {
  english("Default.isl"),
  armenian("Languages\\Armenian.isl"),
  brazilianportuguese("Languages\\BrazilianPortuguese.isl"),
  bulgarian("Languages\\Bulgarian.isl"),
  catalan("Languages\\Catalan.isl"),
  corsican("Languages\\Corsican.isl"),
  czech("Languages\\Czech.isl"),
  danish("Languages\\Danish.isl"),
  dutch("Languages\\Dutch.isl"),
  finnish("Languages\\Finnish.isl"),
  french("Languages\\French.isl"),
  german("Languages\\German.isl"),
  hebrew("Languages\\Hebrew.isl"),
  hungarian("Languages\\Hungarian.isl"),
  icelandic("Languages\\Icelandic.isl"),
  italian("Languages\\Italian.isl"),
  japanese("Languages\\Japanese.isl"),
  korean("Languages\\Korean.isl"),
  norwegian("Languages\\Norwegian.isl"),
  polish("Languages\\Polish.isl"),
  portuguese("Languages\\Portuguese.isl"),
  russian("Languages\\Russian.isl"),
  slovak("Languages\\Slovak.isl"),
  slovenian("Languages\\Slovenian.isl"),
  spanish("Languages\\Spanish.isl"),
  turkish("Languages\\Turkish.isl"),
  ukrainian("Languages\\Ukrainian.isl"),
  swedish("Languages\\Swedish.isl"),
  tamil("Languages\\Tamil.isl"),
  arabic("Languages\\Arabic.isl");

  /// The filename of the language-specific Inno Setup language file.
  final String file;

  /// Creates a [Language] instance with the associated [file] name.
  const Language(this.file);

  /// Retrieves a [Language] instance by its name, or `null` if not found.
  static Language? getByNameOrNull(String name) {
    final index = values.indexWhere((l) => l.name == name);
    return index != -1 ? values[index] : null;
  }

  /// Generates the Inno Setup language item for this language.
  String get innoEntry {
    return "Name: \"$name\"; MessagesFile: \"compiler:$file\"";
  }

  /// Validate configuration option for [Language].
  static String? validateConfig(dynamic option) {
    if (option == null) return null;
    if (option is! String) {
      return "an entry in inno_bundle.languages attribute is invalid "
          "in pubspec.yaml, expected a string, got $option.";
    }
    final language = Language.getByNameOrNull(option);
    if (language == null) {
      return "an entry in inno_bundle.languages attribute is invalid "
          "in pubspec.yaml, language `$option` is not supported.";
    }
    return null;
  }
}
