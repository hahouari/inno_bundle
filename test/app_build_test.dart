import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:inno_bundle/builders/app_builder.dart';
import 'package:inno_bundle/models/cli_configs/inno_bundle_cli_config.dart';
import 'package:inno_bundle/models/config.dart';

import 'support/flutter_build.dart';
import 'support/language_fixture.dart';

void main() {
  initTestLanguages();
  group('AppBuilder', () {
    test('accepts a Flutter project config without throwing', () {
      final config = Config.fromJson(
        {'name': 'x', 'description': 'x', 'version': '1.0', 'maintainer': 'x'},
        {
          'inno_bundle': {'id': '5ec949d0-0582-1e06-b073-b5d1161f6fff'}
        },
        cliConfig: InnoBundleCliConfig(),
        pubspecFile: File(''),
        configFile: File(''),
        innoExec: File('test_iscc.exe'),
      );

      expect(() => AppBuilder(config), isNot(throwsA(anything)));
    },
        skip: !Platform.isWindows
            ? 'Windows-only: needs Flutter Windows build tooling'
            : false);

    test(
      'flutter build tool produces expected windows/runner output tree',
      () async {
        final _config = Config.fromJson(
          {
            'name': 'demo_app',
            'description': 'A demo app.',
            'version': '1.0.0+1',
            'maintainer': 'Hocine Abdellatif Houari',
          },
          {
            'inno_bundle': {
              'id': '5ec949d0-0582-1e06-b073-b5d1161f6fff',
            },
          },
          cliConfig: InnoBundleCliConfig(),
          pubspecFile: File(p.join(fixtureAppPath, 'pubspec.yaml')),
          configFile: File(p.join(fixtureAppPath, 'pubspec.yaml')),
          innoExec: File('test_iscc.exe'),
        );
        // Assert config construction is valid; the app build below does not
        // consume it directly (we invoke `flutter build` as a subprocess), but
        // building the Config exercises the same resolution path the CLI uses.
        expect(_config.name, 'demo_app');

        // Act: build the app ONCE. Downstream cross-version installer tests can
        // reuse this exact output dir (see `demoAppReleaseExe`) instead of
        // rebuilding Flutter per Inno version. Locked so a concurrent build
        // from `full_pipeline_cross_version_test.dart` never races into the
        // same `build/windows/x64` dir (CMake/MSBuild file-lock failures).
        await ensureDemoAppBuilt();

        expect(
          File(demoAppReleaseExe).existsSync(),
          isTrue,
          reason: 'Expected release exe not found at $demoAppReleaseExe.',
        );
      },
      timeout: const Timeout(Duration(minutes: 2)),
      skip: !Platform.isWindows
          ? 'Windows-only: needs Flutter Windows build tooling'
          : false,
    );

    test(
      'build failure surfaces a clear error',
      () async {
        // Point the builder at a directory with no Flutter project and confirm
        // `flutter build windows` exits non-zero (the AppBuilder itself
        // propagates via `exit(exitCode)`).
        final bogus = Directory.systemTemp.createTempSync('no_flutter_');
        addTearDown(() => bogus.deleteSync(recursive: true));

        final result = await Process.run(
          'flutter',
          ['build', 'windows', '--release'],
          workingDirectory: bogus.path,
          runInShell: true,
        );

        expect(result.exitCode, isNot(0));
      },
      skip: !Platform.isWindows
          ? 'Windows-only: needs Flutter Windows build tooling'
          : false,
    );
  });
}
