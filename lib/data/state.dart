import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'models.dart';

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

  void set(Game? game) {
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

@Riverpod(keepAlive: true)
class SelectedFolder extends _$SelectedFolder {
  @override
  String build(String system) {
    return ".";
  }

  void set(String folder) {
    state = folder;
  }
}

@Riverpod(keepAlive: true)
class GameScroll extends _$GameScroll {
  @override
  ScrollController build(String system) {
    return ScrollController();
  }
}
