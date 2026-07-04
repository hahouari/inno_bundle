/// Represents the different build types supported for the software.
///
/// This enum provides three build types:
/// - [release]: Represents a build type optimized for release to users.
/// - [profile]: Represents a build type that allows profiling performance.
/// - [debug]: Represents a build type optimized for debugging.
///
/// The [dirName] getter returns the capitalized directory name associated with each build type.
///
/// The [fromArgs] static method parses command-line arguments using [ArgResults] and
/// determines the desired [BuildType]. If multiple flags are present, it prioritizes
/// `release` over `profile` over `debug`.
///
/// Example usage:
/// ```dart
/// var buildType = BuildType.fromArgs(argResults);
/// print('Selected build type: ${buildType.dirName}');
/// ```
library;

import 'package:args/args.dart';
import 'package:inno_bundle/utils/functions.dart';

/// An enum representing the different build types supported for the software.
enum BuildType {
  release,
  profile,
  debug;

  /// Returns the directory name associated with the build type.
  String get dirName => capitalize(name);

  /// Parses the command-line arguments using [args] and determines the desired [BuildType].
  ///
  /// Prioritizes `release` over `profile` over `debug` if multiple flags are present.
  static BuildType fromArgs(ArgResults args) {
    return args[debug.name]
        ? debug
        : args[profile.name]
            ? profile
            : release;
  }
}
