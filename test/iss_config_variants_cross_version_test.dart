import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:inno_bundle/builders/script_builder.dart';
import 'package:inno_bundle/models/cli_configs/inno_bundle_cli_config.dart';
import 'package:inno_bundle/models/config.dart';
import 'package:inno_bundle/models/language.dart';
import 'package:inno_bundle/utils/functions.dart';

import 'support/flutter_build.dart';
import 'support/inno_version_fixture.dart';

/// Cross-version compile coverage for config options the default demo config
/// does not exercise: `vc_redist: download` (a [Code] Pascal block),
/// `file_extensions_associations` (a [Registry] section) and the `admin`
/// variants. Each config is compiled by every installed matrix Inno version.
///
/// These are compile-only on purpose: the installer is never executed here.
/// Running an `admin`-mode installer requires elevation, which would pop UAC on
/// an interactive machine and hang on a headless CI runner. The run/install
/// stage is covered by `full_pipeline_cross_version_test.dart` with
/// `admin: auto` + `/CURRENTUSER` (per-user, no elevation).
Future<void> main() async {
  if (!Platform.isWindows) {
    group('ISS config variants against Inno versions', () {
      test('compile (SKIPPED — Windows-only)', () {},
          skip: 'Windows-only: needs a real Inno Setup install');
    });
    return;
  }

  final installed = await installedMatrixVersions();
  final skipReason = await skipReasonIfEmpty(installed);

  group('ISS config variants against Inno versions', () {
    if (installed.isEmpty) {
      test('compile (SKIPPED)', () {}, skip: skipReason);
      return;
    }

    const fullFixture = 'inno_bundle.full.yaml';

    for (final v in installed) {
      group('Inno ${v.version}', () {
        late Directory tempDir;
        late Directory appDir;
        late File innoExec;
        late Directory _origCwd;

        setUp(() {
          tempDir = Directory.systemTemp
              .createTempSync('inno_variants_${v.version}_');
          appDir = Directory(p.join(tempDir.path, 'app'))..createSync();
          File(p.join(appDir.path, 'demo_app.exe'))
              .writeAsBytesSync([0x4D, 0x5A, 0x90, 0x00]);
          innoExec = File(v.isccPath);
          Language.loadLanguages(v.isccPath);

          // Resolve installer_icon / license_file exactly as the CLI does when
          // run from `example/demo_app` (they are relative to the cwd).
          _origCwd = Directory.current;
          Directory.current = Directory(p.absolute(fixtureAppPath));
        });

        tearDown(() {
          Directory.current = _origCwd;
          if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
        });

        Config _config({Object? admin}) {
          final pubspecJson = readYaml(File('pubspec.yaml'));
          final configJson = readYaml(File(fullFixture));
          if (admin != null) {
            (configJson['inno_bundle'] as Map<String, dynamic>)['admin'] =
                admin;
          }
          return Config.fromJson(
            pubspecJson,
            configJson,
            cliConfig: InnoBundleCliConfig(),
            pubspecFile: File('pubspec.yaml'),
            configFile: File(fullFixture),
            outputDir: [tempDir.path, 'out'],
            innoExec: innoExec,
          );
        }

        Future<void> _assertCompiles(Config config, String label) async {
          final builder = ScriptBuilder(config, appDir);
          final scriptFile = File(p.join(tempDir.path, 'inno-script.iss'));
          scriptFile.writeAsStringSync(builder.buildScript());

          final result = await Process.run(
            innoExec.path,
            [scriptFile.path],
            runInShell: true,
            workingDirectory: tempDir.path,
          );
          expect(
            result.exitCode,
            0,
            reason: 'ISCC ${v.version} failed to compile the $label '
                'config.\n--- stdout ---\n${result.stdout}\n--- stderr '
                '---\n${result.stderr}',
          );
        }

        test('full config (vc_redist: download + file associations) compiles',
            () async {
          await _assertCompiles(_config(), 'full');
        });

        test('admin: true compiles (compile-only, never executed on CI)',
            () async {
          await _assertCompiles(_config(admin: true), 'admin: true');
        });

        test('admin: false compiles (compile-only, never executed on CI)',
            () async {
          await _assertCompiles(_config(admin: false), 'admin: false');
        });
      });
    }
  });
}
