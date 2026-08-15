import 'dart:convert';
import 'dart:io';

import 'package:inno_bundle/utils/cli_logger.dart';
import 'package:inno_bundle/utils/functions.dart';
import 'package:path/path.dart' as p;

/// Manages multiple versioned Inno Setup installations under a single root
/// directory. Each version lives in its own subfolder (e.g. `<root>/6.3.3/`).
///
/// Use [ensureVersion] to download, verify, and extract a version if missing.
class InnoVersionManager {
  /// Root directory containing version-named subfolders.
  final String versionsDir;

  /// Minimum Inno Setup version (inclusive) this package supports.
  ///
  /// Versions below this floor found on disk — managed under
  /// [innoManagedVersionsDir] or a machine install — are treated as if they
  /// don't exist: never used for resolution and never deleted. [defaultVersion]
  /// must always be `>=` this value.
  static const String minSupportedVersion = '6.4.0';

  /// Default Inno Setup version used when no install is detected and one needs
  /// to be fetched through the version manager.
  static const String defaultVersion = '6.7.3';

  /// Root directory where the package manages its versioned Inno Setup installs
  /// (`~/.inno_bundle/versions`).
  static final String innoManagedVersionsDir = p.join(
    getHomeDir(),
    '.inno_bundle',
    'versions',
  );

  /// Inno Setup installation path when installed on the system level.
  static const innoSysDirPath = ["C:", "Program Files (x86)", "Inno Setup 6"];

  /// Inno Setup installation path when installed on user-specific level.
  static final innoUserDirPath = [
    getHomeDir(),
    "AppData",
    "Local",
    "Programs",
    "Inno Setup 6",
  ];

  /// GitHub link for documentation on how to download and install Inno Setup.
  static const innoDownloadStepLink =
      "https://github.com/hahouari/inno_bundle/wiki/Install-Inno-Setup";

  /// Creates a manager rooted at [versionsDir].
  ///
  /// If omitted, defaults to [innoManagedVersionsDir].
  InnoVersionManager({String? versionsDir})
      : versionsDir = versionsDir ?? innoManagedVersionsDir;

  /// Returns the absolute path to `ISCC.exe` for [version], or `null` if that
  /// version is not yet installed.
  String? isccPath(String version) {
    final path = p.join(versionsDir, version, 'ISCC.exe');
    final file = File(path);
    return file.existsSync() ? file.absolute.path : null;
  }

  /// The absolute path to `ISCC.exe` for [defaultVersion].
  ///
  /// Convenience for [isccPath]; asserts the default version is installed
  /// (callers ensure that beforehand).
  String get defaultIsccPath => isccPath(defaultVersion)!;

  /// Lists every version subfolder under [versionsDir] that contains
  /// `ISCC.exe` and is at least [minSupportedVersion].
  List<String> get installedVersions {
    return installedVersionedIsccs(versionsDir)
        .map((f) => p.basename(f.parent.path))
        .toList();
  }

  /// Locates a machine-wide or per-user install of Inno Setup (`ISCC.exe`).
  ///
  /// Checks the system directory ([innoSysDirPath]) then the user directory
  /// ([innoUserDirPath]). Installs whose reported version is below
  /// [minSupportedVersion] are treated as if they don't exist (left in place,
  /// never used). When [throwIfNotFound] is `true` (the default), prints a
  /// guidance link via [CliLogger] and exits if no usable install is found or
  /// it appears corrupted; otherwise returns `null`.
  static File? getMachineInnoExec({bool throwIfNotFound = true}) {
    if (!Directory(p.joinAll(innoSysDirPath)).existsSync() &&
        !Directory(p.joinAll(innoUserDirPath)).existsSync()) {
      if (throwIfNotFound) {
        CliLogger.exitError("Inno Setup 6 is not detected in your machine, "
            "checkout our docs on how to correctly install it:\n"
            "${CliLogger.sLink(innoDownloadStepLink, level: CliLoggerLevel.two)}");
      }
      return null;
    }

    final sysExecPath = p.joinAll([...innoSysDirPath, "ISCC.exe"]);
    final sysExecFile = File(sysExecPath);
    final userExecPath = p.joinAll([...innoUserDirPath, "ISCC.exe"]);
    final userExecFile = File(userExecPath);

    for (final exec in [sysExecFile, userExecFile]) {
      if (!exec.existsSync()) continue;
      final version = machineInnoVersion(exec);
      if (version != null &&
          compareVersions(version, minSupportedVersion) < 0) {
        if (throwIfNotFound) {
          CliLogger.exitError(
              "Detected Inno Setup $version on your machine, but inno_bundle "
              "supports $minSupportedVersion and newer. Install a supported "
              "version with `dart run inno_bundle:setup_versions` or check "
              "our docs:\n"
              "${CliLogger.sLink(innoDownloadStepLink, level: CliLoggerLevel.two)}");
        }
        continue;
      }
      return exec;
    }

    if (throwIfNotFound) {
      CliLogger.exitError(
          "Inno Setup installation in your machine is corrupted "
          "or incomplete, checkout our docs on how to correctly install it:\n"
          "${CliLogger.sLink(innoDownloadStepLink, level: CliLoggerLevel.two)}");
    }
    return null;
  }

