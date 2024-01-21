import 'dart:io';

import 'package:args/args.dart';
import 'package:inno_bundle/utils/constants.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

/// Run to generate an App ID (as GUID)
void main(List<String> arguments) {
  final parser = ArgParser()
    ..addOption('ns', help: "Namespace, ex: google.com")
    ..addFlag('hf', defaultsTo: true, help: 'Print header and footer')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Print help and exit');

  final parsedArgs = parser.parse(arguments);
  final ns = parsedArgs['ns'] as String?;
  final hf = parsedArgs['hf'] as bool;
  final help = parsedArgs['help'] as bool;

  if (hf) print(START_MESSAGE);

  if (help) {
    print("${parser.usage}\n");
    exit(0);
  }

  if (ns != null) {
    print(uuid.v5(Uuid.NAMESPACE_URL, ns));
  } else {
    print(uuid.v1());
  }

  if (hf) print(GUID_END_MESSAGE);
}
