import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:titanius/data/android_saf.dart';
import 'package:titanius/data/files.dart';
import 'package:titanius/data/gamelist_xml.dart';
import 'package:titanius/data/games.dart';
import 'package:titanius/data/models.dart';
import 'package:titanius/data/repo.dart';
import 'package:titanius/data/scraper.dart';
import 'package:titanius/data/state.dart';
import 'package:titanius/data/systems.dart';
import 'package:titanius/widgets/scraper_progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'pathFromTreeUri decodes primary and external SD card SAF tree URIs properly',
    () {
      final primaryRoms = Uri.parse(
        'content://com.android.externalstorage.documents/tree/primary%3ARoms',
      );
      expect(pathFromTreeUri(primaryRoms), equals('/storage/emulated/0/Roms'));

      final primaryRoot = Uri.parse(
        'content://com.android.externalstorage.documents/tree/primary%3A',
      );
      expect(pathFromTreeUri(primaryRoot), equals('/storage/emulated/0'));

      final sdcardRoms = Uri.parse(
        'content://com.android.externalstorage.documents/tree/9C33-6BBD%3ARoms%2FNES',
      );
      expect(
        pathFromTreeUri(sdcardRoms),
        equals('/storage/9C33-6BBD/Roms/NES'),
      );

      final fileUri = Uri.parse('file:///home/user/Roms');
      expect(pathFromTreeUri(fileUri), equals('/home/user/Roms'));
    },
  );

  test('fastHash produces deterministic hash codes for ROM paths', () {
    final hash1 = fastHash('nes/SuperMarioBros.zip');
    final hash2 = fastHash('nes/SuperMarioBros.zip');
    final hash3 = fastHash('snes/Zelda.zip');

    expect(hash1, equals(hash2));
    expect(hash1, isNot(equals(hash3)));
  });

  test('GameFilter correctly filters games list by search query', () {
    const system = System(
      id: 'nes',
      screenScraperId: 1,
      name: 'NES',
      logo: 'nes.png',
      folders: ['nes'],
      builtInEmulators: [],
    );

    final game1 = Game(
      system,
      'Super Mario Bros',
      '/storage',
      'nes',
      '.',
      './mario.zip',
    );
    final game2 = Game(system, 'Zelda', '/storage', 'nes', '.', './zelda.zip');
    final game3 = Game(
      system,
      'Mario Kart',
      '/storage',
      'nes',
      '.',
      './mariokart.zip',
    );

    final filter = GameFilter('nes', search: 'mario');
    final result = filter.apply([game1, game2, game3]);

    expect(result.length, equals(2));
    expect(
      result.map((g) => g.name),
      containsAll(['Super Mario Bros', 'Mario Kart']),
    );
    expect(result.map((g) => g.name), isNot(contains('Zelda')));
  });

  test(
    'SettingsRepo updating existing setting key succeeds without UNIQUE constraint error',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = SettingsRepo(db);

      await repo.setDaijishoWallpaperPack('POP!');
      var settings = await repo.getSettings();
      expect(settings.daijishoWallpaperPack, equals('POP!'));

      // Updating the same setting key should overwrite cleanly instead of crashing with UNIQUE constraint failure
      await repo.setDaijishoWallpaperPack('DefaultPack');
      settings = await repo.getSettings();
      expect(settings.daijishoWallpaperPack, equals('DefaultPack'));

      await db.close();
    },
  );

  test('Settings font scale supports range from 0.10x to 3.00x', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final repo = SettingsRepo(db);

    var settings = await repo.getSettings();
    expect(settings.fontScale, equals(1.0));

    await repo.setFontScale(0.1);
    settings = await repo.getSettings();
    expect(settings.fontScale, equals(0.1));

    await repo.setFontScale(0.8);
    settings = await repo.getSettings();
    expect(settings.fontScale, equals(0.8));

    await repo.setFontScale(2.5);
    settings = await repo.getSettings();
    expect(settings.fontScale, equals(2.5));

    await repo.setFontScale(3.0);
    settings = await repo.getSettings();
    expect(settings.fontScale, equals(3.0));

    await db.close();
  });

  test(
    'Game JSON serialization and deserialization round-trip properly with nested System',
    () {
      const system = System(
        id: 'gb',
        screenScraperId: 9,
        name: 'Game Boy',
        logo: 'Nintendo Game Boy.png',
        folders: ['gb', 'gbh'],
        builtInEmulators: [],
      );

      final game = Game(
        system,
        'Tetris (W) (V1.1) [!]',
        '/mock/roms',
        'gb',
        '.',
        './Tetris (W) (V1.1) [!].zip',
      );

      final json = game.toJson();
      expect(json['system'], isA<Map<String, dynamic>>());

      final decoded = Game.fromJson(json);
      expect(decoded.name, equals(game.name));
      expect(decoded.system.id, equals('gb'));
      expect(decoded.system.name, equals('Game Boy'));
      expect(decoded.system.folders, equals(['gb', 'gbh']));

      // Also verify Game.fromJson handles in-memory System map directly
      final inMemoryMap = <String, dynamic>{
        'system': system,
        'name': 'Donkey Kong',
        'volumePath': '/mock/roms',
        'systemFolder': 'gb',
        'folder': '.',
        'rom': './Donkey Kong.zip',
      };
      final decodedFromInMemory = Game.fromJson(inMemoryMap);
      expect(decodedFromInMemory.name, equals('Donkey Kong'));
      expect(decodedFromInMemory.system.id, equals('gb'));
    },
  );

  test(
    'setFavouriteInGamelistXml creates gamelist.xml and marks game favorite',
    () async {
      final tempDir = await Directory.systemTemp.createTemp('titanius_test_');
      try {
        final systemDir = Directory('${tempDir.path}/gb');
        await systemDir.create();

        const system = System(
          id: 'gb',
          screenScraperId: 9,
          name: 'Game Boy',
          logo: 'gb.png',
          folders: ['gb'],
          builtInEmulators: [],
        );

        final game = Game(
          system,
          'Super Mario Land',
          tempDir.path,
          'gb',
          '.',
          './Super Mario Land.zip',
        );

        // Gamelist.xml does not exist yet; setting favorite should create it and return true
        final success = await setFavouriteInGamelistXml(game, true);
        expect(success, isTrue);

        final xmlFile = File('${systemDir.path}/gamelist.xml');
        expect(await xmlFile.exists(), isTrue);
        final content = await xmlFile.readAsString();
        expect(content, contains('<favorite>true</favorite>'));
        expect(content, contains('<path>./Super Mario Land.zip</path>'));

        // Toggling off should update the existing file
        final unFavSuccess = await setFavouriteInGamelistXml(game, false);
        expect(unFavSuccess, isTrue);
        final updatedContent = await xmlFile.readAsString();
        expect(updatedContent, contains('<favorite>false</favorite>'));
      } finally {
        await tempDir.delete(recursive: true);
      }
    },
  );

  test('deleteGame succeeds when no gamelist.xml entry exists', () async {
    final tempDir = await Directory.systemTemp.createTemp('titanius_test_');
    try {
      final systemDir = Directory('${tempDir.path}/gb');
      await systemDir.create();
      final rom = File('${systemDir.path}/Unlisted Game.zip');
      await rom.writeAsBytes([1, 2, 3]);

      const system = System(
        id: 'gb',
        screenScraperId: 9,
        name: 'Game Boy',
        logo: 'gb.png',
        folders: ['gb'],
        builtInEmulators: [],
      );
      final game = Game(
        system,
        'Unlisted Game',
        tempDir.path,
        'gb',
        '.',
        './Unlisted Game.zip',
      );

      expect(await deleteGame(game), isTrue);
      expect(await rom.exists(), isFalse);
    } finally {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'ScraperProgress isRunning correctly identifies active and completed states',
    () {
      final idle = ScraperProgress(
        total: 0,
        pending: 0,
        success: 0,
        error: 0,
        system: '',
        rom: '',
        message: '',
      );
      expect(idle.isRunning, isFalse);

      final active = ScraperProgress(
        total: 10,
        pending: 8,
        success: 2,
        error: 0,
        system: 'gb',
        rom: 'test.zip',
        message: 'Scraping...',
      );
      expect(active.isRunning, isTrue);

      final done = ScraperProgress(
        total: 10,
        pending: 0,
        success: 10,
        error: 0,
        system: '',
        rom: '',
        message: 'Done',
      );
      expect(done.isRunning, isFalse);

      final cancelled = ScraperProgress(
        total: 10,
        pending: 0,
        success: 2,
        error: 0,
        system: '',
        rom: '',
        message: 'Cancelled',
      );
      expect(cancelled.isRunning, isFalse);

      final quota = ScraperProgress(
        total: 10,
        pending: 5,
        success: 2,
        error: 3,
        system: '',
        rom: '',
        message: 'Quota exceeded',
      );
      expect(quota.isRunning, isFalse);
    },
  );

  test('getScraperRegionPriority returns expected priority sequences', () {
    expect(getScraperRegionPriority('us'), equals(['us', 'wor', 'eu', 'jp']));
    expect(getScraperRegionPriority('eu'), equals(['eu', 'wor', 'us', 'jp']));
    expect(getScraperRegionPriority('jp'), equals(['jp', 'wor', 'us', 'eu']));
    expect(getScraperRegionPriority('wor'), equals(['wor', 'us', 'eu', 'jp']));
    expect(getScraperRegionPriority(null), equals(['us', 'wor', 'eu', 'jp']));
  });

  test(
    'SettingsRepo saves and retrieves scraperRegion defaulting to us',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final repo = SettingsRepo(db);

      var settings = await repo.getSettings();
      expect(settings.scraperRegion, equals('us'));

      await repo.setScraperRegion('eu');
      settings = await repo.getSettings();
      expect(settings.scraperRegion, equals('eu'));

      await repo.setScraperRegion('jp');
      settings = await repo.getSettings();
      expect(settings.scraperRegion, equals('jp'));

      await db.close();
    },
  );

  test(
    'DesktopScraperService handles startScrape, stopScrape and receives progress events',
    () async {
      final service = DesktopScraperService();
      expect(await service.isRunning(), isFalse);

      final updates = <ScraperProgress>[];
      final sub = service.progressStream.listen((event) => updates.add(event));

      await service.startScrape(
        username: 'test',
        password: 'pwd',
        region: 'us',
        romFolders: [],
        roms: [],
        systems: [],
        scrapeTheseGames: 'all_games',
      );

      await Future.delayed(const Duration(milliseconds: 50));

      expect(updates.isNotEmpty, isTrue);
      expect(updates.first.message, equals('Starting...'));

      await service.stopScrape();
      expect(await service.isRunning(), isFalse);

      await sub.cancel();
    },
  );

  test(
    'listGamesFromFiles filters out auxiliary and save files (.srm, .auto, .state, .sav, .png, etc.)',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'titanius_roms_test_',
      );
      try {
        final gbaDir = Directory('${tempDir.path}/gba');
        await gbaDir.create(recursive: true);

        // Create real ROMs
        await File('${gbaDir.path}/Pokemon - Emerald.zip').create();
        await File('${gbaDir.path}/Zelda - Minish Cap.gba').create();

        // Create auxiliary files
        await File('${gbaDir.path}/Pokemon - Emerald.srm').create();
        await File('${gbaDir.path}/Pokemon - Emerald.srm.auto').create();
        await File('${gbaDir.path}/Pokemon - Emerald.auto').create();
        await File('${gbaDir.path}/Pokemon - Emerald.state').create();
        await File('${gbaDir.path}/Pokemon - Emerald.state1').create();
        await File('${gbaDir.path}/Pokemon - Emerald.state.auto').create();
        await File('${gbaDir.path}/Pokemon - Emerald.st0').create();
        await File('${gbaDir.path}/Pokemon - Emerald.sav').create();
        await File('${gbaDir.path}/Pokemon - Emerald.cht').create();
        await File('${gbaDir.path}/Pokemon - Emerald.cfg').create();
        await File('${gbaDir.path}/Pokemon - Emerald.png').create();
        await File('${gbaDir.path}/Pokemon - Emerald.mp4').create();
        await File('${gbaDir.path}/Pokemon - Emerald.txt').create();
        await File('${gbaDir.path}/Pokemon - Emerald.bak').create();

        const system = System(
          id: 'gba',
          screenScraperId: 12,
          name: 'Game Boy Advance',
          logo: 'gba.png',
          folders: ['gba'],
          builtInEmulators: [],
        );

        final games = await listGamesFromFiles(
          romsFolder: tempDir.path,
          folder: 'gba',
          system: system,
        );

        final romNames = games.map((g) => g.rom).toList();
        expect(romNames.length, equals(2));
        expect(romNames, contains('./Pokemon - Emerald.zip'));
        expect(romNames, contains('./Zelda - Minish Cap.gba'));
      } finally {
        await tempDir.delete(recursive: true);
      }
    },
  );

  test('scanner retains legitimate ROM folders named media', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'titanius_streaming_scan_test_',
    );
    try {
      await Directory('${tempDir.path}/gba/hacks').create(recursive: true);
      await Directory(
        '${tempDir.path}/gba/media/images/deep',
      ).create(recursive: true);
      await File('${tempDir.path}/gba/original.gba').create();
      await File('${tempDir.path}/gba/hacks/translated.gba').create();
      await File(
        '${tempDir.path}/gba/media/images/deep/not-a-rom.gba',
      ).create();
      const system = System(
        id: 'gba',
        screenScraperId: 12,
        name: 'GBA',
        logo: 'gba.png',
        folders: ['gba'],
        builtInEmulators: [],
      );
      final games = await listGamesFromFiles(
        romsFolder: tempDir.path,
        folder: 'gba',
        system: system,
      );
      expect(
        games.map((game) => game.name),
        containsAll(['original', 'translated']),
      );
      expect(games.map((game) => game.name), contains('not-a-rom'));
    } finally {
      await tempDir.delete(recursive: true);
    }
  });

  test('scanner keeps ROMs stored beside artwork', () async {
    final tempDir = await Directory.systemTemp.createTemp(
      'titanius_mixed_media_test_',
    );
    try {
      final mixed = Directory('${tempDir.path}/gba/hacks');
      await mixed.create(recursive: true);
      await File('${mixed.path}/cover.png').create();
      await File('${mixed.path}/game.gba').create();
      const system = System(
        id: 'gba',
        screenScraperId: 12,
        name: 'GBA',
        logo: '',
        folders: ['gba'],
        builtInEmulators: [],
      );
      final games = await listGamesFromFiles(
        romsFolder: tempDir.path,
        folder: 'gba',
        system: system,
      );
      expect(games.map((game) => game.name), contains('game'));
      expect(games.map((game) => game.name), isNot(contains('cover')));
    } finally {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'GameList indexes large collections for constant-time selection lookup',
    () {
      const system = System(
        id: 'gba',
        screenScraperId: 12,
        name: 'GBA',
        logo: 'gba.png',
        folders: ['gba'],
        builtInEmulators: [],
      );
      final games = List.generate(
        10000,
        (index) => Game(
          system,
          'Game $index',
          '/roms',
          'gba',
          '.',
          './game-$index.gba',
        ),
      );
      final gameList = GameList(system, '.', games, null);
      expect(gameList.indexOf(games[9999]), 9999);
      expect(
        gameList.indexOf(
          Game(system, 'Missing', '/roms', 'gba', '.', './missing.gba'),
        ),
        -1,
      );
    },
  );

  test('GameLibrary coalesces requests and invalidates one system', () async {
    var calls = 0;
    final gate = Completer<void>();
    final library = GameLibrary(
      loader: (params) async {
        calls++;
        await gate.future;
        return [];
      },
    );
    const system = System(
      id: 'gba',
      screenScraperId: 12,
      name: 'GBA',
      logo: 'gba.png',
      folders: ['gba'],
      builtInEmulators: [],
    );
    final params = SystemGamesTaskParams(['/roms'], system, false);
    final first = library.load(params);
    final second = library.load(params);
    expect(identical(first, second), isTrue);
    gate.complete();
    await Future.wait([first, second]);
    expect(calls, 1);
    library.invalidateSystem('gba');
    await library.load(params);
    expect(calls, 2);
  });

  test('GameLibrary bounds concurrent system loads', () async {
    var active = 0;
    var peak = 0;
    final library = GameLibrary(
      maxConcurrent: 2,
      loader: (params) async {
        active++;
        peak = max(peak, active);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        active--;
        return [];
      },
    );
    System system(String id) => System(
      id: id,
      screenScraperId: 1,
      name: id,
      logo: '',
      folders: [id],
      builtInEmulators: const [],
    );
    await Future.wait([
      for (final id in ['a', 'b', 'c', 'd'])
        library.load(SystemGamesTaskParams(['/roms'], system(id), false)),
    ]);
    expect(peak, 2);
  });

  test(
    'system visibility checks folders without scanning their contents',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'titanius_visibility_test_',
      );
      try {
        const system = System(
          id: 'gba',
          screenScraperId: 12,
          name: 'GBA',
          logo: '',
          folders: ['gba'],
          builtInEmulators: [],
        );
        expect(await hasSystemFolder(system, [tempDir.path]), isFalse);
        await Directory('${tempDir.path}/gba').create(recursive: true);
        expect(await hasSystemFolder(system, [tempDir.path]), isTrue);
      } finally {
        await tempDir.delete(recursive: true);
      }
    },
  );

  test('disabled systems never reach the game loader', () async {
    var loads = 0;
    final library = GameLibrary(
      loader: (params) async {
        loads++;
        return [];
      },
    );
    final container = ProviderContainer(
      overrides: [
        detectedSystemsProvider.overrideWith((ref) async => []),
        romFoldersProvider.overrideWith((ref) async => ['/roms']),
        settingsProvider.overrideWith((ref) async => Settings({})),
        gameLibraryProvider.overrideWithValue(library),
      ],
    );
    try {
      expect(await container.read(systemGamesProvider('gba').future), isEmpty);
      expect(loads, 0);
    } finally {
      container.dispose();
    }
  });

  test('system statistics stay disabled until deliberate interaction', () {
    final container = ProviderContainer();
    try {
      expect(container.read(systemStatsEnabledProvider), isFalse);
      container.read(systemStatsEnabledProvider.notifier).enable();
      expect(container.read(systemStatsEnabledProvider), isTrue);
    } finally {
      container.dispose();
    }
  });

  test(
    'no_metadata collection is disabled by default and identifies games without metadata',
    () {
      final enabledSystems = EnabledSystems({});
      expect(enabledSystems.showSystem('nes'), isTrue);
      expect(enabledSystems.showSystem('favourites'), isTrue);
      expect(enabledSystems.showSystem('no_metadata'), isFalse);

      const system = System(
        id: 'nes',
        screenScraperId: 1,
        name: 'NES',
        logo: '',
        folders: ['nes'],
        builtInEmulators: [],
      );
      final gameWithoutMetadata = Game(
        system,
        'Game 1',
        '/roms',
        'nes',
        '.',
        './game1.zip',
      );
      expect(gameWithoutMetadata.hasMetadata, isFalse);

      final gameWithImage = Game(
        system,
        'Game 2',
        '/roms',
        'nes',
        '.',
        './game2.zip',
        imageUrl: './media/images/game2.png',
      );
      expect(gameWithImage.hasMetadata, isTrue);

      final gameWithDesc = Game(
        system,
        'Game 3',
        '/roms',
        'nes',
        '.',
        './game3.zip',
        description: 'Some description',
      );
      expect(gameWithDesc.hasMetadata, isTrue);
    },
  );
}
