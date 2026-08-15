import 'dart:io';

import 'package:path/path.dart' as p;

/// Relative path from repo root to the demo app used as a test fixture.
const String fixtureAppPath = 'example/demo_app';

/// Expected release output of `flutter build windows --release` for the demo
/// app. This is version-independent of Inno Setup, so the cross-version
/// installer tests reuse one build of the app across every Inno version rather
/// than rebuilding Flutter per version.
String get demoAppReleaseExe => p.joinAll([
      fixtureAppPath,
      'build',
      'windows',
      'x64',
      'runner',
      'Release',
      'demo_app.exe',
    ]);

/// Builds the demo Flutter app once, no matter how many test files request it
/// or whether they run in parallel.
///
/// `dart test` runs each test file in its own isolate, so both
/// `app_build_test.dart` and `full_pipeline_cross_version_test.dart` can
/// trigger `flutter build windows` at the same time. Two concurrent builds into
/// the same `build/windows/x64` directory race inside CMake's MSBuild probe and
/// die with MSB3491 ("file is being used by another process"). The existence
/// check makes this idempotent; the exclusive lock serializes the
/// build-if-missing path across isolates and processes.
Future<void> ensureDemoAppBuilt({bool verbose = false}) async {
  if (File(demoAppReleaseExe).existsSync()) return;

  final lockFile = File(p.join(fixtureAppPath, 'build', '.demo_app.lock'));
  lockFile.parent.createSync(recursive: true);
  final lock = lockFile.openSync(mode: FileMode.write);
  try {
    await lock.lock(FileLock.blockingExclusive);
    try {
      if (File(demoAppReleaseExe).existsSync()) return;

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
        [
          'build',
          'windows',
          '--release',
          if (verbose) '-v',
        ],
        workingDirectory: fixtureAppPath,
        runInShell: true,
      );
      if (build.exitCode != 0) {
        final envDump = {
          'VSINSTALLDIR': Platform.environment['VSINSTALLDIR'],
          'VCToolsInstallDir': Platform.environment['VCToolsInstallDir'],
          'INCLUDE_set': Platform.environment['INCLUDE'] != null,
          'LIB_set': Platform.environment['LIB'] != null,
          'PATH_has_cl': (Platform.environment['PATH'] ?? '')
              .toLowerCase()
              .contains('vc\\tools'),
        };
        throw StateError(
          'flutter build windows failed (exit ${build.exitCode})\n'
          '--- env ---\n$envDump\n'
          '--- stdout ---\n${build.stdout}\n'
          '--- stderr ---\n${build.stderr}',
        );
      }
    } finally {
      await lock.unlock();
    }
  } finally {
    lock.closeSync();
  }
}
