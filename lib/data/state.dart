import 'dart:io';

import 'package:device_apps/device_apps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:titanius/data/repo.dart';
import 'package:video_player/video_player.dart';

import 'games.dart';
import 'models.dart';
import 'stack.dart';

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
  final String? search;
  final Set<String>? genres;

  factory GameFilter.empty(String system) => GameFilter(system, search: null, genres: null);

  GameFilter(this.system, {this.search, this.genres});

  List<Game> apply(List<Game> games) {
    if (search != null) {
      final term = search!.toLowerCase();
      games.retainWhere((game) => game.name.toLowerCase().contains(term));
    }
    if (genres != null) {
      games.retainWhere((game) => game.genre != null && genres!.contains(game.genre));
    }
    return games;
  }
}

@Riverpod(keepAlive: true)
class CurrentGameFilter extends _$CurrentGameFilter {
  @override
  GameFilter build(String system) {
    return GameFilter.empty(system);
  }

  void set(GameFilter filter) {
    state = filter;
  }
}

@riverpod
Future<VideoPlayerController?> currentVideo(CurrentVideoRef ref, String system) {
  final game = ref.watch(selectedGameProvider(system));
  final settings = ref.watch(settingsProvider.future);
  if (game != null && game.videoUrl != null) {
    return settings.then((value) {
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
    });
  }
  return Future.value(null);
}

@riverpod
Future<GameList> gamesInFolder(GamesInFolderRef ref, String system) async {
  final gamelist = await ref.watch(gamesProvider(system).future);
  final navigation = ref.watch(currentGameNavigationProvider(system));
  final filter = ref.watch(currentGameFilterProvider(system));
  if (gamelist.system.isCollection) {
    final games = filter.apply(gamelist.games);
    return GameList(gamelist.system, navigation.folder, games);
  } else {
    final gamesInFolder = gamelist.games.where((game) => game.folder == navigation.folder).toList();
    final games = filter.apply(gamesInFolder);
    return GameList(gamelist.system, navigation.folder, games);
  }
}
