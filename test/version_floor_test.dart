import 'dart:io';

import 'package:inno_bundle/managers/inno_version_manager.dart';
import 'package:inno_bundle/utils/functions.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Unit tests for the minimum supported Inno Setup version floor: versions
/// below [InnoVersionManager.minSupportedVersion] found on disk must be
/// ignored (never used, never deleted) and never installed on request.
void main() {
  group('InnoVersionManager version floor', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('inno_bundle_floor_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    void seedVersion(String version) {
      final dir = Directory(p.join(tempDir.path, version))
        ..createSync(recursive: true);
      File(p.join(dir.path, 'ISCC.exe')).writeAsStringSync('fake');
    }

    test('defaultVersion is at or above minSupportedVersion', () {
      expect(
        compareVersions(
          InnoVersionManager.defaultVersion,
          InnoVersionManager.minSupportedVersion,
        ),
        greaterThanOrEqualTo(0),
      );
    });

    test(
        'installedVersionedIsccs skips below-floor versions without deleting them',
        () {
      seedVersion('6.3.3');
      seedVersion('6.4.0');
      seedVersion('6.5.4');

      final isccs = InnoVersionManager.installedVersionedIsccs(tempDir.path);

      expect(
        isccs.map((f) => p.basename(f.parent.path)).toList(),
        ['6.5.4', '6.4.0'],
      );
      expect(
        Directory(p.join(tempDir.path, '6.3.3')).existsSync(),
        isTrue,
        reason: 'below-floor versions must be left untouched on disk',
      );
    });

    test('installedVersions getter reflects the floor', () {
      seedVersion('6.3.3');
      seedVersion('6.5.4');

      final manager = InnoVersionManager(versionsDir: tempDir.path);
      expect(manager.installedVersions, ['6.5.4']);
    });

    test('ensureVersion refuses a below-floor version without hitting network',
        () async {
      final error = await InnoVersionManager(versionsDir: tempDir.path)
          .ensureVersion('6.3.3');
      expect(error, contains(InnoVersionManager.minSupportedVersion));
    });
  });
}
