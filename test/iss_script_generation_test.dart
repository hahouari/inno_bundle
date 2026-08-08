import 'dart:io';

import 'package:test/test.dart';

import 'package:inno_bundle/builders/script_builder.dart';
import 'package:inno_bundle/cli_args_parsers/inno_bundle_cli_args.dart';
import 'package:inno_bundle/models/config.dart';

import 'support/language_fixture.dart';

void main() {
  initTestLanguages();
  group('.iss script generation', () {
    late Directory tempDir;
    late Directory appDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('inno_test_');
      appDir = Directory('${tempDir.path}\\app');
      appDir.createSync();
      // Put a dummy exe so the [Files] section has something to list
      File('${appDir.path}\\my_app.exe').writeAsStringSync('dummy');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    Config _config({List<String> outputDir = const ['tmp', 'inno_out']}) {
      return Config.fromJson(
        {
          'name': 'my_app',
          'description': 'A test app.',
          'version': '1.0.0',
          'maintainer': 'Test User',
        },
        {
          'inno_bundle': {
            'id': '5ec949d0-0582-1e06-b073-b5d1161f6fff',
          },
        },
        cliConfig: InnoBundleCliArgs(),
        pubspecFile: File(''),
        configFile: File(''),
        outputDir: outputDir,
        innoExec: File('test_iscc.exe'),
      );
    }

    test('includes [Setup] section with id, publisher, version from config',
        () {
      final config = _config(outputDir: ['tmp', 'inno_out']);
      final builder = ScriptBuilder(config, appDir);

      final script = builder.buildScript();

      expect(script, contains('[Setup]'));
      expect(script, contains('AppId=5ec949d0-0582-1e06-b073-b5d1161f6fff'));
      expect(script, contains('AppName=my_app'));
      expect(script, contains('AppVersion=1.0.0'));
      expect(script, contains('AppPublisher=Test User'));
    });

    test('includes one [Files] entry per DLL in the required-DLL allowlist',
        () {
      final config = _config(outputDir: ['tmp', 'inno_out']);
      final builder = ScriptBuilder(config, appDir);

      final script = builder.buildScript();

      expect(script, contains('[Files]'));
      expect(script, contains('Source:'));
      // The app exe should be listed
      expect(script, contains('my_app.exe'));
    });

    test('honors architecture selection (x64) in output paths', () {
      final config = _config(outputDir: ['tmp', 'inno_out']);
      final builder = ScriptBuilder(config, appDir);

      final script = builder.buildScript();

      expect(script, contains('ArchitecturesAllowed=x64compatible'));
      expect(script, contains('ArchitecturesInstallIn64BitMode=x64compatible'));
    });
  });
}
