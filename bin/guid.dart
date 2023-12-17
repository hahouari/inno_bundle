import 'package:args/args.dart';
import 'package:inno_setup/utils/constants.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

/// Run to generate an App ID (as GUID)
void main(List<String> arguments) {
  print(START_MESSAGE);

  final parser = ArgParser()..addOption('url');
  final parsedArgs = parser.parse(arguments);
  final url = parsedArgs['url'] as String?;

  if (url != null) {
    print(uuid.v5(Uuid.NAMESPACE_URL, url));
  } else {
    print(uuid.v1());
  }

  print(GUID_END_MESSAGE);
}