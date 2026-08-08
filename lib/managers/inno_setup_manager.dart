import 'dart:io';

import 'package:inno_bundle/utils/constants.dart';
import 'package:inno_bundle/utils/functions.dart';
import 'package:path/path.dart' as p;

/// Manages multiple versioned Inno Setup installations under a single root
/// directory. Each version lives in its own subfolder (e.g. `<root>/6.3.3/`).
///
/// Use [ensureVersion] to download, verify, and extract a version if missing.
class InnoSetupManager {
  /// Root directory containing version-named subfolders.
  final String versionsDir;

  /// Creates a manager rooted at [versionsDir].
  ///
  /// If omitted, defaults to [innoManagedVersionsDir]
  /// (`$USERPROFILE/.inno_bundle/versions` on Windows).
  InnoSetupManager({String? versionsDir})
      : versionsDir = versionsDir ?? innoManagedVersionsDir;

  /// Returns the absolute path to `ISCC.exe` for [version], or `null` if that
  /// version is not yet installed.
  String? isccPath(String version) {
    final path = p.join(versionsDir, version, 'ISCC.exe');
    final file = File(path);
    return file.existsSync() ? file.absolute.path : null;
  }

  /// Lists every version subfolder under [versionsDir] that contains
  /// `ISCC.exe`.
  List<String> get installedVersions {
    return installedVersionedIsccs(versionsDir)
        .map((f) => p.basename(f.parent.path))
        .toList();
  }

  /// Ensures [version] is downloaded, checksum verified, and extracted.
  ///
  /// Returns `null` on success, or an error message describing the failure.
  /// Already-installed versions are silently skipped.
  Future<String?> ensureVersion(
    String version, {
    String? githubToken,
  }) async {
    if (isccPath(version) != null) return null;

    final versionTag = version.replaceAll('.', '_');
    final apiUrl = 'https://api.github.com'
        '/repos/jrsoftware/issrc/releases/tags/is-$versionTag';

    final releaseData = await fetchGitHubJson(
      apiUrl,
      githubToken: githubToken,
    );
    if (releaseData == null) {
      return 'Failed to fetch release info for version $version — '
              'check that the version exists.' +
          (githubToken == null
              ? ' Tip: set GITHUB_TOKEN (or GH_TOKEN) to avoid API rate limits.'
              : '');
    }

    // after Inno Setup 7 it started having 32-bit and 64-bit versions,
    // flutter only needs the 64-bit version.
    final isVersionEqualOrGreaterThan7 = version.compareTo('7.0.0') >= 0;
    final assetName =
        'innosetup-$version${isVersionEqualOrGreaterThan7 ? '-x64' : ''}.exe';
    final assets = releaseData['assets'] as List<dynamic>?;
    Map<String, dynamic>? asset;
    if (assets != null) {
      for (final a in assets) {
        if (a is Map<String, dynamic> && a['name'] == assetName) {
          asset = a;
          break;
        }
      }
    }
    if (asset == null) {
      return 'Asset $assetName not found for version $version.';
    }

    final downloadUrl = asset['browser_download_url'] as String;
    final digest = asset['digest'] as String;
    final expectedHash =
        digest.startsWith('sha256:') ? digest.substring(7) : digest;

    final tempDir = Directory.systemTemp;
    final installerPath = p.join(tempDir.path, assetName);

    final installerFileCached = await _tryUseCachedInstaller(
      installerPath,
      expectedHash,
    );
    if (!installerFileCached) {
      try {
        await downloadFile(downloadUrl, installerPath);
      } catch (e) {
        return 'Failed to download $version: $e';
      }

      final actualHash = await sha256HashFile(installerPath);
      if (actualHash == null ||
          actualHash.toLowerCase() != expectedHash.toLowerCase()) {
        File(installerPath).deleteSync();
        return 'Checksum mismatch for $version.\n'
            '  Expected: $expectedHash\n'
            '  Actual:   $actualHash';
      }
    }

    final dest = p.join(versionsDir, version);
    Directory(dest).createSync(recursive: true);

    final result = await Process.run(
        installerPath,
        [
          '/VERYSILENT',
          '/SUPPRESSMSGBOXES',
          '/NORESTART',
          '/CURRENTUSER',
          '/DIR=$dest',
        ],
        runInShell: true);

    File(installerPath).deleteSync();

    if (result.exitCode != 0) {
      return 'Installer for $version exited with code ${result.exitCode}.';
    }

    if (!File(p.join(dest, 'ISCC.exe')).existsSync()) {
      return 'ISCC.exe not found after extracting $version.';
    }

    return null;
  }

  /// Try to reuse a cached installer from a previous run if its checksum
  /// matches. Returns `true` when the cached file is valid.
  Future<bool> _tryUseCachedInstaller(String path, String expectedHash) async {
    final file = File(path);
    if (!file.existsSync()) return false;
    final hash = await sha256HashFile(path);
    if (hash != null && hash.toLowerCase() == expectedHash.toLowerCase()) {
      return true;
    }
    return false;
  }
}
