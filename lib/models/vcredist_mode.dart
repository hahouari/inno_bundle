/// This file defines the [VcRedistMode] enum, which represents the different
/// modes for handling the Visual C++ Redistributable.
///
/// The [VcRedistMode] enum provides three options:
/// - [VcRedistMode.bundle]: Bundles the VCRedist with the installer.
/// - [VcRedistMode.download]: Downloads the VCRedist during installation.
/// - [VcRedistMode.none]: Does not include or download the VCRedist.
///
/// The file also includes a [fromOption] method that allows for parsing a
/// configuration option into one of the [VcRedistMode] values, ensuring
/// compatibility with boolean and string representations.
library;

/// An enum representing the different modes for handling the Visual C++ Redistributable.
enum VcRedistMode {
  bundle,
  download,
  none;

  /// Parses configuration option to the desired [VcRedistMode].
  static VcRedistMode fromOption(dynamic option) {
    if (option is bool) {
      return option ? bundle : none;
    } else if (option == 'download') {
      return download;
    }
    return none;
  }
}
