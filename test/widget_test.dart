import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titanius/data/models.dart';
import 'package:titanius/data/repo.dart';
import 'package:titanius/data/state.dart';

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
}
