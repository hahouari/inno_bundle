import 'package:inno_setup/utils/cli_logger.dart';
import 'package:inno_setup/utils/constants.dart';
import 'package:inno_setup/utils/functions.dart';

void generate() {
  final config = getConfig();
  CliLogger.info(config.toString());
}

/// Run to build installer
void main(List<String> arguments) {
  print(START_MESSAGE);
  generate();
  print(BUILD_END_MESSAGE);
}