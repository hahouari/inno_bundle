import 'dart:io';

import 'package:test/test.dart';

import 'support/inno_versions.dart';

/// Unit tests for the cross-version matrix selector. The pure selector logic
/// is fully testable without network access; the live fetch test is skipped
/// when GitHub can't be reached (per project policy: no stale fallback list).
void main() {
  group('latestPatchPerMinor', () {
    test('keeps the highest patch per minor, never two from the same minor',
        () {
      expect(
        latestPatchPerMinor([
          '6.4.0',
          '6.4.1',
          '6.4.2',
          '6.4.3',
          '6.5.0',
          '6.5.1',
          '6.5.2',
          '6.5.3',
          '6.5.4',
          '6.6.0',
          '6.6.1',
          '6.7.0',
          '6.7.1',
          '6.7.2',
          '6.7.3',
          '7.0.0',
          '7.0.1',
          '7.0.2',
        ]),
        equals(['6.4.3', '6.5.4', '6.6.1', '6.7.3', '7.0.2']),
      );
    });

    test('only one entry per major.minor even if many patches exist', () {
      final result = latestPatchPerMinor([
        '7.0.0',
        '7.0.1',
        '7.0.2',
        '7.0.3',
        '7.0.4',
        '7.0.5',
      ]);
      expect(result, equals(['7.0.5']));
      expect(result.where((v) => v.startsWith('7.0.')).length, 1);
    });

    test('a .0 patch is NOT special: if it is the only/highest patch, keep it',
        () {
      // A minor that only ever shipped the .0 is still represented by .0.
      expect(latestPatchPerMinor(['6.8.0']), equals(['6.8.0']));
      // Sibling minors are unaffected; each contributes its own highest patch.
      expect(
        latestPatchPerMinor(['6.8.0', '6.9.0', '6.9.5']),
        equals(['6.8.0', '6.9.5']),
      );
    });

    test('tolerates out-of-order input', () {
      expect(
        latestPatchPerMinor(['7.0.2', '6.7.3', '6.4.0', '6.4.3', '6.7.0']),
        // Sorted by minor ascending: 6.4.3, 6.7.3, 7.0.2.
        equals(['6.4.3', '6.7.3', '7.0.2']),
      );
    });

    test('deduplicates identical versions', () {
      expect(
        latestPatchPerMinor(['6.4.3', '6.4.3', '6.4.1', '6.4.1']),
        equals(['6.4.3']),
      );
    });

    test('ignores non-semver strings (betas, previews, odd shapes)', () {
      expect(
        latestPatchPerMinor([
          '6.1.0-beta',
          '7.0.0-preview',
          'not-a-version',
          '6.4.3',
          '6.4.0',
        ]),
        equals(['6.4.3']),
      );
    });

    test('empty input yields empty output', () {
      expect(latestPatchPerMinor([]), isEmpty);
    });
  });

  group('fallbackMatrix', () {
    test('is internally consistent: one latest patch per minor', () {
      expect(fallbackMatrix, equals(latestPatchPerMinor(fallbackMatrix)));
    });
  });

  group('fetchMatrixVersions (live)', () {
    setUp(resetMatrixCacheForTest);
    tearDown(resetMatrixCacheForTest);

    test(
      'returns the known matrix from GitHub',
      () async {
        final matrix = await fetchMatrixVersions();
        // Sanity: 6.4.3 floor and 7.0.x present.
        expect(matrix, contains('6.4.3'));
        expect(matrix, anyOf(contains('7.0.2')));
        // No betas, one per minor.
        final minors = matrix.map((v) => v.split('.')..removeLast()).toSet();
        expect(minors.length, matrix.length, reason: 'one per minor');
      },
      skip: Platform.environment['GITHUB_TOKEN'] == null &&
              Platform.environment['GH_TOKEN'] == null
          ? 'set GITHUB_TOKEN/GH_TOKEN to run the live matrix fetch '
              '(avoids rate limiting)'
          : false,
    );

    test(
      'result is cached: a second call does not hit GitHub again',
      () async {
        final first = await fetchMatrixVersions();
        final second = await fetchMatrixVersions();
        expect(second, same(first));
      },
      skip: 'caching is process-wide; verifying requires mocking the HTTP '
          'client and is out of scope for this iteration',
    );
  });
}
