/// Represents the CLI options accepted by the `id` command.
///
/// The `id` command is a tiny utility that prints a GUID to stdout for use as
/// an `inno_bundle.id`. This class is what translates the user-supplied
/// arguments into the values [IdCliArgs.parse] hands back to the entry point.
///
/// Instances are normally built via [IdCliArgs.parse] on top of [parser], but
/// the constructor accepts plain values too.
import 'package:args/args.dart';

/// The fully resolved CLI options for the `id` command.
class IdCliArgs {
  /// Namespace to generate a namespaced (UUIDv5) App ID from.
  ///
  /// When null a random UUID is produced instead. Providing a namespace makes
  /// the output deterministic for the same string, which is handy for getting
  /// a stable App ID without storing it.
  final String? ns;

  /// Whether to print the header/footer lines framing the output.
  final bool hf;

  /// Whether to print usage and exit without outputting an ID.
  final bool help;

  /// Creates an instance with the given values.
  IdCliArgs({required this.ns, required this.hf, required this.help});

  /// Declares the options accepted by the `id` command.
  ///
  /// The `help:` strings are shown verbatim to users through `--help`.
  static ArgParser parser = ArgParser()
    ..addOption('ns', help: "Namespace, ex: google.com")
    ..addFlag('hf', defaultsTo: true, help: 'Print header and footer')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Print help and exit');

  /// Returns the usage message describing the accepted options.
  String helpMessage() {
    return "${parser.usage}\n";
  }

  /// Parses the given [arguments] into an [IdCliArgs].
  factory IdCliArgs.parse(List<String> arguments) {
    final parsedArgs = parser.parse(arguments);
    return IdCliArgs(
      ns: parsedArgs['ns'] as String?,
      hf: parsedArgs['hf'] as bool,
      help: parsedArgs['help'] as bool,
    );
  }
}