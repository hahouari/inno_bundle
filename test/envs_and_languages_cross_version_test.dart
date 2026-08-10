import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:inno_bundle/cli_args_parsers/inno_bundle_cli_args.dart';
import 'package:inno_bundle/models/config.dart';
import 'package:inno_bundle/models/language.dart';

import 'support/inno_version_fixture.dart';

/// Per-version "so on" coverage: verifies that
///  - `config.toEnvironmentVariables()` emits a stable, complete env-var set
///    across every matrix version — the same set `dart run inno_bundle --envs`
///    prints, asserted here directly against the pinned `innoExec` without
///    going through a CLI subprocess, and
///  - `Language.loadLanguages(<version>/ISCC.exe)` discovers the language
///    files that ship with each version (catches language-file churn between
///    6.4 and 7.0).
///
/// Windows-only: needs a real Inno Setup install on disk.
Future<void> main() async {
  if (!Platform.isWindows) {
    group('Envs & languages across Inno versions', () {
      test('envs & languages (SKIPPED — Windows-only)', () {},
          skip: 'Windows-only: needs Inno Setup on disk');
    });
    return;
  }

  final installed = await installedMatrixVersions();
  final skipReason = await skipReasonIfEmpty(installed);

  group('Envs & languages across Inno versions', () {
    if (installed.isEmpty) {
      test('envs & languages (SKIPPED)', () {}, skip: skipReason);
      return;
    }

    // The set of env-var keys `Config.toEnvironmentVariables()` is expected to
    // emit. Stable across Inno versions — keeping the assertion here means a
    // future refactor that drops/renames one will fail loudly per Inno version.
    const expectedEnvKeys = <String>{
      'APP_ID',
      'PUBSPEC_NAME',
      'CONFIG_FILE',
      'APP_NAME',
      'APP_NAME_CAMEL_CASE',
      'APP_DESCRIPTION',
      'APP_VERSION',
      'APP_PUBLISHER',
      'APP_URL',
      'APP_SUPPORT_URL',
      'APP_UPDATES_URL',
      'APP_INSTALLER_ICON',
      'APP_LANGUAGES',
      'APP_ADMIN',
      'APP_VCREDIST',
      'APP_TYPE',
      'APP_BUILD_APP',
      'APP_BUILD_INSTALLER',
    };

    for (final v in installed) {
      group('Inno ${v.version}', () {
        late Config config;

        setUp(() {
          // Load THIS version's languages first so `Config.fromJson` can
          // resolve `language` config values (default `Language.all` comes
          // from the loaded set).
          Language.loadLanguages(v.isccPath);

          // Pinned to THIS version's ISCC — no env override, no subprocess.
          config = Config.fromJson(
            {
              'name': 'demo_app',
              'description': 'A demo app.',
              'version': '1.0.0+1',
              'maintainer': 'Hocine Abdellatif Houari',
            },
            {
              'inno_bundle': {
                'id': '5ec949d0-0582-1e06-b073-b5d1161f6fff',
                'publisher': 'Hocine Abdellatif Houari',
                'admin': 'auto',
                'arch': 'x64_compatible',
              },
            },
            cliConfig: InnoBundleCliArgs(),
            pubspecFile: File('pubspec.yaml'),
            configFile: File('pubspec.yaml'),
            innoExec: File(v.isccPath),
          );
        });

        test('Language.loadLanguages discovers >= 1 language file', () {
          Language.loadLanguages(v.isccPath);
          final names = Language.all.map((l) => l.name).toSet();
          expect(names, contains('English'),
              reason: 'Every Inno release ships Default.isl (= English).');
          expect(names.length, greaterThanOrEqualTo(1));
          // Each declared language must point at a real .isl file inside this
          // exact version's install dir (catches version-specific churn).
          final innoDir = File(v.isccPath).parent;
          for (final lang in Language.all) {
            final f = File(p.join(innoDir.path, lang.file));
            expect(
              f.existsSync(),
              isTrue,
              reason: '${lang.file} missing for Inno ${v.version}',
            );
          }
        });

        test('toEnvironmentVariables() emits a stable, complete env-var set',
            () {
          final envs = config.toEnvironmentVariables();
          final keys = envs
              .split('\n')
              .where((l) => l.contains('='))
              .map((l) => l.substring(0, l.indexOf('=')).trim())
              .toSet();
          for (final key in expectedEnvKeys) {
            expect(
              keys,
              contains(key),
              reason:
                  'Missing env key $key in toEnvironmentVariables() for Inno ${v.version}',
            );
          }
        });
      });
    }
  });
}
