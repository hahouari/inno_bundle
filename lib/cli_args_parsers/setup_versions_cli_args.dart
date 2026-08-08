/// The `setup_versions` command manages versioned Inno Setup installations.
///
/// Inno_bundle can test against multiple Inno Setup versions, each installed
/// into its own folder. This class models the arguments that drive that setup:
/// which versions to install, where to put them, and the output framing. See
/// the `bin/setup_versions.dart` entry point for how these are consumed.
import 'package:args/args.dart';
import 'package:inno_bundle/utils/constants.dart';

/// The resolved CLI options for the `setup_versions` command.
class SetupVersionsCliArgs {
  /// The Inno Setup versions requested for installation, in order.
  final List<String> versions;

  /// Root directory under which each version is installed.
  ///
  /// Each version gets its own subfolder (e.g. `<outRoot>/6.3.3/`).
  final String outRoot;

  /// Whether to print the header/footer lines framing the output.
  final bool hf;

  /// Whether to print usage and exit without installing anything.
  final bool help;

  /// Creates an instance with the given values.
  SetupVersionsCliArgs({
    required this.versions,
    required this.outRoot,
    required this.hf,
    required this.help,
  });

  /// Declares the options accepted by the `setup_versions` command.
  ///
  /// The `help:` strings are shown verbatim to users through `--help`.
  static ArgParser parser = ArgParser()
    ..addOption(
      'versions',
      defaultsTo: defaultInnoSetupVersion,
      help: 'Comma-separated Inno Setup versions to install',
    )
    ..addOption(
      'out-root',
      defaultsTo: innoManagedVersionsDir,
      help: 'Root directory for extracted versions',
    )
    ..addFlag(
      'hf',
      defaultsTo: true,
      help: 'Print header and footer',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print help and exit',
    );

  /// Returns the usage message for the command, including runnable examples.
  String helpMessage() {
    return "${parser.usage}\n"
        '\nExamples:'
        '\n  dart run inno_bundle:setup_versions'
        '\n  dart run inno_bundle:setup_versions --versions 6.7.3,6.6.1'
        '\n  dart run inno_bundle:setup_versions --versions 6.7.3 --out-root C:\\tools\\inno\n';
  }

  /// Parses the given [arguments] into a [SetupVersionsCliArgs].
  ///
  /// The comma-separated `--versions` option is split into a list and trimmed;
  /// every other option maps directly onto a field.
  factory SetupVersionsCliArgs.parse(List<String> arguments) {
    final parsedArgs = parser.parse(arguments);
    return SetupVersionsCliArgs(
      versions: (parsedArgs['versions'] as String)
          .split(',')
          .map((v) => v.trim())
          .toList(),
      outRoot: parsedArgs['out-root'] as String,
      hf: parsedArgs['hf'] as bool,
      help: parsedArgs['help'] as bool,
    );
  }
}
