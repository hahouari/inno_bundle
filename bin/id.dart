/// The `inno_bundle id` command-line entry point.
///
/// This is a small standalone tool that produces an App ID (a GUID) for use
/// as the `inno_bundle.id` value in a config file. It accepts an optional `--ns`
/// namespace so the same name always yields the same namespaced UUID.
import 'dart:io';

import 'package:inno_bundle/models/cli_configs/id_cli_config.dart';
import 'package:inno_bundle/utils/constants.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

/// Generates an App ID (as a GUID) and prints it to stdout.
///
/// Uses a namespaced UUID when [`--ns`] is provided, otherwise a random UUID,
/// then exits. The value is meant to be copied into the config file.
void main(List<String> arguments) {
  final cliConfig = IdCliConfig.parse(arguments);

  if (cliConfig.hf) print(START_MESSAGE);

  if (cliConfig.help) {
    print(cliConfig.helpMessage());
    exit(0);
  }

  final ns = cliConfig.ns;
  if (ns != null) {
    print(uuid.v5(Namespace.url.value, ns));
  } else {
    print(uuid.v1());
  }

  if (cliConfig.hf) print(GUID_END_MESSAGE);
}
