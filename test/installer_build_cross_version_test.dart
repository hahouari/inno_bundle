import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:inno_bundle/builders/script_builder.dart';
import 'package:inno_bundle/cli_args_parsers/inno_bundle_cli_args.dart';
import 'package:inno_bundle/models/config.dart';
import 'package:inno_bundle/models/language.dart';
import 'package:inno_bundle/utils/functions.dart';

import 'support/inno_version_fixture.dart';

/// Cross-version installer build test: for each installed matrix Inno Setup
/// version, generate the `.iss` from a fake app dir and let that version's
/// `ISCC.exe` produce a real `Setup.exe`, asserting the artifact exists and is
/// named exactly like the package would name it
/// (`<camelName>-<cpu>-<version>-Installer.exe`).
///
/// We call `ISCC` directly (rather than `InstallerBuilder.build()`) because
/// `InstallerBuilder` calls `exit()` on compile failure, which would terminate
/// the whole test runner. Mirroring the compile step here keeps the runner
/// alive and surfaces the failure as a normal assertion.
///
/// The Flutter app itself is version-independent and is NOT rebuilt here —
/// this test focuses purely on the installer stage. See `app_build_test.dart`
/// for the app-build stage (shared across versions).
Future<void> main() async {
  if (!Platform.isWindows) {
    group('InstallerBuilder against Inno versions', () {
      test('installer build (SKIPPED — Windows-only)', () {},
          skip: 'Windows-only: needs Inno Setup ISCC.exe');
    });
    return;
  }

  final installed = await installedMatrixVersions();
  final skipReason = await skipReasonIfEmpty(installed);

  group('InstallerBuilder against Inno versions', () {
    if (installed.isEmpty) {
      test('installer build (SKIPPED)', () {}, skip: skipReason);
      return;
    }

    for (final v in installed) {
      group('Inno ${v.version}', () {
        late Directory tempDir;
        late Directory appDir;
        late File innoExec;
        late Config config;

        setUp(() {
          tempDir = Directory.systemTemp
              .createTempSync('inno_installer_${v.version}_');
          appDir = Directory(p.join(tempDir.path, 'app'))..createSync();
          File(p.join(appDir.path, 'demo_app.exe'))
              .writeAsBytesSync([0x4D, 0x5A, 0x90, 0x00]);
          final dataDir = Directory(p.join(appDir.path, 'data'))..createSync();
          File(p.join(dataDir.path, 'asset.txt')).writeAsStringSync('hi');

          innoExec = File(v.isccPath);
          // Load THIS version's languages so the [Languages] section references
          // files that ship with that exact ISCC install.
          Language.loadLanguages(v.isccPath);

          // Use an absolute outputDir so the [Setup] OutputDir= lands in our
          // temp dir regardless of the Dart process's current directory.
          config = Config.fromJson(
            {
              'name': 'demo_app',
              'description': 'A test app.',
              'version': '1.0.0',
              'maintainer': 'Test User',
            },
            {
              'inno_bundle': {
                'id': '5ec949d0-0582-1e06-b073-b5d1161f6fff',
              },
            },
            cliConfig: InnoBundleCliArgs(),
            pubspecFile: File(''),
            configFile: File(''),
            outputDir: [tempDir.path, 'out'],
            innoExec: innoExec,
          );
        });

        tearDown(() {
          if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
        });

        test('produces the named installer .exe with exit 0', () async {
          // Generate the script exactly as the CLI does (writes into the
          // absolute outputDir under <type.dirName>/inno-script.iss).
          final scriptFile = await ScriptBuilder(config, appDir).build();

          final result = await Process.run(
            innoExec.path,
            [scriptFile.path],
            runInShell: true,
            workingDirectory: tempDir.path,
          );

          expect(
            result.exitCode,
            0,
            reason: 'Inno ${v.version} failed to build the installer.\n'
                '--- stdout ---\n${result.stdout}\n--- stderr ---\n${result.stderr}',
          );

          final expectedName =
              '${camelCase(config.name)}-${config.arch.cpu}-${config.version}-Installer.exe';
          final produced = File(
            p.joinAll([
              tempDir.path,
              'out',
              config.type.dirName,
              expectedName,
            ]),
          );
          expect(
            produced.existsSync(),
            isTrue,
            reason: 'Inno ${v.version} compiled successfully but did not emit '
                '$expectedName.\nwork dir: ${tempDir.path}',
          );
          expect(produced.lengthSync(), greaterThan(0));
        });
      });
    }
  });
}
