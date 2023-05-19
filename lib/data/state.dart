import 'dart:io';

import 'package:device_apps/device_apps.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:video_player/video_player.dart';

import 'games.dart';
import 'genres.dart';
import 'models.dart';
import 'repo.dart';
import 'stack.dart';
import 'systems.dart';

part 'state.g.dart';

@Riverpod(keepAlive: true)
class SelectedSystem extends _$SelectedSystem {
  @override
  int build() {
    return 0;
  }

  void set(int index) {
    state = index;
  }
}

@Riverpod(keepAlive: true)
class SelectedGame extends _$SelectedGame {
  @override
  Game? build(String system) {
    return null;
  }

  void set(Game game) {
    state = game;
  }

  void reset() {
    state = null;
  }
}

@Riverpod(keepAlive: true)
class SelectedApp extends _$SelectedApp {
  @override
  ApplicationWithIcon? build() {
    return null;
  }

  void set(ApplicationWithIcon app) {
    state = app;
  }
}

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

@Riverpod(keepAlive: true)
class CurrentGameNavigation extends _$CurrentGameNavigation {
  @override
  GameNavigation build(String system) {
    return GameNavigation(MyStack());
  }

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

class GameFilter {
  final String system;
  final String search;
  final bool? favourite;
  final Set<GameGenres> genres;

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
          genres.map((g) => Genres.getName(g)).join(", ")
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

@Riverpod(keepAlive: true)
class CurrentGameFilter extends _$CurrentGameFilter {
  @override
  GameFilter build(String system) {
    return GameFilter.empty(system);
  }

  void set(GameFilter filter) {
    debugPrint("set filter ${filter.description}");
    state = GameFilter(filter.system, search: filter.search, genres: filter.genres, favourite: filter.favourite);
  }
}

@Riverpod(keepAlive: true)
class TemporaryGameFilter extends _$TemporaryGameFilter {
  @override
  GameFilter build(String system) {
    return GameFilter.empty(system);
  }

  void toggleGenre(GameGenres genre) {
    final genres = state.genres;
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

@riverpod
Future<VideoPlayerController?> currentVideo(CurrentVideoRef ref, String system) {
  final game = ref.watch(selectedGameProvider(system));
  final settings = ref.watch(settingsProvider.future);
  if (game != null && game.videoUrl != null) {
    return settings.then(
      (value) {
        if (value.showGameVideos) {
          final controller = VideoPlayerController.file(File(game.videoUrl!));
          controller.setLooping(true);
          controller.setVolume(0);
          ref.onDispose(() => controller.dispose());
          return controller.initialize().then((value) {
            controller.play();
            return controller;
          });
        }
        return null;
      },
    );
  }
  return Future.value(null);
}

@Riverpod(keepAlive: true)
class DeletedGames extends _$DeletedGames {
  @override
  Set<String> build(String system) {
    return {};
  }

  void deleteGame(Game game) {
    debugPrint("Delete game ${game.romPath}");
    state = {...state, game.romPath};
  }
}

@Riverpod(keepAlive: true)
class HiddenGames extends _$HiddenGames {
  @override
  Set<String> build(String system) {
    return {};
  }

  void hideGame(Game game) {
    debugPrint("Hide game ${game.romPath}");
    state = {...state, game.romPath};
  }

  void unhideGame(Game game) {
    debugPrint("Unhide game ${game.romPath}");
    final set = {...state};
    set.remove(game.romPath);
    state = set;
  }
}

@riverpod
Future<GameList> gamesForCurrentSystem(GamesForCurrentSystemRef ref) async {
  final allSystems = await ref.watch(detectedSystemsProvider.future);
  if (allSystems.isEmpty) {
    return const GameList(systemAllGames, ".", []);
  }
  final selectedSystem = ref.watch(selectedSystemProvider);
  final system = allSystems[selectedSystem.clamp(0, allSystems.length - 1)];
  final gamelist = await ref.watch(gamesProvider(system.id).future);
  return gamelist;
}

@riverpod
Future<GameList> gamesInFolder(GamesInFolderRef ref, String system) async {
  final gamelist = await ref.watch(gamesProvider(system).future);
  final navigation = ref.watch(currentGameNavigationProvider(system));
  if (gamelist.system.isCollection) {
    return gamelist;
  } else {
    final gamesInFolder = gamelist.games.where((game) => game.folder == navigation.folder).toList();
    return GameList(gamelist.system, navigation.folder, gamesInFolder);
  }
}

@riverpod
Future<GameList> filteredGamesInFolder(FilteredGamesInFolderRef ref, String system) async {
  final gamelist = await ref.watch(gamesInFolderProvider(system).future);
  final settings = await ref.watch(settingsProvider.future);
  final filter = ref.watch(currentGameFilterProvider(system));
  final deletedGames = ref.watch(deletedGamesProvider(system));
  final hiddenGames = ref.watch(hiddenGamesProvider(system));

  gamelist.games.removeWhere((game) => deletedGames.contains(game.romPath));

  if (!settings.showHiddenGames) {
    gamelist.games.removeWhere((game) => hiddenGames.contains(game.romPath));
  }
  final games = filter.apply(gamelist.games);
  return GameList(gamelist.system, gamelist.currentFolder, games);
}
