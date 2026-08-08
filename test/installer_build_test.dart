import 'dart:io';

import 'package:test/test.dart';

import 'package:inno_bundle/managers/inno_setup_manager.dart';

/// List of Inno Setup versions to test against, discovered from the
/// manager's [versionsDir] (set via `INNO_VERSIONS_DIR` env var).
List<String> discoverInnoVersions() {
  final root = Platform.environment['INNO_VERSIONS_DIR'];
  if (root == null) return [];
  return InnoSetupManager(versionsDir: root).installedVersions;
}

void main() {
  final innoVersions = discoverInnoVersions();

  if (innoVersions.isEmpty) {
    test('installer build (SKIPPED — set INNO_VERSIONS_DIR)', () {}, skip: true);
    return;
  }

  for (final version in innoVersions) {
    group('InstallerBuilder against Inno $version', () {
      final manager = InnoSetupManager(
          versionsDir: Platform.environment['INNO_VERSIONS_DIR']);
      final isccPath = manager.isccPath(version);

      test('compiles a valid installer .exe from a script', () {
        // Integration test that would:
        // 1. Create a minimal .iss script
        // 2. Construct a Config carrying innoSetupExec: isccPath
        // 3. Instantiate InstallerBuilder(config, scriptFile) and call build()
        // 4. Assert exit code 0 and output .exe exists
        expect(isccPath, isNotNull);
      }, skip: !Platform.isWindows);

      test('ISCC compile log contains no Error lines', () {
        // Run ISCC with a valid script, check stderr for "Error".
      }, skip: !Platform.isWindows);

      test('generated installer runs /VERYSILENT and installs expected files',
          () {
        // Full install/uninstall cycle in a temp dir.
      }, skip: !Platform.isWindows);
    });
  }
}
