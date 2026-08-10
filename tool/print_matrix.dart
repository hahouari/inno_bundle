// ignore_for_file: avoid_print
import 'dart:io';

import 'package:inno_bundle/utils/functions.dart';

import '../test/support/inno_versions.dart';

/// Prints the canonical cross-version test matrix as a comma-separated string.
///
/// Used by `.github/workflows/cross-version.yml` to drive the Inno Setup
/// install step. The matrix is computed live from GitHub (see
/// `test/support/inno_versions.dart`): one entry per minor, the latest patch,
/// no betas, floored at 6.4.0.
///
/// On fetch failure, exits non-zero so the workflow can fall back to a
/// known-good pinned list defined directly in the YAML.
Future<void> main() async {
  try {
    final matrix = await fetchMatrixVersions(githubToken: gitHubToken);
    if (matrix.isEmpty) {
      stderr.writeln('matrix is empty under the configured floor/ceiling.');
      exit(1);
    }
    print(matrix.join(','));
  } on InnoMatrixFetchError catch (e) {
    stderr.writeln(e.message);
    exit(1);
  }
}
