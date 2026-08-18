import 'package:test/test.dart';

import 'dart:io';

import 'package:inno_bundle/models/admin_mode.dart';
import 'package:inno_bundle/models/build_arch.dart';
import 'package:inno_bundle/models/build_type.dart';
import 'package:inno_bundle/models/cli_configs/inno_bundle_cli_config.dart';
import 'package:inno_bundle/models/config.dart';
import 'package:inno_bundle/models/sign_tool.dart';
import 'package:inno_bundle/models/vcredist_mode.dart';
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
        cliConfig: InnoBundleCliConfig(),
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
          cliConfig: InnoBundleCliConfig(),
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
          cliConfig: InnoBundleCliConfig(),
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
          cliConfig: InnoBundleCliConfig(),
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
          cliConfig: InnoBundleCliConfig(),
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
          cliConfig: InnoBundleCliConfig(),
          pubspecFile: File(''),
          configFile: File(''),
          innoExec: File('test_iscc.exe'),
        ),
        throwsA(isA<InnoBundleError>()),
      );
    });
  });

  group('Config validation (edge options and error paths)', () {
    const validId = '5ec949d0-0582-1e06-b073-b5d1161f6fff';

    Config _from({
      Map<String, dynamic>? json,
      Map<String, dynamic>? inno,
      InnoBundleCliConfig cliConfig = const InnoBundleCliConfig(),
    }) {
      return Config.fromJson(
        json ??
            {
              'name': 'my_app',
              'description': 'A test app.',
              'version': '1.0.0',
              'maintainer': 'Test User',
            },
        {
          'inno_bundle': inno ?? {'id': validId}
        },
        cliConfig: cliConfig,
        pubspecFile: File(''),
        configFile: File(''),
        innoExec: File('test_iscc.exe'),
      );
    }

    test('rejects an invalid admin option', () {
      expect(
        () => _from(inno: {'id': validId, 'admin': 'root'}),
        throwsA(isA<InnoBundleError>()),
      );
    });

    test('accepts admin as the string "auto"', () {
      expect(
          _from(inno: {'id': validId, 'admin': 'auto'}).admin, AdminMode.auto);
    });

    test('accepts admin as a bool', () {
      expect(_from(inno: {'id': validId, 'admin': false}).admin,
          AdminMode.nonAdmin);
      expect(
          _from(inno: {'id': validId, 'admin': true}).admin, AdminMode.admin);
    });

    test('rejects an invalid vc_redist option', () {
      expect(
        () => _from(inno: {'id': validId, 'vc_redist': 'sideload'}),
        throwsA(isA<InnoBundleError>()),
      );
    });

    test('accepts vc_redist as the string "download" and as a bool', () {
      expect(_from(inno: {'id': validId, 'vc_redist': 'download'}).vcRedist,
          VcRedistMode.download);
      expect(_from(inno: {'id': validId, 'vc_redist': true}).vcRedist,
          VcRedistMode.bundle);
      expect(_from(inno: {'id': validId, 'vc_redist': false}).vcRedist,
          VcRedistMode.none);
    });

    test('rejects an invalid arch option', () {
      expect(
        () => _from(inno: {'id': validId, 'arch': 'x32'}),
        throwsA(isA<InnoBundleError>()),
      );
    });

    test('accepts a valid arch option', () {
      expect(_from(inno: {'id': validId, 'arch': 'x64'}).arch, BuildArch.x64);
      expect(_from(inno: {'id': validId, 'arch': 'x64_compatible'}).arch,
          BuildArch.x64Compatible);
    });

    test('rejects a non-list languages option', () {
      expect(
        () => _from(inno: {'id': validId, 'languages': 'English'}),
        throwsA(isA<InnoBundleError>()),
      );
    });

    test('rejects an unsupported language', () {
      expect(
        () => _from(inno: {
          'id': validId,
          'languages': ['Klingon']
        }),
        throwsA(isA<InnoBundleError>()),
      );
    });

    test('rejects a non-list files option', () {
      expect(
        () => _from(inno: {'id': validId, 'files': 'my.dll'}),
        throwsA(isA<InnoBundleError>()),
      );
    });

    test('rejects a file entry without a path', () {
      expect(
        () => _from(inno: {
          'id': validId,
          'files': [
            {'name': 'x.dll'},
          ],
        }),
        throwsA(isA<InnoBundleError>()),
      );
    });

    test('rejects a file entry with an invalid source', () {
      expect(
        () => _from(inno: {
          'id': validId,
          'files': [
            {'path': 'x.dll', 'source': 'elsewhere'},
          ],
        }),
        throwsA(isA<InnoBundleError>()),
      );
    });

    test('rejects an installer icon that does not exist', () {
      final missing =
          'missing_icon_${DateTime.now().microsecondsSinceEpoch}.ico';
      expect(
        () => _from(inno: {'id': validId, 'installer_icon': missing}),
        throwsA(isA<InnoBundleError>()),
      );
    });

    test('rejects a sign_tool with neither name nor command', () {
      expect(
        () => _from(inno: {'id': validId, 'sign_tool': <String, dynamic>{}}),
        throwsA(isA<InnoBundleError>()),
      );
    });

    test('accepts a sign_tool as a string command', () {
      final config =
          _from(inno: {'id': validId, 'sign_tool': r'signtool.exe $p'});
      expect(config.signTool, isA<SignTool>());
      expect(config.signTool!.command, r'signtool.exe $p');
    });

    test('merges the deprecated dlls list with files', () {
      final config = _from(inno: {
        'id': validId,
        'dlls': ['a.dll'],
        'files': ['b.dll'],
      });
      expect(config.files.map((f) => f.name), ['a.dll', 'b.dll']);
    });

    test('splits comma-separated file extension associations and drops blanks',
        () {
      final config = _from(inno: {
        'id': validId,
        'file_extensions_associations': ['.foo,.bar', '  '],
        'file_extensions_associations_exclude': ['.old'],
      });
      expect(config.includedFileExts, ['.foo', '.bar']);
      expect(config.excludedFileExts, ['.old']);
    });

    test('rejects an inno_bundle name that is not a valid file name', () {
      expect(
        () => _from(inno: {'id': validId, 'name': 'bad<name>'}),
        throwsA(isA<InnoBundleError>()),
      );
    });

    test('rejects a missing version attribute', () {
      expect(
        () => _from(json: {
          'name': 'my_app',
          'description': 'A test app.',
          'maintainer': 'Test User',
        }),
        throwsA(isA<InnoBundleError>()),
      );
    });

    test('cli --app-version overrides the config version', () {
      final config = _from(
        cliConfig: const InnoBundleCliConfig(appVersion: '2.0.0'),
      );
      expect(config.version, '2.0.0');
    });
  });
}
