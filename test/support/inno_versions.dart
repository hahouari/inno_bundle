/// Cross-version test support: discovers the canonical Inno Setup version
/// matrix from GitHub and helps tests loop over it.
///
/// The matrix rule (per the project owner's spec):
///   1. Only consider stable releases with a release asset whose name exactly
///      matches what [InnoVersionManager.ensureVersion] would download —
///      `innosetup-<v>.exe` for pre-7 versions, `innosetup-<v>-x64.exe` for
///      version >= 7.0.0. This naturally excludes beta/preview releases whose
///      assets are named like `innosetup-7.0.1-beta-x64.exe`.
///   2. From each ``major.minor`` group, keep only the highest patch.
///      A ``.0`` patch is NOT special: if `x.y.0` is the only (or highest)
///      patch of its minor, it is kept. The "drop the first" wording in the
///      original spec meant "don't test more than one patch per minor" —
///      `patches.last` does that by picking the latest.
///   3. Restrict to ``[floor, ceiling)`` — floor defaults to
///      [InnoVersionManager.minSupportedVersion] (6.4.0), ceiling to 8.0.0.
///
/// Today this yields ``['6.4.3', '6.5.4', '6.6.1', '6.7.3', '7.0.2']``.
library;

import 'dart:convert';
import 'dart:io';

import 'package:inno_bundle/managers/inno_version_manager.dart';
import 'package:inno_bundle/utils/functions.dart';

/// Pinned fallback matrix, used by `tool/print_matrix.dart --fallback` (and
/// therefore the cross-version workflow) when the live GitHub fetch is
/// unreachable or rate-limited. Updated manually when a new minor ships.
const fallbackMatrix = ['6.4.3', '6.5.4', '6.6.1', '6.7.3', '7.0.2', '7.1.0'];

/// Floor (inclusive) of the matrix minor range.
///
/// Defaults to [InnoVersionManager.minSupportedVersion] so the test matrix
/// never covers a version the package refuses to use. Tunable via the
/// `INNO_MATRIX_FLOOR` env var to widen/narrow coverage without editing code.
/// Must be a semver like `6.4.0`.
String get matrixFloor =>
    Platform.environment['INNO_MATRIX_FLOOR'] ??
    InnoVersionManager.minSupportedVersion;

/// Ceiling (exclusive) of the matrix minor range.
///
/// Tunable via the `INNO_MATRIX_CEILING` env var.
String get matrixCeiling =>
    Platform.environment['INNO_MATRIX_CEILING'] ?? '8.0.0';

/// Per-process cache of the fetched matrix so repeated [fetchMatrixVersions]
/// calls within one `dart test` run only hit GitHub once.
List<String>? _cachedMatrix;

/// Raised when the matrix cannot be fetched from GitHub.
///
/// Tests turn this into a *skip* with a helpful message rather than a failure,
/// because cross-version coverage is meaningless without network access.
class InnoMatrixFetchError implements Exception {
  final String message;
  InnoMatrixFetchError(this.message);
  @override
  String toString() => 'InnoMatrixFetchError: $message';
}

/// Selects, from a flat list of release version strings, one entry per
/// ``major.minor`` group: the highest patch of that minor.
///
/// Pure and synchronous — safe to unit-test without network access. Versions
/// are compared with [compareVersions]. Out-of-order and duplicate input is
/// tolerated. Patches are not assumed sorted; this function sorts them.
///
/// A ``.0`` patch is *not* special — if `x.y.0` is the highest (or only)
/// patch of its minor, it is kept. Only non-``x.y.z`` strings (betas,
/// previews) are dropped, and that happens via the regex filter below, not
/// here. Callers are expected to have already excluded betas before calling
/// (see [fetchMatrixVersions], which filters by asset-name match).
///
/// Example:
/// ```
/// latestPatchPerMinor(['6.4.0','6.4.1','6.4.2','6.4.3','6.5.0','6.5.4',
///                       '6.6.0','6.6.1','6.7.0','6.7.3','7.0.0','7.0.1','7.0.2'])
/// // => ['6.4.3','6.5.4','6.6.1','6.7.3','7.0.2']
/// ```
List<String> latestPatchPerMinor(List<String> versions) {
  final valid = <String>[];
  final _patchRegex = RegExp(r'^\d+\.\d+\.\d+$');
  for (final v in versions) {
    if (!_patchRegex.hasMatch(v)) continue; // skip betas/previews/odd shapes
    valid.add(v);
  }

  final byMinor = <String, List<String>>{};
  for (final v in valid) {
    final dot = v.indexOf('.');
    final dot2 = v.indexOf('.', dot + 1);
    final minorKey = v.substring(0, dot2);
    (byMinor[minorKey] ??= <String>[]).add(v);
  }

  final result = <String>[];
  final minorKeys = byMinor.keys.toList()
    ..sort((a, b) => compareVersions(a, b));
  for (final minorKey in minorKeys) {
    final patches = byMinor[minorKey]!..sort((a, b) => compareVersions(a, b));
    // Keep only the highest patch of this minor. A `.0` patch is NOT special:
    // if `x.y.0` is the only (or highest) patch, it wins for its minor.
    result.add(patches.last);
  }
  return result;
}

