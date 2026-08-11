import 'dart:io';

import 'package:inno_bundle/models/language.dart';
import 'package:test/test.dart';

/// Creates a throwaway Inno Setup installation directory containing a couple
/// of language files and loads them through [Language.loadLanguages].
///
/// Returns the installation directory so the caller can clean it up.
Directory createTestLanguagesDir() {
  final innoDir = Directory.systemTemp.createTempSync('inno_test_lang_');
  File('${innoDir.path}/Default.isl').writeAsStringSync('');
  final langDir = Directory('${innoDir.path}/Languages')..createSync();
  File('${langDir.path}/Portuguese.isl').writeAsStringSync('');
  File('${langDir.path}/French.isl').writeAsStringSync('');
  Language.loadLanguages('${innoDir.path}/ISCC.exe');
  return innoDir;
}

/// Installs a [setUp] that populates the [Language] cache from a throwaway
/// Inno Setup directory and tears it down after each test.
void initTestLanguages() {
  setUp(() {
    final innoDir = createTestLanguagesDir();
    addTearDown(() => innoDir.deleteSync(recursive: true));
  });
}
