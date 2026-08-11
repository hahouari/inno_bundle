import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:inno_bundle/builders/script_builder.dart';
import 'package:inno_bundle/models/cli_configs/inno_bundle_cli_config.dart';
import 'package:inno_bundle/models/config.dart';
import 'package:inno_bundle/models/language.dart';
import 'package:inno_bundle/utils/functions.dart';

import 'support/inno_version_fixture.dart';

/// Full pipeline cross-version test: per matrix Inno Setup version, build the
/// demo Flutter app **once** (in [setUpAll]), generate the `.iss` with that
/// version's `ISCC.exe` baked into the config, compile the installer, then run
/// a real silent install -> verify -> uninstall cycle against it.
///
/// This is the top of the testing pyramid: it surfaces any end-to-end
/// breakage introduced by a feature change against any of the supported Inno
/// versions. Windows-only (needs Flutter, a real Inno Setup install, and the
/// generated Setup.exe's execute permission is Windows-only).
const fixtureAppPath = 'example/demo_app';

String get demoAppReleaseDir => p.normalize(p.absolute(
      p.joinAll(
          [fixtureAppPath, 'build', 'windows', 'x64', 'runner', 'Release']),
    ));

Future<Directory> _buildDemoAppOnce() async {
  final pubGet = await Process.run(
    'flutter',
    ['pub', 'get'],
    workingDirectory: fixtureAppPath,
    runInShell: true,
  );
  if (pubGet.exitCode != 0) {
    throw StateError('flutter pub get failed:\n${pubGet.stderr}');
  }
  final build = await Process.run(
    'flutter',
    ['build', 'windows', '--release'],
    workingDirectory: fixtureAppPath,
    runInShell: true,
  );
  if (build.exitCode != 0) {
    throw StateError('flutter build windows failed:\n${build.stderr}');
  }
  return Directory(demoAppReleaseDir);
}

