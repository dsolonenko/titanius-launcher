import 'package:flutter_test/flutter_test.dart';
import 'package:titanius/data/android_saf.dart';
import 'package:titanius/data/daijisho_launcher.dart';
import 'package:titanius/data/models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SAF Tree Document URI Resolution', () {
    test(
      'pathToTreeDocumentUri formats primary storage correctly with systemFolder',
      () {
        const path =
            '/storage/emulated/0/Roms/nds/Ace Attorney Investigations - Miles Edgeworth (USA).zip';
        final uri = pathToTreeDocumentUri(path, systemFolder: 'nds');
        expect(
          uri,
          equals(
            'content://com.android.externalstorage.documents/tree/primary%3ARoms%2Fnds/document/primary%3ARoms%2Fnds%2FAce%20Attorney%20Investigations%20-%20Miles%20Edgeworth%20(USA).zip',
          ),
        );
      },
    );

    test('pathToTreeDocumentUri formats SD card storage correctly', () {
      const path = '/storage/1234-5678/Roms/gc/game.rvz';
      final uri = pathToTreeDocumentUri(path, systemFolder: 'gc');
      expect(
        uri,
        equals(
          'content://com.android.externalstorage.documents/tree/1234-5678%3ARoms%2Fgc/document/1234-5678%3ARoms%2Fgc%2Fgame.rvz',
        ),
      );
    });
  });

  group('DaijishoLauncher Intent Creation', () {
    final ndsSystem = System(
      id: 'nds',
      screenScraperId: 0,
      name: 'Nintendo DS',
      logo: '',
      folders: ['nds'],
      builtInEmulators: [],
    );

    final ndsGame = Game(
      ndsSystem,
      'Ace Attorney',
      '/storage/emulated/0/Roms',
      'nds',
      '',
      'Ace Attorney Investigations - Miles Edgeworth (USA).zip',
    );

    final pspSystem = System(
      id: 'psp',
      screenScraperId: 0,
      name: 'PlayStation Portable',
      logo: '',
      folders: ['psp'],
      builtInEmulators: [],
    );

    final pspGame = Game(
      pspSystem,
      'Metal Slug',
      '/storage/emulated/0/Roms',
      'psp',
      '',
      'Metal Slug Anthology.iso',
    );

    test('creates correct intent for melonDS matching Daijisho engine', () async {
      const command =
          "-a me.magnum.melonds.LAUNCH_ROM\n"
          "-n me.magnum.melonds/.ui.emulator.EmulatorActivity\n"
          "-e uri {file.uri}";

      final intent = await DaijishoLauncher.createIntentFromCommand(
        command,
        ndsGame,
      );

      expect(intent.action, equals('me.magnum.melonds.LAUNCH_ROM'));
      expect(intent.package, equals('me.magnum.melonds'));
      expect(
        intent.componentName,
        equals('me.magnum.melonds.ui.emulator.EmulatorActivity'),
      );
      expect(
        intent.arguments?['uri'],
        equals(
          'content://com.android.externalstorage.documents/tree/primary%3ARoms%2Fnds/document/primary%3ARoms%2Fnds%2FAce%20Attorney%20Investigations%20-%20Miles%20Edgeworth%20(USA).zip',
        ),
      );
      // Daijisho adds NEW_TASK (0x10000000)
      expect(intent.flags?.contains(0x10000000), isTrue);
    });

    test(
      'creates correct intent for DolphinCS with AutoStartFile and activity flags',
      () async {
        final gcSystem = System(
          id: 'gc',
          screenScraperId: 0,
          name: 'GameCube',
          logo: '',
          folders: ['gc'],
          builtInEmulators: [],
        );
        final gcGame = Game(
          gcSystem,
          'Luigi',
          '/storage/emulated/0/Roms',
          'gc',
          '',
          'Luigi\'s Mansion (Europe) (60hz) (v1.0) (Maeson).rvz',
        );

        const command =
            "-n com.joeyos.dolphinemu/org.dolphinemu.dolphinemu.ui.main.MainActivity\n"
            "-a android.intent.action.MAIN\n"
            "-c android.intent.category.LAUNCHER\n"
            "-e AutoStartFile {file.uri}\n"
            "--activity-clear-task --activity-clear-top --activity-no-history";

        final intent = await DaijishoLauncher.createIntentFromCommand(
          command,
          gcGame,
        );

        expect(intent.action, equals('android.intent.action.MAIN'));
        expect(intent.category, equals('android.intent.category.LAUNCHER'));
        expect(intent.package, equals('com.joeyos.dolphinemu'));
        expect(
          intent.componentName,
          equals('org.dolphinemu.dolphinemu.ui.main.MainActivity'),
        );
        expect(
          intent.arguments?['AutoStartFile'],
          equals(
            "content://com.android.externalstorage.documents/tree/primary%3ARoms%2Fgc/document/primary%3ARoms%2Fgc%2FLuigi's%20Mansion%20(Europe)%20(60hz)%20(v1.0)%20(Maeson).rvz",
          ),
        );
        expect(intent.flags?.contains(0x00008000), isTrue); // CLEAR_TASK
        expect(intent.flags?.contains(0x04000000), isTrue); // CLEAR_TOP
        expect(intent.flags?.contains(0x40000000), isTrue); // NO_HISTORY
        expect(intent.flags?.contains(0x10000000), isTrue); // NEW_TASK
      },
    );

    test('creates correct intent for PPSSPP with data URI and type', () async {
      const command =
          "-n org.ppsspp.ppsspp/.PpssppActivity\n"
          " -a android.intent.action.VIEW\n"
          " -c android.intent.category.DEFAULT\n"
          " -d {file.uri}\n"
          " -t application/octet-stream\n"
          " --activity-clear-task --activity-clear-top --activity-no-history";

      final intent = await DaijishoLauncher.createIntentFromCommand(
        command,
        pspGame,
      );

      expect(intent.action, equals('android.intent.action.VIEW'));
      expect(intent.category, equals('android.intent.category.DEFAULT'));
      expect(intent.type, equals('application/octet-stream'));
      expect(intent.componentName, equals('org.ppsspp.ppsspp.PpssppActivity'));
      expect(
        intent.data,
        equals(
          'content://com.android.externalstorage.documents/tree/primary%3ARoms%2Fpsp/document/primary%3ARoms%2Fpsp%2FMetal%20Slug%20Anthology.iso',
        ),
      );
      // Ensure FLAG_GRANT_READ_URI_PERMISSION is not passed for external storage URI
      expect(intent.flags?.contains(0x00000001), isFalse);
    });

    test(
      'creates correct intent for RetroArch with raw file path and extras',
      () async {
        const command =
            "-n com.retroarch.aarch64/com.retroarch.browser.retroactivity.RetroActivityFuture\n"
            " -e ROM {file.path}\n"
            " -e LIBRETRO melonds\n"
            " -e CONFIGFILE /storage/emulated/0/Android/data/com.retroarch.aarch64/files/retroarch.cfg";

        final intent = await DaijishoLauncher.createIntentFromCommand(
          command,
          ndsGame,
        );

        expect(
          intent.arguments?['ROM'],
          equals(
            '/storage/emulated/0/Roms/nds/Ace Attorney Investigations - Miles Edgeworth (USA).zip',
          ),
        );
        expect(intent.arguments?['LIBRETRO'], equals('melonds'));
        expect(
          intent.arguments?['CONFIGFILE'],
          equals(
            '/storage/emulated/0/Android/data/com.retroarch.aarch64/files/retroarch.cfg',
          ),
        );
      },
    );

    test('handles array arguments with --esa', () async {
      const command =
          "-n org.vita3k.emulator/org.vita3k.emulator.Emulator "
          "--esa AppStartParameters -r,PCSF00001";

      final intent = await DaijishoLauncher.createIntentFromCommand(
        command,
        ndsGame,
      );

      expect(
        intent.arrayArguments?['AppStartParameters'],
        equals(['-r', 'PCSF00001']),
      );
    });

    test(
      'strips all URI grant flags even if explicitly passed in command',
      () async {
        const command =
            "-n org.ppsspp.ppsspp/.PpssppActivity\n"
            " -a android.intent.action.VIEW\n"
            " -d {file.uri}\n"
            " --grant-read-uri-permission --grant-write-uri-permission\n"
            " -f 0x10000001";

        final intent = await DaijishoLauncher.createIntentFromCommand(
          command,
          pspGame,
        );

        expect(
          intent.flags?.contains(0x00000001),
          isFalse,
        ); // FLAG_GRANT_READ_URI_PERMISSION stripped
        expect(
          intent.flags?.contains(0x00000002),
          isFalse,
        ); // FLAG_GRANT_WRITE_URI_PERMISSION stripped
        expect(
          intent.flags?.contains(0x10000000),
          isTrue,
        ); // FLAG_ACTIVITY_NEW_TASK preserved
      },
    );
  });
}
