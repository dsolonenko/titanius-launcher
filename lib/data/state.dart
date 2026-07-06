import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenscraper/screenscraper.dart' show GameGenre;
import 'package:video_player/video_player.dart';

import 'package:titanius/data/games.dart';
import 'package:titanius/data/models.dart';
import 'package:titanius/data/repo.dart';
import 'package:titanius/data/stack.dart';

import 'package:installed_apps/app_info.dart';

final selectedSystemProvider = StateProvider<int>((ref) => 0);

final selectedGameProvider = StateProvider.family<Game?, String>((ref, system) => null);

final selectedAppProvider = StateProvider<AppInfo?>((ref) => null);

class GameNavigation {
  final MyStack<Game> folders;

  GameNavigation(this.folders);

  bool get isAtRoot => folders.isEmpty;

  String get folder => folders.isEmpty ? "." : folders.peek().rom;

  @override
  String toString() {
    return "{folder=$folder}";
  }
}

class CurrentGameNavigationNotifier extends StateNotifier<GameNavigation> {
  CurrentGameNavigationNotifier() : super(GameNavigation(MyStack()));

  void selectGame(Game game) {
    state = GameNavigation(state.folders);
  }

  void moveIntoFolder(Game game) {
    final folders = state.folders;
    folders.push(game);
    state = GameNavigation(folders);
  }

  Game goBack() {
    final folders = state.folders;
    final game = folders.pop();
    state = GameNavigation(folders);
    return game;
  }
}

final currentGameNavigationProvider =
    StateNotifierProvider.family<CurrentGameNavigationNotifier, GameNavigation, String>(
  (ref, system) => CurrentGameNavigationNotifier(),
);

class GameFilter {
  final String system;
  final String search;
  final bool? favourite;
  final Set<GameGenre> genres;

  factory GameFilter.empty(String system) => GameFilter(system, search: "", genres: {});

  GameFilter(this.system, {this.search = "", this.genres = const {}, this.favourite});

  get isEmpty => search.isEmpty && genres.isEmpty && favourite == null;

  get description => isEmpty
      ? "All"
      : [
          favourite == null
              ? ""
              : favourite == true
                  ? "Fav"
                  : "Non-Fav",
          search,
          genres.map((g) => g.longName).join(", ")
        ].where((e) => e.toString().isNotEmpty).join(", ");

  List<Game> apply(List<Game> games) {
    if (isEmpty) {
      return games;
    }
    final filteredGames = [...games];
    if (search.isNotEmpty) {
      final term = search.toLowerCase();
      filteredGames.retainWhere((game) => game.name.toLowerCase().contains(term));
    }
    if (genres.isNotEmpty) {
      filteredGames.retainWhere((game) => game.genreId != null && genres.contains(game.genreId));
    }
    if (favourite != null) {
      filteredGames.retainWhere((game) => game.favorite == favourite);
    }
    return filteredGames;
  }
}

class CurrentGameFilterNotifier extends StateNotifier<GameFilter> {
  final String system;
  CurrentGameFilterNotifier(this.system) : super(GameFilter.empty(system));

  void set(GameFilter filter) {
    debugPrint("set filter ${filter.description}");
    state = GameFilter(filter.system, search: filter.search, genres: filter.genres, favourite: filter.favourite);
  }
}

final currentGameFilterProvider =
    StateNotifierProvider.family<CurrentGameFilterNotifier, GameFilter, String>(
  (ref, system) => CurrentGameFilterNotifier(system),
);

class TemporaryGameFilterNotifier extends StateNotifier<GameFilter> {
  final String system;
  TemporaryGameFilterNotifier(this.system) : super(GameFilter.empty(system));

  void toggleGenre(GameGenre genre) {
    final genres = {...state.genres};
    if (genres.contains(genre)) {
      genres.remove(genre);
    } else {
      genres.add(genre);
    }
    state = GameFilter(state.system, search: state.search, genres: genres, favourite: state.favourite);
  }

  void setSearch(String? text) {
    state = GameFilter(state.system, search: text ?? "", genres: state.genres, favourite: state.favourite);
  }

  void setFavourite(bool? favourite) {
    state = GameFilter(state.system, search: state.search, genres: state.genres, favourite: favourite);
  }

  void set(GameFilter filter) {
    state = filter;
  }

  void reset() {
    state = GameFilter.empty(system);
  }
}

final temporaryGameFilterProvider =
    StateNotifierProvider.family<TemporaryGameFilterNotifier, GameFilter, String>(
  (ref, system) => TemporaryGameFilterNotifier(system),
);

class TemporaryEmulatorNotifier extends StateNotifier<CustomEmulator> {
  TemporaryEmulatorNotifier() : super(CustomEmulatorUtils.empty());

  void set(CustomEmulator emulator) {
    state = emulator;
  }

  void reset() {
    state = CustomEmulatorUtils.empty();
  }
}

final temporaryEmulatorProvider = StateNotifierProvider<TemporaryEmulatorNotifier, CustomEmulator>(
  (ref) => TemporaryEmulatorNotifier(),
);

final currentVideoProvider = FutureProvider.family<VideoPlayerController?, String>((ref, system) async {
  final game = ref.watch(selectedGameProvider(system));
  final settings = await ref.watch(settingsProvider.future);
  if (game != null && game.videoUrl != null) {
    if (settings.showGameVideos) {
      final controller = VideoPlayerController.file(File(game.videoUrl!));
      controller.setLooping(true);
      controller.setVolume(0);
      ref.onDispose(() => controller.dispose());
      await controller.initialize();
      controller.play();
      return controller;
    }
  }
  return null;
});

class DeletedGamesNotifier extends StateNotifier<Set<String>> {
  DeletedGamesNotifier() : super({});

  void deleteGame(Game game) {
    debugPrint("Delete game ${game.romPath}");
    state = {...state, game.romPath};
  }
}

final deletedGamesProvider = StateNotifierProvider.family<DeletedGamesNotifier, Set<String>, String>(
  (ref, system) => DeletedGamesNotifier(),
);

final gamesForCurrentSystemProvider = FutureProvider<GameList>((ref) async {
  final allSystems = await ref.watch(loadedSystemsProvider.future);
  if (allSystems.isEmpty) {
    return const GameList(
      systemAllGames,
      ".",
      [],
      null,
    );
  }
  final selectedSystem = ref.watch(selectedSystemProvider);
  final system = allSystems[selectedSystem.clamp(0, allSystems.length - 1)];
  final gamelist = await ref.watch(gamesProvider(system.id).future);
  return gamelist;
});

final gamesInFolderProvider = FutureProvider.family<GameList, String>((ref, system) async {
  final gamelist = await ref.watch(gamesProvider(system).future);
  final navigation = ref.watch(currentGameNavigationProvider(system));
  if (gamelist.system.isCollection) {
    return gamelist;
  } else {
    final gamesInFolder = gamelist.games.where((game) => game.folder == navigation.folder).toList();
    return GameList(gamelist.system, navigation.folder, gamesInFolder, gamelist.compare);
  }
});

final filteredGamesInFolderProvider = FutureProvider.family<GameList, String>((ref, system) async {
  final gamelist = await ref.watch(gamesInFolderProvider(system).future);
  final filter = ref.watch(currentGameFilterProvider(system));
  final games = filter.apply(gamelist.games);
  return GameList(gamelist.system, gamelist.currentFolder, games, gamelist.compare);
});
