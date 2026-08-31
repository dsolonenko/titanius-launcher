import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:titanius/data/repo.dart';
import 'package:titanius/data/storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'selection repositories emit database changes without refreshes',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final settings = SettingsRepo(db);
      final enabledSystems = EnabledSystemsRepo(db);
      final apps = AndroidAppsRepo(db);
      final romFolders = RomFoldersRepo(db);
      addTearDown(db.close);

      final scraperStream = StreamIterator(settings.watchScrapeTheseSystems());
      expect(await scraperStream.moveNext(), isTrue);
      expect(scraperStream.current, isEmpty);
      await settings.setScrapeTheseSystems(['nes']);
      expect(await scraperStream.moveNext(), isTrue);
      expect(scraperStream.current, {'nes'});
      await scraperStream.cancel();

      final systemsStream = StreamIterator(
        enabledSystems.watchEnabledSystems(),
      );
      expect(await systemsStream.moveNext(), isTrue);
      expect(systemsStream.current.showSystem('no_metadata'), isFalse);
      await enabledSystems.setShowSystem('no_metadata', true);
      expect(await systemsStream.moveNext(), isTrue);
      expect(systemsStream.current.showSystem('no_metadata'), isTrue);
      await systemsStream.cancel();

      final appsStream = StreamIterator(apps.watchSelectedApps());
      expect(await appsStream.moveNext(), isTrue);
      expect(appsStream.current.isSelected('example.game'), isFalse);
      await apps.selectApp('example.game', true);
      expect(await appsStream.moveNext(), isTrue);
      expect(appsStream.current.isSelected('example.game'), isTrue);
      await appsStream.cancel();

      final initialFolders = await romFolders.getRomFolders();
      final foldersStream = StreamIterator(romFolders.watchRomFolders());
      expect(await foldersStream.moveNext(), isTrue);
      expect(foldersStream.current, initialFolders);
      await romFolders.saveRomsFolders(['/roms']);
      expect(await foldersStream.moveNext(), isTrue);
      expect(foldersStream.current, ['/roms']);
      await foldersStream.cancel();
    },
  );

  test('CSV selection writer preserves rapid toggle order', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
    });

    final writer = container.read(scrapeTheseSystemsWriterProvider);
    writer.toggle(const {}, 'nes');
    writer.toggle(const {}, 'snes');
    writer.toggle(const {}, 'nes');
    await writer.waitForPersistence();

    expect(
      (await container.read(settingsRepoProvider).getSettings())
          .scrapeTheseSystems,
      ['snes'],
    );
  });
}
