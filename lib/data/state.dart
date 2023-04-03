import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
