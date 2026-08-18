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
/// On fetch failure: with `--fallback`, prints the pinned [fallbackMatrix]
/// instead and exits 0 (the reason goes to stderr); without it, exits
/// non-zero.
Future<void> main(List<String> args) async {
  final useFallback = args.contains('--fallback');
  String? matrix;
  String? error;
  try {
    final fetched = await fetchMatrixVersions(githubToken: gitHubToken);
    if (fetched.isEmpty) {
      error = 'matrix is empty under the configured floor/ceiling.';
    } else {
      matrix = fetched.join(',');
    }
  } on InnoMatrixFetchError catch (e) {
    error = e.message;
  }
  if (error != null) {
    stderr.writeln(error);
    if (!useFallback) {
      exit(1);
    }
    stderr
        .writeln('Falling back to pinned matrix ${fallbackMatrix.join(',')}.');
    matrix = fallbackMatrix.join(',');
  }
  // printing to stdout is the machine-readable return channel.
  print(matrix!);
}
