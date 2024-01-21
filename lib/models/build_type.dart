import 'package:args/args.dart';
import 'package:inno_bundle/utils/functions.dart';

/// An enum representing the different build types supported for the software.
enum BuildType {
  debug,
  profile,
  release;

  /// Returns the directory name associated with the build type.
  String get dirName => capitalize(name);

  /// Parses the command-line arguments using [args] and determines the desired [BuildType].
  ///
  /// Prioritizes `release` over `profile` over `debug` if multiple flags are present.
  static BuildType fromArgs(ArgResults args) {
    return args[BuildType.release.name]
        ? BuildType.release
        : args[BuildType.profile.name]
            ? BuildType.profile
            : BuildType.debug;
  }
}