/// Returns `true` if [release] (a parsed GitHub release JSON object) should be
/// considered for the matrix: it must expose a non-prerelease with an asset
/// named exactly the way [InnoVersionManager.ensureVersion] constructs the
/// asset name for that version.
bool _hasMatchingAsset(Map<String, dynamic> release) {
  final tag = (release['tag_name'] as String?) ?? '';
  // tag looks like `is-6_4_3`
  final version =
      tag.startsWith('is-') ? tag.substring(3).replaceAll('_', '.') : null;
  if (version == null || !RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version)) {
    return false;
  }

  final isSevenPlus = version.compareTo('7.0.0') >= 0;
  final expected = 'innosetup-$version${isSevenPlus ? '-x64' : ''}.exe';
  final assets = release['assets'] as List<dynamic>?;
  if (assets == null) return false;
  for (final a in assets) {
    if (a is Map<String, dynamic> && a['name'] == expected) return true;
  }
  return false;
}

/// Fetches the canonical matrix of Inno Setup versions from GitHub, filtered
/// to the ``[floor, ceiling)`` range and reduced to one (latest) patch per
/// minor via [latestPatchPerMinor].
///
/// Results are cached per process. The GitHub token from [gitHubToken]
/// (env `GITHUB_TOKEN` || `GH_TOKEN`) is forwarded as a Bearer token to raise
/// the unauthenticated rate limit (60 req/hr -> 5000 req/hr).
///
/// Throws [InnoMatrixFetchError] with a user-facing hint when GitHub is
/// unreachable or rate-limited. Tests are expected to translate that into a
/// *skip*, never a failure.
Future<List<String>> fetchMatrixVersions({
  String? githubToken,
  String? floor,
  String? ceiling,
}) async {
  if (_cachedMatrix != null) return List.unmodifiable(_cachedMatrix!);

  final token = githubToken ?? gitHubToken;
  final lo = floor ?? matrixFloor;
  final hi = ceiling ?? matrixCeiling;

  final url = Uri.parse(
    'https://api.github.com/repos/jrsoftware/issrc/releases?per_page=100',
  );

  final client = HttpClient();
  try {
    final request = await client.getUrl(url);
    request.headers.set('User-Agent', 'inno_bundle');
    request.headers.set('Accept', 'application/json');
    if (token != null && token.isNotEmpty) {
      request.headers.set('Authorization', 'Bearer $token');
    }
    final response = await request.close();
    if (response.statusCode == 403 || response.statusCode == 429) {
      throw InnoMatrixFetchError(
        'GitHub rate-limited the matrix fetch (HTTP ${response.statusCode}). '
        'Set GITHUB_TOKEN (or GH_TOKEN) to avoid the limit.',
      );
    }
    if (response.statusCode != 200) {
      throw InnoMatrixFetchError(
        'Failed to fetch Inno Setup releases (HTTP ${response.statusCode}). '
        'Check your internet connection.',
      );
    }
    final body = await response.transform(utf8.decoder).join();
    final decoded = jsonDecode(body);
    if (decoded is! List) {
      throw InnoMatrixFetchError('Unexpected releases payload from GitHub.');
    }

    final versions = <String>[];
    for (final release in decoded) {
      if (release is! Map<String, dynamic>) continue;
      if (release['prerelease'] == true) continue;
      if (release['draft'] == true) continue;
      if (!_hasMatchingAsset(release)) continue;
      final tag = release['tag_name'] as String;
      final version = tag.substring(3).replaceAll('_', '.');
      versions.add(version);
    }

    final inRange = versions.where((v) {
      final ge = compareVersions(v, lo) >= 0;
      final lt = compareVersions(v, hi) < 0;
      return ge && lt;
    }).toList();

    final matrix = latestPatchPerMinor(inRange);
    _cachedMatrix = List.unmodifiable(matrix);
    return matrix;
  } on InnoMatrixFetchError {
    rethrow;
  } catch (e) {
    throw InnoMatrixFetchError(
      'Could not fetch the Inno Setup version matrix: $e\n'
      'Check your internet connection; set GITHUB_TOKEN (or GH_TOKEN) '
      'to avoid GitHub rate limits.',
    );
  } finally {
    client.close();
  }
}

/// Resets the process-wide matrix cache. Test-only.
void resetMatrixCacheForTest() => _cachedMatrix = null;
