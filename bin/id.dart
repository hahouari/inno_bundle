import 'package:args/args.dart';
import 'package:inno_bundle/utils/constants.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

/// Run to generate an App ID (as GUID)
void main(List<String> arguments) {
  print(START_MESSAGE);

  final parser = ArgParser()..addOption('ns');
  final parsedArgs = parser.parse(arguments);
  final ns = parsedArgs['ns'] as String?;

  if (ns != null) {
    print(uuid.v5(Uuid.NAMESPACE_URL, ns));
  } else {
    print(uuid.v1());
  }

  print(GUID_END_MESSAGE);
}