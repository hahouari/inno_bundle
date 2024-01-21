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
  norwegian("Languages\\Norwegian.isl"),
  polish("Languages\\Polish.isl"),
  portuguese("Languages\\Portuguese.isl"),
  russian("Languages\\Russian.isl"),
  slovak("Languages\\Slovak.isl"),
  slovenian("Languages\\Slovenian.isl"),
  spanish("Languages\\Spanish.isl"),
  turkish("Languages\\Turkish.isl"),
  ukrainian("Languages\\Ukrainian.isl");

  /// The filename of the language-specific Inno Setup language file.
  final String file;

  /// Creates a [Language] instance with the associated [file] name.
  const Language(this.file);

  /// Retrieves a [Language] instance by its name, or `null` if not found.
  static Language? getByNameOrNull(String name) {
    final index = Language.values.indexWhere((l) => l.name == name);
    return index != -1 ? Language.values[index] : null;
  }

  /// Generates the Inno Setup language item for this language.
  String toInnoItem() {
    return "Name: \"$name\"; MessagesFile: \"compiler:$file\"";
  }
}
