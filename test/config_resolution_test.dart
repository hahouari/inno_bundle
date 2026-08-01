import 'package:test/test.dart';

import 'dart:io';

import 'package:inno_bundle/models/build_type.dart';
import 'package:inno_bundle/models/cli_config.dart';
import 'package:inno_bundle/models/config.dart';
import 'package:inno_bundle/utils/inno_bundle_error.dart';

void main() {
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
        cliConfig: CliConfig(),
        pubspecFile: File(''),
        configFile: File(''),
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
          cliConfig: CliConfig(),
          pubspecFile: File(''),
          configFile: File(''),
        ),
        throwsA(isA<InnoBundleError>()),
      );
    });

    test('rejects missing id', () {
      expect(
        () => Config.fromJson(
          {'name': 'x'},
          {'inno_bundle': {}},
          cliConfig: CliConfig(),
          pubspecFile: File(''),
          configFile: File(''),
        ),
        throwsA(isA<InnoBundleError>()),
      );
    });

    test('rejects invalid id format', () {
      expect(
        () => Config.fromJson(
          {'name': 'x'},
          {'inno_bundle': {'id': 'not-a-uuid'}},
          cliConfig: CliConfig(),
          pubspecFile: File(''),
          configFile: File(''),
        ),
        throwsA(isA<InnoBundleError>()),
      );
    });

    test('rejects missing name', () {
      expect(
        () => Config.fromJson(
          {},
          {'inno_bundle': {'id': '5ec949d0-0582-1e06-b073-b5d1161f6fff'}},
          cliConfig: CliConfig(),
          pubspecFile: File(''),
          configFile: File(''),
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
          cliConfig: CliConfig(),
          pubspecFile: File(''),
          configFile: File(''),
        ),
        throwsA(isA<InnoBundleError>()),
      );
    });
  });
}
