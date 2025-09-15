/// Represents the tool used to build the Windows application.
library;

import 'package:args/args.dart';

/// Supported build tools.
enum BuildTool {
  /// Use Flutter CLI to build: `flutter build windows`.
  flutter,

  /// Use Shorebird CLI to build/release: `shorebird release windows`.
  shorebird;

  /// Parse from CLI args (expects an option named `build-tool`).
  static BuildTool fromArgs(ArgResults args) {
    final value = args['build-tool'] as String?;
    return fromOption(value);
  }

  /// Parse from a string option (e.g., from YAML), defaults to [BuildTool.flutter].
  static BuildTool fromOption(Object? option) {
    final s = option?.toString().toLowerCase().trim();
    switch (s) {
      case 'shorebird':
        return BuildTool.shorebird;
      case 'flutter':
      case null:
      case '':
        return BuildTool.flutter;
      default:
        return BuildTool.flutter;
    }
  }
}
