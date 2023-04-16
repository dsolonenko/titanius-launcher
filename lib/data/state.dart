import 'dart:io';

import 'package:device_apps/device_apps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:titanius/data/settings.dart';
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
  if (system == "all") {
    final roms = <String>{};
    final uniqueGames = gamelist.games.where((element) => !element.isFolder).toList();
    uniqueGames.retainWhere((game) => roms.add("${game.system.id}/${game.name}"));
    return GameList(gamelist.system, ".", uniqueGames);
  } else {
    final navigation = ref.watch(currentGameNavigationProvider(system));
    final gamesInFolder = gamelist.games.where((game) => game.folder == navigation.folder).toList();
    return GameList(gamelist.system, navigation.folder, gamesInFolder);
  }
}
