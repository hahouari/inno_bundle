import 'dart:io';

import 'package:test/test.dart';

import 'package:inno_bundle/models/language.dart';
import 'package:inno_bundle/utils/inno_bundle_error.dart';

void main() {
  late Directory tempDir;

  void makeInstaller({List<String> extraLangs = const []}) {
    final langDir =
        Directory('${tempDir.path}/Languages')..createSync(recursive: true);
    File('${tempDir.path}/Default.isl').writeAsStringSync('');
    for (final name in extraLangs) {
      File('${langDir.path}/$name.isl').writeAsStringSync('');
    }
  }

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('inno_lang_test_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  test('throws when accessed before loadLanguages', () {
    expect(() => Language.all, throwsA(isA<InnoBundleError>()));
  });

  test('loads Default + Languages/*.isl from the installer directory', () {
    makeInstaller(extraLangs: ['Portuguese', 'French']);

    Language.loadLanguages('${tempDir.path}/ISCC.exe');

    expect(
      Language.all.map((l) => l.name),
      containsAll({'Portuguese', 'French'}),
    );
  });

  test('replaces the existing cache on subsequent loads', () {
    makeInstaller(extraLangs: ['Portuguese', 'French']);
    Language.loadLanguages('${tempDir.path}/ISCC.exe');

    expect(
      Language.all.map((l) => l.name).where((n) => n == 'Portuguese'),
      isNotEmpty,
    );

    final otherDir =
        Directory.systemTemp.createTempSync('inno_lang_test_2');
    addTearDown(() => otherDir.deleteSync(recursive: true));
    final otherLangDir = Directory('${otherDir.path}/Languages')
      ..createSync(recursive: true);
    File('${otherDir.path}/Default.isl').writeAsStringSync('');
    File('${otherLangDir.path}/German.isl').writeAsStringSync('');
    Language.loadLanguages('${otherDir.path}/ISCC.exe');

    expect(Language.all.map((l) => l.name), isNot(contains('Portuguese')));
    expect(Language.all.map((l) => l.name), contains('German'));
    expect(Language.all.map((l) => l.name), contains('English'));
  });
}