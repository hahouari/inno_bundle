/// This file defines the [AdminMode] enum, which represents the different
/// privilege modes that can be requested by the installer.
///
/// The [AdminMode] enum provides three options:
/// - [AdminMode.admin]: Requests administrator privileges.
/// - [AdminMode.nonAdmin]: Does not request administrator privileges.
/// - [AdminMode.auto]: Automatically determines the appropriate privilege mode.
///
/// The file also includes a [fromOption] method that allows for parsing a
/// configuration option (typically from a YAML or JSON configuration file)
/// into one of the [AdminMode] values, ensuring compatibility with both
/// boolean and string representations.
library;

/// An enum representing the different privilege modes to be asked by installer.
enum AdminMode {
  admin,
  nonAdmin,
  auto;

  /// Parses configuration option to the desired [AdminMode].
  static AdminMode fromOption(dynamic option) {
    if (option is bool) {
      return option ? admin : nonAdmin;
    }
    return auto;
  }
}