Future<void> main() async {
  if (!Platform.isWindows) {
    group('Full pipeline (dart run inno_bundle)', () {
      test('end-to-end (SKIPPED — Windows-only)', () {},
          skip: 'Windows-only: needs Flutter + Inno Setup');
    });
    return;
  }

  // Discover installed matrix versions *before* triggering a Flutter build so
  // we skip the ~30s app build entirely when there's nothing to test (avoids
  // wasted work on a fresh Windows box without `setup_versions` having run,
  // and removes the only reason an env-var gate ever seemed necessary).
  final installed = await installedMatrixVersions();
  final skipReason = await skipReasonIfEmpty(installed);

  if (installed.isEmpty) {
    group('Full pipeline (dart run inno_bundle)', () {
      test('end-to-end (SKIPPED)', () {}, skip: skipReason);
    });
    return;
  }

  // Built once and shared across every Inno version (the Flutter build does
  // not depend on the Inno version chosen).
  late final Directory appDir;
  setUpAll(() async {
    appDir = await _buildDemoAppOnce();
  });

  group('Full pipeline (dart run inno_bundle)', () {
    for (final v in installed) {
      group('Inno ${v.version}', () {
        late Directory tempDir;
        late Directory installDir;
        late File innoExec;
        late Config config;
        // Saved so the test can run from the demo app's dir (the installer
        // icon + license file paths in its pubspec are resolved against the
        // cwd, exactly like `dart run inno_bundle` run from the app dir) and
        // restore it afterward so other tests aren't affected.
        late Directory _origCwd;

        setUp(() {
          tempDir = Directory.systemTemp
              .createTempSync('inno_pipeline_${v.version}_');
          // `out` is created as needed by ISCC; no need to pre-create it.
          installDir = Directory(p.join(tempDir.path, 'install'))..createSync();
          innoExec = File(v.isccPath);
          Language.loadLanguages(v.isccPath);

          // Resolve installer_icon / license_file / etc. exactly as the CLI
          // does when run from `example/demo_app`; absolute outputDir keeps
          // ISCC's `OutputDir=` and the generated script inside the temp dir.
          _origCwd = Directory.current;
          Directory.current = Directory(p.absolute(fixtureAppPath));
          // cwd is now the demo app dir, so `pubspec.yaml` resolves here —
          // matching the path `dart run inno_bundle` uses inside the app.
          final pubspecFile = File('pubspec.yaml');
          config = Config.fromFile(
            pubspecFile,
            pubspecFile,
            innoExec,
            InnoBundleCliConfig(),
            outputDir: [tempDir.path, 'out'],
          );
        });

        tearDown(() {
          Directory.current = _origCwd;
          if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
        });

        test(
            'end-to-end: build app, compile installer, silent install, verify, uninstall',
            () async {
          // 1. Generate + compile the installer with THIS Inno version.
          final scriptFile = await ScriptBuilder(config, appDir).build();
          final compiled = await Process.run(
            innoExec.path,
            [scriptFile.path],
            runInShell: true,
            workingDirectory: tempDir.path,
          );
          expect(
            compiled.exitCode,
            0,
            reason: 'Inno ${v.version} could not compile the installer.\n'
                '--- stdout ---\n${compiled.stdout}\n--- stderr ---\n${compiled.stderr}',
          );

          final expectedName =
              '${camelCase(config.name)}-${config.arch.cpu}-${config.version}-Installer.exe';
          final installerExe = File(
            p.joinAll([tempDir.path, 'out', config.type.dirName, expectedName]),
          );
          expect(installerExe.existsSync(), isTrue,
              reason: 'Installer .exe missing: $expectedName');

          // 2. Silent install into the temp install dir.
          final install = await Process.run(
            installerExe.path,
            [
              '/VERYSILENT',
              '/SUPPRESSMSGBOXES',
              '/NORESTART',
              '/CURRENTUSER',
              '/DIR=${installDir.path}',
            ],
            runInShell: true,
          );
          expect(
            install.exitCode,
            0,
            reason: 'Installer under Inno ${v.version} failed silent '
                'install.\n${install.stdout}\n${install.stderr}',
          );

          // 3. Verify expected files landed.
          expect(
            File(p.join(installDir.path, 'demo_app.exe')).existsSync(),
            isTrue,
            reason: 'demo_app.exe not installed by Inno ${v.version} run.',
          );
          final unins000 = File(p.join(installDir.path, 'unins000.exe'));
          expect(unins000.existsSync(), isTrue,
              reason: 'uninstaller not created by Inno ${v.version} run.');

          // 4. Silent uninstall. Pass `/CURRENTUSER` for symmetry with the install —
          // the real demo app config sets `admin: auto`, so the uninstaller
          // honors the override and runs per-user (no UAC). Without it Inno
          // falls back to the dialog (admin) path and pops UAC.
          final uninstall = await Process.run(
            unins000.path,
            ['/VERYSILENT', '/SUPPRESSMSGBOXES', '/NORESTART', '/CURRENTUSER'],
            runInShell: true,
          );
          expect(
            uninstall.exitCode,
            0,
            reason: 'Uninstaller under Inno ${v.version} failed.\n'
                '${uninstall.stdout}\n${uninstall.stderr}',
          );

          // 5. Verify cleanup. Inno's uninstaller deletes `unins000.exe` via a
          // self-spawned temp copy *after* the main process exits, so poll
          // briefly for the install dir to become empty. If it never empties,
          // fail loudly naming the leftover files instead of a bare boolean.
          var cleaned = false;
          for (var i = 0; i < 10; i++) {
            if (!installDir.existsSync() || installDir.listSync().isEmpty) {
              cleaned = true;
              break;
            }
            await Future<void>.delayed(const Duration(milliseconds: 200));
          }
          if (!cleaned) {
            final leftover =
                installDir.listSync().map((e) => p.basename(e.path)).join(', ');
            fail('Install dir not cleaned by Inno ${v.version} uninstall. '
                'Leftover: $leftover');
          }
        });

        test('config.toEnvironmentVariables() emits a stable env-var set', () {
          // Assert the version-pinned config produces a complete, stable
          // env-var set per Inno version — no subprocess/cwd/env isolation.
          final envs = config.toEnvironmentVariables();
          expect(envs, contains('APP_ID='));
          expect(envs, contains('APP_NAME=demo_app'));
          expect(envs, contains('APP_VERSION=1.0.0'));
          expect(envs, contains('APP_PUBLISHER=Hocine Abdellatif Houari'));
          expect(envs, contains('APP_BUILD_INSTALLER=true'));
        });
      });
    }
  });
}
