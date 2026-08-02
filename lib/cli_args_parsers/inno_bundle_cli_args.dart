/// Holds every CLI option accepted by the `inno_bundle` command.
///
/// In this package a single set of command-line flags drives both what the
/// command should *do* (install Inno Setup, generate essentials, print env
/// vars, ...) and which build settings override the config file (app version,
/// sign tool, build type, ...). Because those two concerns share one flag
/// surface, they are modeled as a single object rather than separate classes.
///
/// Instances are normally produced by [InnoBundleCliArgs.parse] on top of
/// [parser], but they can also be constructed directly (as in tests) because
/// every field has a sensible default that matches invoking the command with
/// no arguments.
import 'package:args/args.dart';
import 'package:inno_bundle/models/build_type.dart';

/// The fully resolved set of CLI options for the `inno_bundle` command.
class InnoBundleCliArgs {
  /// Which build type to produce (`release`, `profile` or `debug`).
  ///
  /// Sets the [BuildType] used when invoking the Flutter build, which in turn
  /// decides the artifact directory the installer is produced from.
  final BuildType type;

  /// Whether to build the app itself.
  ///
  /// When false the installer is produced from an already-built app instead
  /// of triggering a new Flutter build.
  final bool app;

  /// Whether to produce the installer.
  final bool installer;

  /// Extra arguments appended to the `flutter build ...` invocation.
  final String? buildArgs;

  /// Overrides the app version resolved from the config file.
  final String? appVersion;

  /// Overrides the signing tool name defined in the config file.
  final String? signToolName;

  /// Overrides the signing tool command defined in the config file.
  final String? signToolCommand;

  /// Overrides the signing tool parameters defined in the config file.
  final String? signToolParams;

  /// Whether to make sure Inno Setup is installed before building.
  ///
  /// Requires Winget to be available; the install is skipped if Inno Setup is
  /// already detected on the machine.
  final bool installInnoSetup;

  /// Whether to generate an App ID and persist it into the config file.
  ///
  /// Only takes effect when the config file has no `id` yet.
  final bool generateAppId;

  /// Whether to derive a publisher name and persist it into the config file.
  ///
  /// Falls back to the logged-in username, and only if neither the config
  /// file nor the `maintainer` field provides a publisher.
  final bool generatePublisher;

  /// Namespace used when [generateAppId] creates a namespaced UUID.
  final String? appIdNamespace;

  /// Path to a custom config file; when omitted `pubspec.yaml` is used.
  final String? path;

  /// Whether to print the resolved configuration as environment variables and
  /// exit before doing any build work.
  final bool envs;

  /// Whether to print the header/footer lines framing the command output.
  final bool hf;

  /// Whether to print usage and exit without doing any work.
  final bool help;

  /// Whether to print the supported Inno Setup languages and exit.
  final bool listLanguages;

  /// Creates an instance with the given values.
  ///
  /// Every option defaults to the same behaviour as invoking the command with
  /// no arguments, so a bare `InnoBundleCliArgs()` is a valid default config.
  const InnoBundleCliArgs({
    this.type = BuildType.release,
    this.app = true,
    this.installer = true,
    this.buildArgs,
    this.appVersion,
    this.signToolName,
    this.signToolCommand,
    this.signToolParams,
    this.installInnoSetup = true,
    this.generateAppId = true,
    this.generatePublisher = true,
    this.appIdNamespace,
    this.path,
    this.envs = false,
    this.hf = true,
    this.help = false,
    this.listLanguages = false,
  });

  /// Declares the command-line options accepted by the command.
  ///
  /// The `help:` strings are shown verbatim to users through `--help`.
  static ArgParser parser = ArgParser()
    ..addFlag(BuildType.release.name, negatable: false, help: 'Default flag')
    ..addFlag(BuildType.profile.name, negatable: false)
    ..addFlag(BuildType.debug.name, negatable: false)
    ..addFlag('app', defaultsTo: true, help: 'Build app')
    ..addFlag('installer', defaultsTo: true, help: 'Build installer')
    ..addFlag(
      'install-inno',
      defaultsTo: true,
      help: 'Install Inno Setup into your system if not already installed\n'
          'This requires Winget to be already available on the system',
    )
    ..addFlag(
      'gen-app-id',
      defaultsTo: true,
      help: 'Generate a random App ID into your config file if non-existent\n'
          'This will use namespace from --app-id-ns if provided',
    )
    ..addOption(
      'path',
      help: 'Path to custom config file. Default: pubspec.yaml',
    )
    ..addOption(
      "app-id-ns",
      help: "Namespace for --gen-app-id\nExample: www.example.com",
    )
    ..addFlag(
      'gen-publisher',
      defaultsTo: true,
      help: 'Generate a publisher name into config file if non-existent\n'
          'This will generate based on username of logged in user in machine\n'
          'and only if maintainer field is not present in config file',
    )
    ..addOption("build-args", help: "Append args to \"flutter build ...\"")
    ..addOption("app-version", help: "Override app version")
    ..addOption("sign-tool-name", help: "Override sign tool name")
    ..addOption("sign-tool-command", help: "Override sign tool command")
    ..addOption("sign-tool-params", help: "Override sign tool params")
    ..addFlag(
      'envs',
      defaultsTo: false,
      negatable: false,
      help: "Print env variables and exit",
    )
    ..addFlag('hf', defaultsTo: true, help: 'Print header and footer')
    ..addFlag('list-languages',
        negatable: false, help: 'List all supported languages and exit')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Print help and exit');

  /// Returns the usage message describing the accepted options.
  String helpMessage() {
    return "${parser.usage}\n";
  }

  /// Parses the given [arguments] into an [InnoBundleCliArgs].
  ///
  /// Build-type precedence (release > profile > debug) is delegated to
  /// [BuildType.fromArgs]; every other field is read straight off the parsed
  /// results.
  factory InnoBundleCliArgs.parse(List<String> arguments) {
    final parsedArgs = parser.parse(arguments);
    return InnoBundleCliArgs(
      type: BuildType.fromArgs(parsedArgs),
      app: parsedArgs['app'],
      installer: parsedArgs['installer'],
      installInnoSetup: parsedArgs['install-inno'],
      generateAppId: parsedArgs['gen-app-id'],
      generatePublisher: parsedArgs['gen-publisher'],
      appIdNamespace: parsedArgs['app-id-ns'],
      buildArgs: parsedArgs['build-args'],
      appVersion: parsedArgs['app-version'],
      signToolName: parsedArgs['sign-tool-name'],
      signToolCommand: parsedArgs['sign-tool-command'],
      signToolParams: parsedArgs['sign-tool-params'],
      path: parsedArgs['path'] as String?,
      envs: parsedArgs['envs'],
      hf: parsedArgs['hf'],
      help: parsedArgs['help'],
      listLanguages: parsedArgs['list-languages'],
    );
  }
}