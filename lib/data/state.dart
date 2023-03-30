import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

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
  int build(String system) {
    return 0;
  }

  void set(int index) {
    state = index;
  }
}

@Riverpod(keepAlive: true)
class GameScroll extends _$GameScroll {
  @override
  ItemScrollController build(String system) {
    return ItemScrollController();
  }
}
