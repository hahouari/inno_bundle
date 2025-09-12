import 'package:inno_bundle/utils/cli_logger.dart';

import 'inno_bundle.dart' as build;

/// Run to build installer, this is a shortcut to the main function in inno_bundle.dart
///
/// This is kept for backwards compatibility.
void main(List<String> arguments) async {
  CliLogger.addDeferred(
    "This command is deprecated, use 'dart run inno_bundle' instead.",
    kind: CliLoggerKind.warning,
  );

  build.main(arguments);
}
