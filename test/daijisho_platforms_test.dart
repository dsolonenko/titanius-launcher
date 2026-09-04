import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:titanius/data/daijisho_platforms.dart';

void main() {
  group('Daijisho Platforms & Models', () {
    test('System aliases map correctly to Daijisho shortnames', () {
      expect(toDaijishoShortname('megadrive'), equals('genesis'));
      expect(toDaijishoShortname('psvita'), equals('vita'));
      expect(toDaijishoShortname('amigacd32'), equals('amiga'));
      expect(toDaijishoShortname('gx4000'), equals('cpc'));
      expect(toDaijishoShortname('psp'), equals('psp'));
      expect(toDaijishoShortname('snes'), equals('snes'));
      expect(toDaijishoShortname('gba'), equals('gba'));
    });

    test(
      'DaijishoPlatformIndex parses list and finds shortname case-insensitively',
      () {
        final json = {
          'baseUri':
              'https://raw.githubusercontent.com/TapiocaFox/Daijishou/main/platforms/',
          'platformList': [
            {
              'filename': 'PlayStationPortable.json',
              'platformName': 'PlayStation Portable',
              'platformShortname': 'psp',
              'platformUniqueId': 'psp',
              'revisionNumber': 14,
            },
            {
              'filename': 'SegaGenesis.json',
              'platformName': 'Sega Genesis',
              'platformShortname': 'genesis',
              'platformUniqueId': 'genesis',
              'revisionNumber': 10,
            },
          ],
        };

        final index = DaijishoPlatformIndex.fromJson(json);
        expect(index.platformList.length, equals(2));

        final pspItem = index.findByShortname('psp');
        expect(pspItem, isNotNull);
        expect(pspItem!.filename, equals('PlayStationPortable.json'));
        expect(pspItem.platformName, equals('PlayStation Portable'));

        final genesisItem = index.findByShortname('GENESIS');
        expect(genesisItem, isNotNull);
        expect(genesisItem!.filename, equals('SegaGenesis.json'));

        final nonExistent = index.findByShortname('nonexistent');
        expect(nonExistent, isNull);
      },
    );

    test(
      'DaijishoPlayer converts to Emulator with clean name and daijisho prefix',
      () {
        final playerJson = {
          'name': 'psp - PPSSPP',
          'uniqueId': 'psp.org.ppsspp.ppsspp',
          'description': 'Supported extensions: cso, chd, elf, iso, pbp, prx.',
          'acceptedFilenameRegex': '^(.*)\\.(?:cso|chd|elf|iso|pbp|prx)\$',
          'amStartArguments':
              '-n org.ppsspp.ppsspp/.PpssppActivity\n -a android.intent.action.VIEW\n -c android.intent.category.DEFAULT\n -d {file.uri}\n -t application/octet-stream\n --activity-clear-task  --activity-clear-top  --activity-no-history',
          'killPackageProcesses': false,
          'killPackageProcessesWarning': true,
          'extra': '',
        };

        final player = DaijishoPlayer.fromJson(playerJson);
        final emulator = player.toEmulator();

        expect(emulator.id, equals('daijisho:psp.org.ppsspp.ppsspp'));
        expect(emulator.name, equals('PPSSPP'));
        expect(emulator.isDaijisho, isTrue);
        expect(emulator.isCustom, isFalse);
        expect(emulator.isInternal, isFalse);
        expect(emulator.isStandalone, isTrue);
        expect(
          emulator.intent.target,
          equals('org.ppsspp.ppsspp/.PpssppActivity'),
        );
        expect(
          emulator.intent.category,
          equals('android.intent.category.DEFAULT'),
        );
        expect(emulator.intent.type, equals('application/octet-stream'));
        expect(emulator.intent.data, equals('{file.uri}'));
        expect(emulator.intent.needsUri, isTrue);
      },
    );

    test(
      'DaijishoPlayer preserves raw amStartArguments without modification',
      () {
        const args =
            '-a me.magnum.melonds.LAUNCH_ROM\n-n me.magnum.melonds/.ui.emulator.EmulatorActivity\n-e uri {file.uri}';
        final player = DaijishoPlayer(
          name: 'nds - MelonDS',
          uniqueId: 'nds.me.magnum.melonds',
          amStartArguments: args,
        );
        final emulator = player.toEmulator();
        expect(emulator.name, equals('MelonDS'));
        expect(emulator.id, equals('daijisho:nds.me.magnum.melonds'));
        expect(emulator.amStartArguments, equals(args));
        expect(emulator.intent.args['uri'], equals('{file.uri}'));
      },
    );

    test('DaijishoPlayer preserves name without dash separator', () {
      final player = DaijishoPlayer(
        name: 'artemis',
        uniqueId: 'artemis.app',
        amStartArguments: '-n artemis.app/.MainActivity',
      );
      final emulator = player.toEmulator();
      expect(emulator.name, equals('artemis'));
      expect(emulator.id, equals('daijisho:artemis.app'));
    });

    test('DaijishoPlatformFile parses platform and players', () {
      const sample = '''
      {
        "databaseVersion": 14,
        "revisionNumber": 14,
        "platform": {
          "name": "PlayStation Portable",
          "uniqueId": "psp",
          "shortname": "psp"
        },
        "playerList": [
          {
            "name": "psp - PPSSPP",
            "uniqueId": "psp.org.ppsspp.ppsspp",
            "amStartArguments": "-n org.ppsspp.ppsspp/.PpssppActivity"
          },
          {
            "name": "psp - RetroArch 64 - ppsspp",
            "uniqueId": "psp.ra64.ppsspp",
            "amStartArguments": "-n com.retroarch.aarch64/com.retroarch.browser.retroactivity.RetroActivityFuture -e ROM {file.path}"
          }
        ]
      }
      ''';

      final file = DaijishoPlatformFile.fromJson(jsonDecode(sample));
      expect(file.shortname, equals('psp'));
      expect(file.name, equals('PlayStation Portable'));
      expect(file.playerList.length, equals(2));

      final emus = file.playerList.map((p) => p.toEmulator()).toList();
      expect(emus[0].name, equals('PPSSPP'));
      expect(emus[0].isStandalone, isTrue);
      expect(emus[1].name, equals('RetroArch 64 - ppsspp'));
      expect(emus[1].isStandalone, isFalse);
    });
  });
}
