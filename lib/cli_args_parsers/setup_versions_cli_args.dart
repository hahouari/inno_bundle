/// CLI argument parser for the `setup_versions` command.
///
/// Parses the arguments received by the `bin/setup_versions.dart` entry point
/// into a [SetupVersionsCliArgs] instance via [SetupVersionsCliArgs.parse],
/// using the options declared in [SetupVersionsCliArgs.parser].
import 'package:args/args.dart';
import 'package:inno_bundle/utils/functions.dart';
import 'package:path/path.dart' as p;

/// Holds the parsed command-line arguments for the `setup_versions` command.
///
/// Exposes the resolved [versions], [outRoot], [hf] and [help] values so the
/// entry point can drive the installation of Inno Setup versions without
/// re-parsing the raw arguments.
class SetupVersionsCliArgs {
  /// Comma-separated Inno Setup versions to install, split into a list.
  final List<String> versions;

  /// Root directory for extracted versions.
  final String outRoot;

  /// Whether to print header and footer messages.
  final bool hf;

  /// Whether the `--help` flag was passed.
  final bool help;

  /// Creates an instance with the given [versions], [outRoot], [hf] and [help].
  SetupVersionsCliArgs({
    required this.versions,
    required this.outRoot,
    required this.hf,
    required this.help,
  });

  /// Declares the CLI options accepted by the `setup_versions` command.
  static ArgParser parser = ArgParser()
    ..addOption(
      'versions',
      defaultsTo: '6.3.3',
      help: 'Comma-separated Inno Setup versions to install',
    )
    ..addOption(
      'out-root',
      defaultsTo: p.join(getHomeDir(), '.inno_bundle', 'versions'),
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

  /// Returns the parser usage message followed by usage examples.
  String helpMessage() {
    return "${parser.usage}\n"
        '\nExamples:'
        '\n  dart run inno_bundle:setup_versions'
        '\n  dart run inno_bundle:setup_versions --versions 6.7.3,6.6.1'
        '\n  dart run inno_bundle:setup_versions --versions 6.7.3 --out-root C:\\tools\\inno\n';
  }

  /// Parses the given [arguments] into a [SetupVersionsCliArgs].
  ///
  /// Splits the `--versions` option on commas and trims each entry, and maps
  /// the remaining options onto the corresponding fields.
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
