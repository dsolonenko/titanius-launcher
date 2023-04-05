import 'dart:io';

import 'package:device_apps/device_apps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:titanius/data/settings.dart';
import 'package:video_player/video_player.dart';

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

class GameNavigation {
  final Game? game;
  final MyStack<Game> folders;

  GameNavigation(this.game, this.folders);

  bool get isAtRoot => folders.isEmpty;

  bool get isGame => game != null && !game!.isFolder;

  String get folder => folders.isEmpty ? "." : folders.peek().rom;

  @override
  String toString() {
    return "{game=${game?.rom}, folder=$folder}";
  }
}

@Riverpod(keepAlive: true)
class CurrentGameNavigation extends _$CurrentGameNavigation {
  @override
  GameNavigation build(String system) {
    return GameNavigation(null, MyStack());
  }

  void selectGame(Game game) {
    state = GameNavigation(game, state.folders);
  }

  void moveIntoFolder() {
    if (state.game != null && state.game!.isFolder) {
      final folders = state.folders;
      folders.push(state.game!);
      state = GameNavigation(null, folders);
    }
  }

  void goBack() {
    final folders = state.folders;
    final game = folders.pop();
    state = GameNavigation(game, folders);
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

@riverpod
Future<VideoPlayerController?> currentVideo(
    CurrentVideoRef ref, String system) {
  final navigation = ref.watch(currentGameNavigationProvider(system));
  final settings = ref.watch(settingsProvider.future);
  if (navigation.game != null && navigation.game!.videoUrl != null) {
    return settings.then((value) {
      if (value.showGameVideos) {
        final controller =
            VideoPlayerController.file(File(navigation.game!.videoUrl!));
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
