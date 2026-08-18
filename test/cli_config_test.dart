import 'package:test/test.dart';

import 'package:inno_bundle/managers/inno_version_manager.dart';
import 'package:inno_bundle/models/build_type.dart';
import 'package:inno_bundle/models/cli_configs/id_cli_config.dart';
import 'package:inno_bundle/models/cli_configs/inno_bundle_cli_config.dart';
import 'package:inno_bundle/models/cli_configs/setup_versions_cli_config.dart';

void main() {
  group('InnoBundleCliConfig.parse', () {
    test('defaults match invoking the command with no arguments', () {
      final c = InnoBundleCliConfig.parse([]);
      expect(c.type, BuildType.release);
      expect(c.app, isTrue);
      expect(c.installer, isTrue);
      expect(c.installInnoSetup, isTrue);
      expect(c.generateAppId, isTrue);
      expect(c.generatePublisher, isTrue);
      expect(c.envs, isFalse);
      expect(c.hf, isTrue);
      expect(c.help, isFalse);
    });

    test('reads flag overrides', () {
      final c = InnoBundleCliConfig.parse([
        '--app-version',
        '2.0.0',
        '--no-app',
        '--no-installer',
        '--build-args',
        '--dart-define=X=1',
        '--path',
        'custom.yaml',
        '--envs',
        '--sign-tool-name',
        'N',
        '--sign-tool-command',
        'cmd',
        '--sign-tool-params',
        'p',
      ]);
      expect(c.appVersion, '2.0.0');
      expect(c.app, isFalse);
      expect(c.installer, isFalse);
      expect(c.buildArgs, '--dart-define=X=1');
      expect(c.path, 'custom.yaml');
      expect(c.envs, isTrue);
      expect(c.signToolName, 'N');
      expect(c.signToolCommand, 'cmd');
      expect(c.signToolParams, 'p');
    });

    test('build-type precedence: debug beats profile beats release', () {
      expect(InnoBundleCliConfig.parse(['--release']).type, BuildType.release);
      expect(InnoBundleCliConfig.parse(['--profile']).type, BuildType.profile);
      expect(InnoBundleCliConfig.parse(['--debug']).type, BuildType.debug);
      expect(InnoBundleCliConfig.parse(['--profile', '--debug']).type,
          BuildType.debug);
      expect(InnoBundleCliConfig.parse(['--release', '--profile']).type,
          BuildType.profile);
    });
  });

  group('SetupVersionsCliConfig.parse', () {
    test('defaults to the manager default version', () {
      final c = SetupVersionsCliConfig.parse([]);
      expect(c.versions, [InnoVersionManager.defaultVersion]);
    });

    test('splits and trims the comma-separated versions list', () {
      final c =
          SetupVersionsCliConfig.parse(['--versions', '6.7.3, 6.6.1 ,6.4.3']);
      expect(c.versions, ['6.7.3', '6.6.1', '6.4.3']);
    });
  });

  group('IdCliConfig.parse', () {
    test('defaults to no namespace (random id)', () {
      expect(IdCliConfig.parse([]).ns, isNull);
    });

    test('reads the --ns namespace', () {
      expect(IdCliConfig.parse(['--ns', 'google.com']).ns, 'google.com');
    });
  });

  group('BuildType.fromArgs', () {
    test('debug beats profile beats release', () {
      final parser = InnoBundleCliConfig.parser;
      expect(
          BuildType.fromArgs(parser.parse(['--release'])), BuildType.release);
      expect(
          BuildType.fromArgs(parser.parse(['--profile'])), BuildType.profile);
      expect(BuildType.fromArgs(parser.parse(['--debug'])), BuildType.debug);
      expect(
        BuildType.fromArgs(parser.parse(['--profile', '--debug'])),
        BuildType.debug,
      );
    });
  });
}
