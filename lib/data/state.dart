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

class SelectedSystemNotifier extends Notifier<int> {
  @override
  int build() => 0;

  @override
  set state(int value) => super.state = value;
}

final selectedSystemProvider = NotifierProvider<SelectedSystemNotifier, int>(
  SelectedSystemNotifier.new,
);

class SystemStatsEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void enable() => state = true;
}

final systemStatsEnabledProvider =
    NotifierProvider<SystemStatsEnabledNotifier, bool>(
      SystemStatsEnabledNotifier.new,
    );

class SelectedGameNotifier extends Notifier<Game?> {
  final String system;
  SelectedGameNotifier(this.system);

  @override
  Game? build() => null;

  @override
  set state(Game? value) => super.state = value;
}

final selectedGameProvider =
    NotifierProvider.family<SelectedGameNotifier, Game?, String>(
      SelectedGameNotifier.new,
    );

class SelectedAppNotifier extends Notifier<AppInfo?> {
  @override
  AppInfo? build() => null;

  @override
  set state(AppInfo? value) => super.state = value;
}

final selectedAppProvider = NotifierProvider<SelectedAppNotifier, AppInfo?>(
  SelectedAppNotifier.new,
);

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

class CurrentGameNavigationNotifier extends Notifier<GameNavigation> {
  final String system;
  CurrentGameNavigationNotifier(this.system);

  @override
  GameNavigation build() => GameNavigation(MyStack());

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
    NotifierProvider.family<
      CurrentGameNavigationNotifier,
      GameNavigation,
      String
    >(CurrentGameNavigationNotifier.new);

class GameFilter {
  final String system;
  final String search;
  final bool? favourite;
  final Set<GameGenre> genres;

  factory GameFilter.empty(String system) =>
      GameFilter(system, search: "", genres: {});

  GameFilter(
    this.system, {
    this.search = "",
    this.genres = const {},
    this.favourite,
  });

  bool get isEmpty => search.isEmpty && genres.isEmpty && favourite == null;

  String get description => isEmpty
      ? "All"
      : [
          favourite == null
              ? ""
              : favourite == true
              ? "Fav"
              : "Non-Fav",
          search,
          genres.map((g) => g.longName).join(", "),
        ].where((e) => e.toString().isNotEmpty).join(", ");

  List<Game> apply(List<Game> games) {
    if (isEmpty) {
      return games;
    }
    final filteredGames = [...games];
    if (search.isNotEmpty) {
      final term = search.toLowerCase();
      filteredGames.retainWhere(
        (game) => game.name.toLowerCase().contains(term),
      );
    }
    if (genres.isNotEmpty) {
      filteredGames.retainWhere(
        (game) => game.genreId != null && genres.contains(game.genreId),
      );
    }
    if (favourite != null) {
      filteredGames.retainWhere((game) => game.favorite == favourite);
    }
    return filteredGames;
  }
}

class CurrentGameFilterNotifier extends Notifier<GameFilter> {
  final String system;
  CurrentGameFilterNotifier(this.system);

  @override
  GameFilter build() {
    return GameFilter.empty(system);
  }

  void set(GameFilter filter) {
    debugPrint("set filter ${filter.description}");
    state = GameFilter(
      filter.system,
      search: filter.search,
      genres: filter.genres,
      favourite: filter.favourite,
    );
  }
}

final currentGameFilterProvider =
    NotifierProvider.family<CurrentGameFilterNotifier, GameFilter, String>(
      CurrentGameFilterNotifier.new,
    );

class TemporaryGameFilterNotifier extends Notifier<GameFilter> {
  final String system;
  TemporaryGameFilterNotifier(this.system);

  @override
  GameFilter build() {
    return GameFilter.empty(system);
  }

  void toggleGenre(GameGenre genre) {
    final genres = {...state.genres};
    if (genres.contains(genre)) {
      genres.remove(genre);
    } else {
      genres.add(genre);
    }
    state = GameFilter(
      state.system,
      search: state.search,
      genres: genres,
      favourite: state.favourite,
    );
  }

  void setSearch(String? text) {
    state = GameFilter(
      state.system,
      search: text ?? "",
      genres: state.genres,
      favourite: state.favourite,
    );
  }

  void setFavourite(bool? favourite) {
    state = GameFilter(
      state.system,
      search: state.search,
      genres: state.genres,
      favourite: favourite,
    );
  }

  void set(GameFilter filter) {
    state = filter;
  }

  void reset() {
    state = GameFilter.empty(system);
  }
}

final temporaryGameFilterProvider =
    NotifierProvider.family<TemporaryGameFilterNotifier, GameFilter, String>(
      TemporaryGameFilterNotifier.new,
    );

class TemporaryEmulatorNotifier extends Notifier<CustomEmulator> {
  @override
  CustomEmulator build() {
    return CustomEmulatorUtils.empty();
  }

  void set(CustomEmulator emulator) {
    state = emulator;
  }

  void reset() {
    state = CustomEmulatorUtils.empty();
  }
}

final temporaryEmulatorProvider =
    NotifierProvider<TemporaryEmulatorNotifier, CustomEmulator>(
      TemporaryEmulatorNotifier.new,
    );

final currentVideoProvider =
    FutureProvider.family<VideoPlayerController?, String>((ref, system) async {
      final game = ref.watch(selectedGameProvider(system));
      final showGameVideos = await ref.watch(
        settingsProvider.selectAsync((settings) => settings.showGameVideos),
      );
      if (game != null && game.videoUrl != null) {
        if (showGameVideos) {
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

class DeletedGamesNotifier extends Notifier<Set<String>> {
  final String system;
  DeletedGamesNotifier(this.system);

  @override
  Set<String> build() {
    return {};
  }

  void deleteGame(Game game) {
    debugPrint("Delete game ${game.romPath}");
    state = {...state, game.romPath};
  }
}

final deletedGamesProvider =
    NotifierProvider.family<DeletedGamesNotifier, Set<String>, String>(
      DeletedGamesNotifier.new,
    );

final gamesInFolderProvider = FutureProvider.family<GameList, String>((
  ref,
  system,
) async {
  final navigation = ref.watch(currentGameNavigationProvider(system));
  final gamelistFuture = ref.watch(gamesProvider(system).future);
  final gamelist = await gamelistFuture;
  if (gamelist.system.isCollection) {
    return gamelist;
  } else {
    final gamesInFolder = gamelist.games
        .where((game) => game.folder == navigation.folder)
        .toList();
    return GameList(
      gamelist.system,
      navigation.folder,
      gamesInFolder,
      gamelist.compare,
    );
  }
});

final filteredGamesInFolderProvider = FutureProvider.family<GameList, String>((
  ref,
  system,
) async {
  final filter = ref.watch(currentGameFilterProvider(system));
  final gamelistFuture = ref.watch(gamesInFolderProvider(system).future);
  final gamelist = await gamelistFuture;
  final games = filter.apply(gamelist.games);
  return GameList(
    gamelist.system,
    gamelist.currentFolder,
    games,
    gamelist.compare,
  );
});
