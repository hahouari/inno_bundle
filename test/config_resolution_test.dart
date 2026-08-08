import 'package:test/test.dart';

import 'dart:io';

import 'package:inno_bundle/models/build_type.dart';
import 'package:inno_bundle/cli_args_parsers/inno_bundle_cli_args.dart';
import 'package:inno_bundle/models/config.dart';
import 'package:inno_bundle/utils/constants.dart';
import 'package:inno_bundle/utils/inno_bundle_error.dart';
import 'package:path/path.dart' as p;

import 'support/language_fixture.dart';

void main() {
  initTestLanguages();
  group('Config file resolution', () {
    test('uses the default config file when it exists', () {
      final tempDir = Directory.systemTemp.createTempSync('inno_resolve_');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final defaultConfigFile =
          File(p.join(tempDir.path, defaultConfigFileName));
      defaultConfigFile.writeAsStringSync('');

      final resolved = Config.resolveConfigFile(
        configPath: null,
        pubspecFile: File(''),
        defaultConfigFile: defaultConfigFile,
      );

      expect(resolved, same(defaultConfigFile));
    });

    test('falls back to pubspec.yaml when the default config file is absent',
        () {
      final pubspecFile = File('pubspec.yaml');
      final resolved = Config.resolveConfigFile(
        configPath: null,
        pubspecFile: pubspecFile,
        defaultConfigFile: File('inno_bundle.yaml'),
      );

      expect(resolved, same(pubspecFile));
    });

    test('a custom config path wins over the default config file', () {
      final resolved = Config.resolveConfigFile(
        configPath: 'custom_config.yaml',
        pubspecFile: File('pubspec.yaml'),
        defaultConfigFile: File('inno_bundle.yaml'),
      );

      expect(resolved.path, 'custom_config.yaml');
    });

    test('returns the pubspec file when the config path points to it', () {
      final pubspecFile = File('pubspec.yaml');
      final resolved = Config.resolveConfigFile(
        configPath: 'pubspec.yaml',
        pubspecFile: pubspecFile,
        defaultConfigFile: File('inno_bundle.yaml'),
      );

      expect(resolved, same(pubspecFile));
    });
  });

  group('Config resolution', () {
    test('applies defaults when optional props are omitted', () {
      final json = {
        'name': 'my_app',
        'description': 'A test app.',
        'version': '1.0.0',
        'maintainer': 'Test User',
      };
      final innoJson = {
        'inno_bundle': {
          'id': '5ec949d0-0582-1e06-b073-b5d1161f6fff',
        },
      };

      final config = Config.fromJson(
        json,
        innoJson,
        cliConfig: InnoBundleCliArgs(),
        pubspecFile: File(''),
        configFile: File(''),
        innoExec: File('test_iscc.exe'),
      );

      expect(config.publisher, 'Test User');
      expect(config.languages.length, greaterThan(0));
      expect(config.admin.name, isNotEmpty);
      expect(config.type, BuildType.release);
      expect(config.app, true);
      expect(config.installer, true);
    });

    test('rejects missing inno_bundle section', () {
      expect(
        () => Config.fromJson(
          {'name': 'x'},
          {},
          cliConfig: InnoBundleCliArgs(),
          pubspecFile: File(''),
          configFile: File(''),
          innoExec: File('test_iscc.exe'),
        ),
        throwsA(isA<InnoBundleError>()),
      );
    });

    test('rejects missing id', () {
      expect(
        () => Config.fromJson(
          {'name': 'x'},
          {'inno_bundle': {}},
          cliConfig: InnoBundleCliArgs(),
          pubspecFile: File(''),
          configFile: File(''),
          innoExec: File('test_iscc.exe'),
        ),
        throwsA(isA<InnoBundleError>()),
      );
    });

    test('rejects invalid id format', () {
      expect(
        () => Config.fromJson(
          {'name': 'x'},
          {
            'inno_bundle': {'id': 'not-a-uuid'}
          },
          cliConfig: InnoBundleCliArgs(),
          pubspecFile: File(''),
          configFile: File(''),
          innoExec: File('test_iscc.exe'),
        ),
        throwsA(isA<InnoBundleError>()),
      );
    });

    test('rejects missing name', () {
      expect(
        () => Config.fromJson(
          {},
          {
            'inno_bundle': {'id': '5ec949d0-0582-1e06-b073-b5d1161f6fff'}
          },
          cliConfig: InnoBundleCliArgs(),
          pubspecFile: File(''),
          configFile: File(''),
          innoExec: File('test_iscc.exe'),
        ),
        throwsA(isA<InnoBundleError>()),
      );
    });

    test('rejects missing publisher', () {
      expect(
        () => Config.fromJson(
          {'name': 'x'},
          {
            'inno_bundle': {
              'id': '5ec949d0-0582-1e06-b073-b5d1161f6fff',
            },
          },
          cliConfig: InnoBundleCliArgs(),
          pubspecFile: File(''),
          configFile: File(''),
          innoExec: File('test_iscc.exe'),
        ),
        throwsA(isA<InnoBundleError>()),
      );
    });
  });
}
