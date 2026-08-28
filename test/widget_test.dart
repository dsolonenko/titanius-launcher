import 'dart:io';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titanius/data/files.dart';
import 'package:titanius/data/gamelist_xml.dart';
import 'package:titanius/data/models.dart';
import 'package:titanius/data/repo.dart';
import 'package:titanius/data/scraper.dart';
import 'package:titanius/data/state.dart';
import 'package:titanius/widgets/scraper_progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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

    final game1 = Game(system, 'Super Mario Bros', '/storage', 'nes', '.', './mario.zip');
    final game2 = Game(system, 'Zelda', '/storage', 'nes', '.', './zelda.zip');
    final game3 = Game(system, 'Mario Kart', '/storage', 'nes', '.', './mariokart.zip');

    final filter = GameFilter('nes', search: 'mario');
    final result = filter.apply([game1, game2, game3]);

    expect(result.length, equals(2));
    expect(result.map((g) => g.name), containsAll(['Super Mario Bros', 'Mario Kart']));
    expect(result.map((g) => g.name), isNot(contains('Zelda')));
  });

  test('SettingsRepo updating existing setting key succeeds without UNIQUE constraint error', () async {
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
  });

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

  test('Game JSON serialization and deserialization round-trip properly with nested System', () {
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
      '/Users/ds/Roms',
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
      'volumePath': '/Users/ds/Roms',
      'systemFolder': 'gb',
      'folder': '.',
      'rom': './Donkey Kong.zip',
    };
    final decodedFromInMemory = Game.fromJson(inMemoryMap);
    expect(decodedFromInMemory.name, equals('Donkey Kong'));
    expect(decodedFromInMemory.system.id, equals('gb'));
  });

  test('setFavouriteInGamelistXml creates gamelist.xml and marks game favorite', () async {
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
  });

  test('ScraperProgress isRunning correctly identifies active and completed states', () {
    final idle = ScraperProgress(total: 0, pending: 0, success: 0, error: 0, system: '', rom: '', message: '');
    expect(idle.isRunning, isFalse);

    final active = ScraperProgress(total: 10, pending: 8, success: 2, error: 0, system: 'gb', rom: 'test.zip', message: 'Scraping...');
    expect(active.isRunning, isTrue);

    final done = ScraperProgress(total: 10, pending: 0, success: 10, error: 0, system: '', rom: '', message: 'Done');
    expect(done.isRunning, isFalse);

    final cancelled = ScraperProgress(total: 10, pending: 0, success: 2, error: 0, system: '', rom: '', message: 'Cancelled');
    expect(cancelled.isRunning, isFalse);

    final quota = ScraperProgress(total: 10, pending: 5, success: 2, error: 3, system: '', rom: '', message: 'Quota exceeded');
    expect(quota.isRunning, isFalse);
  });

  test('DesktopScraperService handles startScrape, stopScrape and receives progress events', () async {
    final service = DesktopScraperService();
    expect(await service.isRunning(), isFalse);

    final updates = <ScraperProgress>[];
    final sub = service.progressStream.listen((event) => updates.add(event));

    await service.startScrape(
      username: 'test',
      password: 'pwd',
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
  });

  test('listGamesFromFiles filters out auxiliary and save files (.srm, .auto, .state, .sav, .png, etc.)', () async {
    final tempDir = await Directory.systemTemp.createTemp('titanius_roms_test_');
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
  });
}
