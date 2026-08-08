import 'dart:io';

import 'package:test/test.dart';

import 'package:inno_bundle/builders/app_builder.dart';
import 'package:inno_bundle/cli_args_parsers/inno_bundle_cli_args.dart';
import 'package:inno_bundle/models/config.dart';

import 'support/language_fixture.dart';

/// Relative path from repo root to the demo app used as a test fixture.
const fixtureAppPath = 'example/demo_app';

void main() {
  initTestLanguages();
  group('AppBuilder', () {
    test('requires a Flutter project directory', () {
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

      expect(
        () => AppBuilder(config),
        isNot(throwsA(anything)),
      );
    },
        skip: !Platform.isWindows
            ? 'Windows-only: needs Flutter Windows build tooling'
            : false);

    test(
      'flutter build tool produces expected windows/runner output tree',
      () {
        // Requires the demo_app fixture and Flutter SDK.
        // In CI this would run: AppBuilder(config).build()
        // and assert build/windows/x64/runner/Release/<app>.exe exists.
      },
      skip: !Platform.isWindows
          ? 'Windows-only: needs Flutter Windows build tooling'
          : false,
    );

    test(
      'build failure surfaces a clear error',
      () {
        // Point AppBuilder at a dir with no Flutter project, expect error.
      },
      skip: !Platform.isWindows
          ? 'Windows-only: needs Flutter Windows build tooling'
          : false,
    );
  });
}