  /// Returns the Inno Setup version reported by [isccExe], or `null` when it
  /// can't be determined. ISCC prints a `Version x.y.z` banner on startup.
  ///
  /// A detection failure returns `null` and is treated as "version unknown",
  /// which does not block the install (only a positively-identified below-floor
  /// version is skipped).
  static String? machineInnoVersion(File isccExe) {
    try {
      final result = Process.runSync(isccExe.path, const []);
      final output = '${result.stdout}${result.stderr}';
      return RegExp(r'Version\s+(\d+\.\d+\.\d+)').firstMatch(output)?.group(1);
    } catch (_) {
      return null;
    }
  }

  /// Returns the `ISCC.exe` of every version managed under [versionsDir]
  /// (defaults to [innoManagedVersionsDir]) that is at least
  /// [minSupportedVersion], sorted by version in descending order (highest
  /// first). Below-floor versions on disk are left untouched but ignored.
  static List<File> installedVersionedIsccs([String? versionsDir]) {
    final dir = Directory(versionsDir ?? innoManagedVersionsDir);
    if (!dir.existsSync()) return [];

    final isccs = <File>[];
    for (final entry in dir.listSync().whereType<Directory>()) {
      final iscc = File(p.join(entry.path, 'ISCC.exe'));
      if (!iscc.existsSync()) continue;
      final version = p.basename(entry.path);
      if (compareVersions(version, minSupportedVersion) < 0) continue;
      isccs.add(iscc);
    }

    isccs.sort((a, b) {
      final cmp = compareVersions(
        p.basename(a.parent.path),
        p.basename(b.parent.path),
      );
      return cmp == 0 ? 0 : -cmp;
    });
    return isccs;
  }

  /// Resolves the Inno Setup executable to use, or `null` when none is present.
  ///
  /// Prefers a version-managed silent install under [innoManagedVersionsDir]
  /// (highest version first), then falls back to a system/user installed Inno
  /// Setup (e.g. installed separately by the user). It does not trigger any
  /// installation here.
  static File? resolveInnoExec() {
    final versioned = installedVersionedIsccs();
    if (versioned.isNotEmpty) return versioned.first;
    return getMachineInnoExec(throwIfNotFound: false);
  }

  /// Fetches GitHub release data from [url] and returns the parsed JSON map.
  ///
  /// If [githubToken] is provided, it is sent as a Bearer token in the
  /// `Authorization` header (used to raise GitHub API rate limits).
  /// Returns `null` on any HTTP error or parse failure.
  static Future<Map<String, dynamic>?> fetchGitHubReleaseData(
    String url, {
    String? githubToken,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set('User-Agent', 'inno_bundle');
      request.headers.set('Accept', 'application/json');
      if (githubToken != null && githubToken.isNotEmpty) {
        request.headers.set('Authorization', 'Bearer $githubToken');
      }
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != 200) return null;
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  /// Downloads a file from [url] and writes it to [destPath].
  ///
  /// Throws an [HttpException] if the server returns a non-200 status code.
  static Future<void> downloadFile(String url, String destPath) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse(url));
      request.headers.set('User-Agent', 'inno_bundle');
      final response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}');
      }
      final file = File(destPath);
      final sink = file.openWrite();
      await response.pipe(sink);
      await sink.close();
    } finally {
      client.close();
    }
  }

  /// Ensures [defaultVersion] is downloaded, checksum verified, and extracted.
  ///
  /// Convenience wrapper around [ensureVersion]; returns `null` on success, or
  /// an error message describing the failure. Already-installed versions are
  /// silently skipped.
  Future<String?> ensureDefaultVersion({String? githubToken}) =>
      ensureVersion(defaultVersion, githubToken: githubToken);

  /// Ensures [version] is downloaded, checksum verified, and extracted.
  ///
  /// Returns `null` on success, or an error message describing the failure.
  /// Already-installed versions are silently skipped.
  Future<String?> ensureVersion(
    String version, {
    String? githubToken,
  }) async {
    if (compareVersions(version, minSupportedVersion) < 0) {
      return 'Inno Setup $version is below the minimum supported version '
          '($minSupportedVersion) of inno_bundle and would never be used. '
          'Install $minSupportedVersion or newer.';
    }

    if (isccPath(version) != null) return null;

    final versionTag = version.replaceAll('.', '_');
    final apiUrl = 'https://api.github.com'
        '/repos/jrsoftware/issrc/releases/tags/is-$versionTag';

    final releaseData = await fetchGitHubReleaseData(
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
