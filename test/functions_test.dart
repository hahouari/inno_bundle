import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'package:inno_bundle/utils/functions.dart';

void main() {
  group('camelCase', () {
    test('camelCases underscore, dash and space separated words', () {
      expect(camelCase('demo_app'), 'DemoApp');
      expect(camelCase('hello-world_out there'), 'HelloWorldOutThere');
      expect(camelCase('myApp'), 'MyApp');
    });
  });

  group('capitalize', () {
    test('capitalizes the first letter only and tolerates empty input', () {
      expect(capitalize('hello'), 'Hello');
      expect(capitalize('Hello'), 'Hello');
      expect(capitalize(''), '');
    });
  });

  group('compareVersions', () {
    test('compares dotted versions numerically', () {
      expect(compareVersions('6.10.0', '6.9.9'), greaterThan(0));
      expect(compareVersions('6.4.0', '6.4.0'), 0);
      expect(compareVersions('6.3.3', '6.4.0'), lessThan(0));
      expect(compareVersions('7.0.0', '6.99.99'), greaterThan(0));
    });

    test('pads missing segments with zero', () {
      expect(compareVersions('6.4', '6.4.0'), 0);
    });
  });

  group('readYaml', () {
    test('converts nested yaml to plain maps and lists', () {
      final tempDir = Directory.systemTemp.createTempSync('read_yaml_');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final file = File(p.join(tempDir.path, 'config.yaml'));
      file.writeAsStringSync('''
name: demo_app
inno_bundle:
  id: 5ec949d0-0582-1e06-b073-b5d1161f6fff
  languages:
    - English
    - French
  nested:
    list:
      - one
      - two
''');

      final map = readYaml(file);
      expect(map['name'], 'demo_app');
      final inno = map['inno_bundle'] as Map<String, dynamic>;
      expect(inno['languages'], ['English', 'French']);
      final nested = inno['nested'] as Map<String, dynamic>;
      expect(nested['list'], ['one', 'two']);
    });
  });
}
