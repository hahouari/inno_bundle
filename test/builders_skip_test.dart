import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:inno_bundle/builders/app_builder.dart';
import 'package:inno_bundle/builders/installer_builder.dart';
import 'package:inno_bundle/models/cli_configs/inno_bundle_cli_config.dart';
import 'package:inno_bundle/models/config.dart';

import 'support/language_fixture.dart';

void main() {
  initTestLanguages();

  Config _config(InnoBundleCliConfig cliConfig, {Directory? baseDir}) {
    return Config.fromJson(
      {'name': 'x', 'description': 'x', 'version': '1.0', 'maintainer': 'x'},
      {
        'inno_bundle': {
          'id': '5ec949d0-0582-1e06-b073-b5d1161f6fff',
          'admin': 'auto',
          'arch': 'x64_compatible',
        },
      },
      cliConfig: cliConfig,
      pubspecFile: File(''),
      configFile: File(''),
      innoExec: File('test_iscc.exe'),
      baseDir: baseDir,
    );
  }

  group('AppBuilder --no-app skip path', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('no_app_skip_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('returns the existing non-empty build dir without invoking flutter',
        () async {
      final releaseDir = Directory(
        p.join(tempDir.path, 'build', 'windows', 'x64', 'runner', 'Release'),
      )..createSync(recursive: true);
      File(p.join(releaseDir.path, 'app.exe')).writeAsStringSync('x');

      final config = _config(
        const InnoBundleCliConfig(app: false),
        baseDir: tempDir,
      );
      final dir = await AppBuilder(config).build();

      expect(p.normalize(dir.path), p.normalize(releaseDir.path));
    });
  });

  group('InstallerBuilder --no-installer skip path', () {
    test('returns without touching the ISCC executable', () async {
      final config = _config(const InnoBundleCliConfig(installer: false));
      final dir = await InstallerBuilder(config, File('unused.iss')).build();
      expect(dir.path, isEmpty);
    });
  });
}
