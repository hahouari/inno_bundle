import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'package:inno_bundle/models/cli_configs/inno_bundle_cli_config.dart';
import 'package:inno_bundle/utils/functions.dart';

void main() {
  const validId = '5ec949d0-0582-1e06-b073-b5d1161f6fff';
  const uuid = Uuid();

  late Directory tempDir;
  late File pubspecFile;
  late File configFile;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('gen_essentials_');
    pubspecFile = File(p.join(tempDir.path, 'pubspec.yaml'));
    configFile = pubspecFile;
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  void writePubspec({String? maintainer, String extraYaml = ''}) {
    pubspecFile.writeAsStringSync('''
name: demo_app
description: A demo app.
version: 1.0.0+1
${maintainer != null ? 'maintainer: $maintainer' : ''}
$extraYaml
''');
  }

  String readConfig() => configFile.readAsStringSync();

  test('appends inno_bundle with id and publisher to a bare pubspec', () {
    writePubspec();
    generateEssentials(pubspecFile, configFile, const InnoBundleCliConfig());

    final content = readConfig();
    expect(content, contains('inno_bundle:'));
    expect(content, contains('  id: '));
    expect(content, contains('  publisher: '));
  });

  test('does nothing when an id is already present', () {
    writePubspec(extraYaml: '''
inno_bundle:
  id: $validId
''');
    generateEssentials(pubspecFile, configFile, const InnoBundleCliConfig());

    final content = readConfig();
    expect(
        RegExp(r'^\s{2}id: ', multiLine: true).allMatches(content).length, 1);
    expect(content, isNot(contains('publisher:')));
  });

  test('skips publisher generation when maintainer is present', () {
    writePubspec(maintainer: 'Someone');
    generateEssentials(pubspecFile, configFile, const InnoBundleCliConfig());

    final content = readConfig();
    expect(content, contains('  id: '));
    expect(content, isNot(contains('publisher:')));
  });

  test(
      'inserts the id under an existing inno_bundle section in a custom config',
      () {
    writePubspec();
    configFile = File(p.join(tempDir.path, 'inno_bundle.yaml'));
    configFile.writeAsStringSync('''
inno_bundle:
  admin: auto
''');
    generateEssentials(pubspecFile, configFile, const InnoBundleCliConfig());

    final content = configFile.readAsStringSync();
    expect(content, contains('inno_bundle:'));
    expect(content, contains('  id: '));
    expect(content, contains('  admin: auto'));
  });

  test('uses the namespace to produce a deterministic v5 id', () {
    writePubspec();
    generateEssentials(
      pubspecFile,
      configFile,
      const InnoBundleCliConfig(appIdNamespace: 'example.com'),
    );

    final id =
        RegExp(r'id: ([0-9a-fA-F-]+)').firstMatch(readConfig())!.group(1);
    expect(id, uuid.v5(Namespace.url.value, 'example.com'));
  });

  test('does nothing when neither id nor publisher generation is requested',
      () {
    writePubspec();
    generateEssentials(
      pubspecFile,
      configFile,
      const InnoBundleCliConfig(
        generateAppId: false,
        generatePublisher: false,
      ),
    );

    expect(readConfig(), isNot(contains('inno_bundle')));
  });
}
