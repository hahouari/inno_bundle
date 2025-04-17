/// This file contains the [CliConfig] class, which holds the configuration
/// for the command-line interface.
library;

import 'package:args/args.dart';
import 'package:inno_bundle/models/build_type.dart';

/// A class representing the configuration for the command-line interface.
class CliConfig {
  /// The build type (debug, profile, or release).
  final BuildType type;

  /// Whether to include the app in the installer.
  final bool app;

  /// Whether to create an installer file.
  final bool installer;

  /// Whether to install Inno Setup into your system, if not already installed.
  final bool installInnoSetup;

  /// Whether to generate app id and save it to pubspec.yaml.
  final bool generateAppId;

  /// Whether to generate publisher and save it to pubspec.yaml.
  /// This will use username of logged in user in machine.
  /// It will generate only if maintainer field is not present in pubspec.yaml.
  final bool generatePublisher;

  /// Namespace for the App ID (as GUID).
  final String? appIdNamespace;

  /// Arguments to be passed to flutter build.
  final String? buildArgs;

  /// Override app version.
  final String? appVersion;

  /// Override sign tool name.
  final String? signToolName;

  /// Override sign tool command.
  final String? signToolCommand;

  /// Override sign tool params.
  final String? signToolParams;

  /// The config name to use inside pubspec.yaml (defaults to inno_bundle).
  /// Useful when using multiple configs in the same project.
  final String configName;

  /// Creates a [CliConfig] instance with default values.
  const CliConfig({
    this.type = BuildType.debug,
    this.app = true,
    this.installer = true,
    this.installInnoSetup = true,
    this.generateAppId = true,
    this.generatePublisher = true,
    this.appIdNamespace,
    this.buildArgs,
    this.appVersion,
    this.signToolName,
    this.signToolCommand,
    this.signToolParams,
    this.configName = 'inno_bundle',
  });

  /// Creates a [CliConfig] instance from command-line arguments using [ArgResults].
  factory CliConfig.fromArgs(ArgResults args) {
    return CliConfig(
      type: BuildType.fromArgs(args),
      app: args['app'],
      installer: args['installer'],
      installInnoSetup: args['install-inno'],
      generateAppId: args['gen-app-id'],
      appIdNamespace: args['app-id-ns'],
      generatePublisher: args['gen-publisher'],
      buildArgs: args['build-args'],
      appVersion: args['app-version'],
      signToolName: args['sign-tool-name'],
      signToolCommand: args['sign-tool-command'],
      signToolParams: args['sign-tool-params'],
      configName: args['config-name'],
    );
  }
}
