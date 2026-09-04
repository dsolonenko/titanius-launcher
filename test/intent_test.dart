import 'package:flutter_test/flutter_test.dart';
import 'package:titanius/data/android_intent.dart';
import 'package:titanius/data/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('parseAmStartCommand should correctly parse command into LaunchIntent', () {
    const command =
        "am start "
        "-n com.retroarch/.browser.retroactivity.RetroActivityFuture "
        "-e ROM {file.path} "
        "-e LIBRETRO /data/data/com.retroarch/cores/fbneo_libretro_android.so "
        "-e CONFIGFILE /storage/emulated/0/Android/data/com.retroarch/files/retroarch.cfg "
        "-e QUITFOCUS "
        "--activity-clear-task "
        "--activity-clear-top "
        "--activity-no-history";

    final expectedIntent = LaunchIntent(
      target: 'com.retroarch/.browser.retroactivity.RetroActivityFuture',
      action: '',
      data: '',
      args: {
        'ROM': '{file.path}',
        'LIBRETRO': '/data/data/com.retroarch/cores/fbneo_libretro_android.so',
        'CONFIGFILE':
            '/storage/emulated/0/Android/data/com.retroarch/files/retroarch.cfg',
        'QUITFOCUS': '',
      },
      flags: [
        '--activity-clear-task',
        '--activity-clear-top',
        '--activity-no-history',
      ],
    );

    final result = LaunchIntent.parseAmStartCommand(command);

    expect(result, equals(expectedIntent));
  });

  test(
    'parseAmStartCommand should correctly parse command with VIEW action into LaunchIntent',
    () {
      const command =
          "-n org.ppsspp.ppssppgold/org.ppsspp.ppsspp.PpssppActivity "
          "-a android.intent.action.VIEW "
          '-d "{file.documenturi}" '
          "--activity-clear-task "
          "--activity-clear-top "
          "--activity-no-history";

      final expectedIntent = LaunchIntent(
        target: 'org.ppsspp.ppssppgold/org.ppsspp.ppsspp.PpssppActivity',
        action: 'android.intent.action.VIEW',
        data: '{file.documenturi}',
        args: {},
        flags: [
          '--activity-clear-task',
          '--activity-clear-top',
          '--activity-no-history',
        ],
      );

      final result = LaunchIntent.parseAmStartCommand(command);

      expect(result, equals(expectedIntent));
    },
  );

  test(
    'parseAmStartCommand should correctly parse Daijisho PPSSPP arguments with newlines and category/type',
    () {
      const command =
          "-n org.ppsspp.ppsspp/.PpssppActivity\n"
          " -a android.intent.action.VIEW\n"
          " -c android.intent.category.DEFAULT\n"
          " -d {file.uri}\n"
          " -t application/octet-stream\n"
          " --activity-clear-task  --activity-clear-top  --activity-no-history";

      final expectedIntent = LaunchIntent(
        target: 'org.ppsspp.ppsspp/.PpssppActivity',
        action: 'android.intent.action.VIEW',
        category: 'android.intent.category.DEFAULT',
        data: '{file.uri}',
        type: 'application/octet-stream',
        args: {},
        flags: [
          '--activity-clear-task',
          '--activity-clear-top',
          '--activity-no-history',
        ],
      );

      final result = LaunchIntent.parseAmStartCommand(command);

      expect(result, equals(expectedIntent));
      expect(result.needsUri, isTrue);
      expect(result.isStandalone, isTrue);
    },
  );

  test(
    'parseAmStartCommand should correctly parse Daijisho melonDS arguments',
    () {
      const command =
          "-a me.magnum.melonds.LAUNCH_ROM\n"
          "-n me.magnum.melonds/.ui.emulator.EmulatorActivity\n"
          "-e uri {file.uri}";

      final expectedIntent = LaunchIntent(
        target: 'me.magnum.melonds/.ui.emulator.EmulatorActivity',
        action: 'me.magnum.melonds.LAUNCH_ROM',
        data: '',
        args: {'uri': '{file.uri}'},
        flags: [],
      );

      final result = LaunchIntent.parseAmStartCommand(command);

      expect(result, equals(expectedIntent));
      expect(result.needsUri, isFalse);
    },
  );

  test('parseAmStartCommand should correctly parse DolphinCS arguments', () {
    const command =
        "-n com.joeyos.dolphinemu/org.dolphinemu.dolphinemu.ui.main.MainActivity\n"
        "-a android.intent.action.MAIN\n"
        "-c android.intent.category.LAUNCHER\n"
        "-e AutoStartFile {file.uri}\n"
        "--activity-clear-task --activity-clear-top --activity-no-history";

    final result = LaunchIntent.parseAmStartCommand(command);

    expect(
      result.target,
      equals(
        'com.joeyos.dolphinemu/org.dolphinemu.dolphinemu.ui.main.MainActivity',
      ),
    );
    expect(result.action, equals('android.intent.action.MAIN'));
    expect(result.category, equals('android.intent.category.LAUNCHER'));
    expect(result.args['AutoStartFile'], equals('{file.uri}'));
    expect(result.needsUri, isFalse);
    expect(result.isStandalone, isTrue);
  });

  test('LaunchIntent toAmStartCommand reproduces am start syntax', () {
    final intent = LaunchIntent(
      target: 'org.ppsspp.ppsspp/.PpssppActivity',
      action: 'android.intent.action.VIEW',
      data: '{file.uri}',
      category: 'android.intent.category.DEFAULT',
      type: 'application/octet-stream',
      args: {'AutoStartFile': '{file.uri}'},
      flags: ['--activity-clear-task'],
      arrayArgs: {
        'AppStartParameters': ['-r', '{tags.game_id}'],
      },
    );

    final cmd = intent.toAmStartCommand();
    expect(cmd, contains('-n org.ppsspp.ppsspp/.PpssppActivity'));
    expect(cmd, contains('-a android.intent.action.VIEW'));
    expect(cmd, contains('-d {file.uri}'));
    expect(cmd, contains('-c android.intent.category.DEFAULT'));
    expect(cmd, contains('-t application/octet-stream'));
    expect(cmd, contains('-e AutoStartFile {file.uri}'));
    expect(cmd, contains('--esa AppStartParameters -r,{tags.game_id}'));
    expect(cmd, contains('--activity-clear-task'));
  });

  test(
    'LaunchIntent toIntent does not include FLAG_GRANT_READ_URI_PERMISSION',
    () async {
      final intent = LaunchIntent(
        target: 'org.ppsspp.ppsspp/.PpssppActivity',
        action: 'android.intent.action.VIEW',
        data: '{file.uri}',
        args: {},
        flags: ['--activity-clear-task', '--grant-read-uri-permission'],
      );
      final pspSystem = System(
        id: 'psp',
        screenScraperId: 0,
        name: 'PSP',
        logo: '',
        folders: ['psp'],
        builtInEmulators: [],
      );
      final game = Game(
        pspSystem,
        'Metal Slug',
        '/storage/emulated/0/Roms',
        'psp',
        '',
        'Metal Slug.iso',
      );
      final androidIntent = await intent.toIntent(game);
      expect(androidIntent.flags?.contains(0x00000001), isFalse);
    },
  );
}
