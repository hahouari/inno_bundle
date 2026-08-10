import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:inno_bundle/builders/app_builder.dart';
import 'package:inno_bundle/cli_args_parsers/inno_bundle_cli_args.dart';
import 'package:inno_bundle/models/config.dart';

import 'support/language_fixture.dart';

/// Relative path from repo root to the demo app used as a test fixture.
const fixtureAppPath = 'example/demo_app';

/// Expected release output of `flutter build windows --release` for the demo
/// app. This is version-independent of Inno Setup, so the cross-version
/// installer tests (`installer_build_cross_version_test.dart`,
/// `full_pipeline_cross_version_test.dart`) build the app **once** (here, or
/// in `setUpAll`) and reuse the produced runner directory across every Inno
/// version rather than rebuilding Flutter per version.
String get demoAppReleaseExe => p.joinAll([
      fixtureAppPath,
      'build',
      'windows',
      'x64',
      'runner',
      'Release',
      'demo_app.exe',
    ]);

void main() {
  initTestLanguages();
  group('AppBuilder', () {
    test('accepts a Flutter project config without throwing', () {
      final config = Config.fromJson(
        {'name': 'x', 'description': 'x', 'version': '1.0', 'maintainer': 'x'},
        {
          'inno_bundle': {'id': '5ec949d0-0582-1e06-b073-b5d1161f6fff'}
        },
        cliConfig: InnoBundleCliArgs(),
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
        // Ensure deps before building (idempotent; no-op if already resolved).
        final pubGet = await Process.run(
          'flutter',
          ['pub', 'get'],
          workingDirectory: fixtureAppPath,
          runInShell: true,
        );
        expect(
          pubGet.exitCode,
          0,
          reason: '`flutter pub get` failed for $fixtureAppPath:\n'
              '${pubGet.stdout}\n${pubGet.stderr}',
        );

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
          cliConfig: InnoBundleCliArgs(),
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
        // rebuilding Flutter per Inno version.
        await Process.run(
          'flutter',
          [
            'build',
            'windows',
            '--release',
          ],
          workingDirectory: fixtureAppPath,
          runInShell: true,
        );

        expect(
          File(demoAppReleaseExe).existsSync(),
          isTrue,
          reason: 'Expected release exe not found at $demoAppReleaseExe.',
        );
      },
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
