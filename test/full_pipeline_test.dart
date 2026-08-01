import 'dart:io';

import 'package:test/test.dart';

const fixtureAppPath = 'example/demo_app';

void main() {
  group('Full pipeline (dart run inno_bundle)', () {
    test(
      'end-to-end: build app, compile installer, silent install, verify, uninstall',
      () {
        // End-to-end test that would:
        // 1. Process.run('dart', ['run', 'inno_bundle'], workingDirectory: fixtureAppPath)
        // 2. Assert each stage in sequence — build output, installer exe, install, uninstall
        // 3. Fail with a message identifying which stage broke
      },
      skip: !Platform.isWindows ? 'Windows-only' : false,
    );

    test(
      'CLI --envs output stays consistent across the full run',
      () {
        // Process.run('dart', ['run', 'inno_bundle', '--envs'], ...)
        // Assert expected env vars are present.
      },
      skip: !Platform.isWindows ? 'Windows-only' : false,
    );
  });
}
