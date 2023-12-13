import 'package:flutter_test/flutter_test.dart';
import 'package:titanius/data/android_intent.dart';

void main() {
  test('parseAmStartCommand should correctly parse command into LaunchIntent', () {
    const command = "am start "
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
        'CONFIGFILE': '/storage/emulated/0/Android/data/com.retroarch/files/retroarch.cfg',
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

  test('parseAmStartCommand should correctly parse command with VIEW action into LaunchIntent', () {
    const command = "-n org.ppsspp.ppssppgold/org.ppsspp.ppsspp.PpssppActivity "
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
  });
}
