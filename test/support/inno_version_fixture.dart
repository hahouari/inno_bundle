/// Cross-version test fixture: resolves which Inno Setup versions from the
/// canonical matrix are actually installed on this machine, and yields one
/// `(version, isccPath)` record per installed version for tests to loop over.
///
/// Versions that are in the matrix but not installed are *not* errored on;
/// tests that depend on them must be skipped with a clear message naming the
/// exact `setup_versions` command to install them. This keeps `dart test`
/// green on machines without any Inno installs (e.g. CI agents before
/// setup_versions has run, or non-Windows dev boxes).
library;

import 'package:inno_bundle/managers/inno_version_manager.dart';

import 'inno_versions.dart';

/// A versioned Inno Setup available on this machine for cross-version tests.
class InstalledInnoVersion {
  final String version;
  final String isccPath;
  const InstalledInnoVersion(this.version, this.isccPath);

  @override
  String toString() => 'Inno $version @ $isccPath';
}

/// Cached result for the lifetime of the test process.
List<InstalledInnoVersion>? _installed;

/// The canonical matrix filtered down to versions actually installed under
/// [InnoVersionManager.innoManagedVersionsDir].
///
/// Order follows the matrix (sorted ascending by version).
Future<List<InstalledInnoVersion>> installedMatrixVersions() async {
  if (_installed != null) return _installed!;

  final List<String> matrix;
  try {
    matrix = await fetchMatrixVersions();
  } on InnoMatrixFetchError {
    _installed = const [];
    return _installed!;
  }

  final manager = InnoVersionManager();
  final installed = manager.installedVersions;
  final installedSet = installed.toSet();
  final result = <InstalledInnoVersion>[];
  for (final v in matrix) {
    if (installedSet.contains(v)) {
      final iscc = manager.isccPath(v);
      if (iscc != null) result.add(InstalledInnoVersion(v, iscc));
    }
  }
  _installed = List.unmodifiable(result);
  return _installed!;
}

/// Returns a comma-joined string of the canonical matrix versions, suitable
/// for a `--versions` argument to `setup_versions`. Empty when the matrix
/// couldn't be fetched.
Future<String> matrixVersionsCsv() async {
  try {
    return (await fetchMatrixVersions()).join(',');
  } on InnoMatrixFetchError {
    return '';
  }
}

/// If [versions] is empty, returns a single human-readable skip reason naming
/// the command to run to populate
/// [InnoVersionManager.innoManagedVersionsDir]. Otherwise returns null.
Future<String?> skipReasonIfEmpty(List<InstalledInnoVersion> versions) async {
  if (versions.isNotEmpty) return null;
  // Distinguish "nothing installed" from "matrix fetch failed" so the skip
  // message stays actionable.
  final List<String> matrix;
  try {
    matrix = await fetchMatrixVersions();
  } on InnoMatrixFetchError catch (e) {
    return 'Skipped: ${e.message}';
  }
  if (matrix.isEmpty) {
    return 'Skipped: no Inno Setup versions in the matrix range '
        '[$matrixFloor, $matrixCeiling).';
  }
  final csv = matrix.join(',');
  return 'Skipped: no matrix Inno installs under '
      '"${InnoVersionManager.innoManagedVersionsDir}". Run:\n'
      '  dart run inno_bundle:setup_versions --versions $csv';
}

/// Reset cached installs between tests when the environment changes
/// (not normally needed; exported for completeness and tests).
void resetInstalledCacheForTest() => _installed = null;
