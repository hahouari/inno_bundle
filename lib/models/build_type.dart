import 'package:args/args.dart';
import 'package:inno_bundle/utils/functions.dart';

enum BuildType {
  debug,
  profile,
  release;

  String get dirName => capitalize(name);

  static BuildType fromArgs(ArgResults args) {
    return args[BuildType.release.name]
        ? BuildType.release
        : args[BuildType.profile.name]
            ? BuildType.profile
            : BuildType.debug;
  }
}
