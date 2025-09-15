import 'package:args/args.dart';
import 'package:inno_bundle/models/build_tool.dart';
import 'package:test/test.dart';

void main() {
  group('BuildTool parsing', () {
    test('defaults to flutter when not provided', () {
      final parser = ArgParser()..addOption('build-tool');
      final args = parser.parse([]);
      expect(BuildTool.fromArgs(args), BuildTool.flutter);
    });

    test('parses shorebird', () {
      final parser = ArgParser()..addOption('build-tool');
      final args = parser.parse(['--build-tool', 'shorebird']);
      expect(BuildTool.fromArgs(args), BuildTool.shorebird);
    });
  });
}
