import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:go_router/go_router.dart';

enum GamepadButton {
  up,
  down,
  upDown,
  left,
  right,
  leftRight,
  a,
  b,
  x,
  y,
  c,
  z,
  l1,
  l2,
  r1,
  r2,
  start,
  select,
}

extension GoRouterLocation on GoRouter {
  String get location {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList =
        lastMatch is ImperativeRouteMatch ? lastMatch.matches : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}

void useGamepad(WidgetRef ref, void Function(String location, GamepadButton key) listener) {
  return use(_GamepadHook(listener));
}

class _GamepadHook extends Hook<void> {
  final void Function(String location, GamepadButton key) listener;
  const _GamepadHook(this.listener);

  @override
  _GamepadHookState createState() => _GamepadHookState();
}

class _GamepadHookState extends HookState<void, _GamepadHook> {
  @override
  void initHook() {
    super.initHook();
    HardwareKeyboard.instance.addHandler(listener);
  }

  @override
  void build(BuildContext context) {}

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(listener);
    super.dispose();
  }

  bool listener(KeyEvent e) {
    String currentLocation = GoRouter.of(context).location;
    if (e is KeyDownEvent) {
      debugPrint("Gamepad down $currentLocation: ${e.logicalKey}");
      if (e.logicalKey == LogicalKeyboardKey.arrowUp) {
        hook.listener(currentLocation, GamepadButton.up);
      } else if (e.logicalKey == LogicalKeyboardKey.arrowDown) {
        hook.listener(currentLocation, GamepadButton.down);
      } else if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
        hook.listener(currentLocation, GamepadButton.left);
      } else if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
        hook.listener(currentLocation, GamepadButton.right);
      } else if (e.logicalKey == LogicalKeyboardKey.gameButtonA || e.logicalKey == LogicalKeyboardKey.numpad2) {
        hook.listener(currentLocation, GamepadButton.a);
      } else if (e.logicalKey == LogicalKeyboardKey.gameButtonB ||
          e.logicalKey == LogicalKeyboardKey.backspace ||
          e.logicalKey == LogicalKeyboardKey.numpad6) {
        hook.listener(currentLocation, GamepadButton.b);
      } else if (e.logicalKey == LogicalKeyboardKey.gameButtonX ||
          e.logicalKey == LogicalKeyboardKey.numpad4 ||
          e.logicalKey == LogicalKeyboardKey.keyX) {
        hook.listener(currentLocation, GamepadButton.x);
      } else if (e.logicalKey == LogicalKeyboardKey.gameButtonY ||
          e.logicalKey == LogicalKeyboardKey.numpad8 ||
          e.logicalKey == LogicalKeyboardKey.keyY) {
        hook.listener(currentLocation, GamepadButton.y);
      } else if (e.logicalKey == LogicalKeyboardKey.gameButtonC) {
        hook.listener(currentLocation, GamepadButton.c);
      } else if (e.logicalKey == LogicalKeyboardKey.gameButtonZ) {
        hook.listener(currentLocation, GamepadButton.z);
      } else if (e.logicalKey == LogicalKeyboardKey.gameButtonLeft1) {
        hook.listener(currentLocation, GamepadButton.l1);
      } else if (e.logicalKey == LogicalKeyboardKey.gameButtonRight1) {
        hook.listener(currentLocation, GamepadButton.r1);
      } else if (e.logicalKey == LogicalKeyboardKey.gameButtonLeft2) {
        hook.listener(currentLocation, GamepadButton.l2);
      } else if (e.logicalKey == LogicalKeyboardKey.gameButtonRight2) {
        hook.listener(currentLocation, GamepadButton.r2);
      } else if (e.logicalKey == LogicalKeyboardKey.gameButtonStart || e.logicalKey == LogicalKeyboardKey.enter) {
        hook.listener(currentLocation, GamepadButton.start);
      } else if (e.logicalKey == LogicalKeyboardKey.gameButtonSelect ||
          e.logicalKey == LogicalKeyboardKey.insert ||
          e.logicalKey == LogicalKeyboardKey.tab) {
        hook.listener(currentLocation, GamepadButton.select);
      } else if (e.logicalKey == LogicalKeyboardKey.audioVolumeUp) {
        FlutterVolumeController.raiseVolume(null).then((value) => debugPrint("Volume raised"));
      } else if (e.logicalKey == LogicalKeyboardKey.audioVolumeDown) {
        FlutterVolumeController.lowerVolume(null).then((value) => debugPrint("Volume lowered"));
      } else if (e.logicalKey == LogicalKeyboardKey.audioVolumeMute) {
        FlutterVolumeController.toggleMute().then((value) => debugPrint("Volume muted"));
      }
    } else if (e is KeyRepeatEvent) {
      debugPrint("Gamepad repeat ${e.logicalKey}");
      if (e.logicalKey == LogicalKeyboardKey.arrowLeft) {
        hook.listener(currentLocation, GamepadButton.left);
      } else if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
        hook.listener(currentLocation, GamepadButton.right);
      } else if (e.logicalKey == LogicalKeyboardKey.gameButtonLeft1) {
        hook.listener(currentLocation, GamepadButton.l1);
      } else if (e.logicalKey == LogicalKeyboardKey.gameButtonRight1) {
        hook.listener(currentLocation, GamepadButton.r1);
      } else if (e.logicalKey == LogicalKeyboardKey.gameButtonLeft2) {
        hook.listener(currentLocation, GamepadButton.l2);
      } else if (e.logicalKey == LogicalKeyboardKey.gameButtonRight2) {
        hook.listener(currentLocation, GamepadButton.r2);
      } else if (e.logicalKey == LogicalKeyboardKey.audioVolumeUp) {
        FlutterVolumeController.raiseVolume(null).then((value) => debugPrint("Volume raised"));
      } else if (e.logicalKey == LogicalKeyboardKey.audioVolumeDown) {
        FlutterVolumeController.lowerVolume(null).then((value) => debugPrint("Volume lowered"));
      }
    }
    return true;
  }
}
