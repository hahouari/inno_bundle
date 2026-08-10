import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:inno_bundle/builders/script_builder.dart';
import 'package:inno_bundle/cli_args_parsers/inno_bundle_cli_args.dart';
import 'package:inno_bundle/models/config.dart';
import 'package:inno_bundle/models/language.dart';

import 'support/inno_version_fixture.dart';

/// Cross-version ISS compile test: generates `inno_bundle`'s real `.iss`
/// output and asks each installed matrix Inno Setup version to compile it.
///
/// This is the single most valuable cross-version test: every directive the
/// generated script uses - `WizardStyle=modern`, `{autopf}`,
/// `ArchitecturesInstallIn64BitMode=x64compatible`, the `[Code]` Pascal
/// block - is exercised here and would surface a regression on any version
/// that dropped/renamed one of them.
Future<void> main() async {
  if (!Platform.isWindows) {
    group('.iss compiles against each Inno Setup version', () {
      test('ISCC compile (SKIPPED — Windows-only)', () {},
          skip: 'Windows-only: needs a real Inno Setup install');
    });
    return;
  }

  // Await discovery at the top level so per-version groups can be registered
  // synchronously for each discovered version.
  final installed = await installedMatrixVersions();
  final skipReason = await skipReasonIfEmpty(installed);

  group('.iss compiles against each Inno Setup version', () {
    if (installed.isEmpty) {
      test('ISCC compile (SKIPPED)', () {}, skip: skipReason);
      return;
    }

    for (final v in installed) {
      group('Inno ${v.version}', () {
        late Directory tempDir;
        late Directory appDir;
        late Directory outDir;
        late File scriptFile;
        late File innoExec;
        late Config config;

        setUp(() {
          tempDir =
              Directory.systemTemp.createTempSync('inno_compile_${v.version}_');
          // A tiny fake app dir mirroring what the package expects: top-level
          // files plus directories.
          appDir = Directory(p.join(tempDir.path, 'app'))..createSync();
          File(p.join(appDir.path, 'my_app.exe'))
              .writeAsBytesSync([0x4D, 0x5A, 0x90, 0x00]);
          final dataDir = Directory(p.join(appDir.path, 'data'))..createSync();
          File(p.join(dataDir.path, 'asset.txt')).writeAsStringSync('hi');
          outDir = Directory(p.join(tempDir.path, 'out'))..createSync();

          innoExec = File(v.isccPath);
          // Load THIS version's languages so the [Languages] section
          // references language files that exist for that exact ISCC install.
          Language.loadLanguages(v.isccPath);

          config = Config.fromJson(
            {
              'name': 'my_app',
              'description': 'A test app.',
              'version': '1.0.0',
              'maintainer': 'Test User',
            },
            {
              'inno_bundle': {
                'id': '5ec949d0-0582-1e06-b073-b5d1161f6fff',
                'publisher': 'Test User',
                'admin': 'auto',
                'arch': 'x64_compatible',
              },
            },
            cliConfig: InnoBundleCliArgs(),
            pubspecFile: File(''),
            configFile: File(''),
            outputDir: [outDir.path],
            innoExec: innoExec,
          );
        });

        tearDown(() {
          if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
        });

        test('ISCC compiles the generated script with exit 0', () async {
          final builder = ScriptBuilder(config, appDir);
          final scriptContent = builder.buildScript();
          scriptFile = File(p.join(tempDir.path, 'inno-script.iss'));
          scriptFile.writeAsStringSync(scriptContent);

          final result = await Process.run(
            innoExec.path,
            [scriptFile.path],
            runInShell: true,
            workingDirectory: tempDir.path,
          );

          expect(
            result.exitCode,
            0,
            reason: 'ISCC ${v.version} failed to compile the generated '
                'script.\n--- stdout ---\n${result.stdout}\n--- stderr '
                '---\n${result.stderr}',
          );

          final combined = '${result.stdout}\n${result.stderr}';
          expect(
            combined,
            isNot(contains(RegExp(r'(^|\n)\s*Error'))),
            reason: 'ISCC ${v.version} output contained "Error":\n$combined',
          );
        });
      });
    }
  });
}
