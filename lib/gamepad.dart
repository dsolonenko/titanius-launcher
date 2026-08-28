import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:gamepads/gamepads.dart' as gp;
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
  StreamSubscription<gp.NormalizedGamepadEvent>? _gamepadSub;

  // Auto-repeat state
  GamepadButton? _repeatButton;
  Timer? _initialRepeatTimer;
  Timer? _repeatIntervalTimer;

  // Analog axis state
  bool _stickLeftActive = false;
  bool _stickRightActive = false;
  bool _stickUpActive = false;
  bool _stickDownActive = false;
  bool _ltActive = false;
  bool _rtActive = false;

  @override
  void initHook() {
    super.initHook();
    HardwareKeyboard.instance.addHandler(listener);
    try {
      _gamepadSub = gp.Gamepads.normalizedEvents.listen(_handleNativeGamepadEvent);
    } catch (e) {
      debugPrint("Gamepads listener error: $e");
    }
  }

  @override
  void build(BuildContext context) {}

  @override
  void dispose() {
    _cancelRepeat();
    _gamepadSub?.cancel();
    HardwareKeyboard.instance.removeHandler(listener);
    super.dispose();
  }

  void _onButtonDown(GamepadButton button) {
    if (!context.mounted) return;
    if (FocusManager.instance.primaryFocus?.context?.widget is EditableText) {
      return;
    }
    final currentLocation = GoRouter.of(context).location;

    // If already repeating this exact button, do not re-dispatch
    if (_repeatButton == button) return;

    _cancelRepeat();
    _dispatchButton(currentLocation, button);

    // Auto-repeat for directional navigation and shoulder bumpers
    if (button == GamepadButton.up ||
        button == GamepadButton.down ||
        button == GamepadButton.left ||
        button == GamepadButton.right ||
        button == GamepadButton.l1 ||
        button == GamepadButton.r1) {
      _repeatButton = button;
      _initialRepeatTimer = Timer(const Duration(milliseconds: 260), () {
        if (_repeatButton == button && context.mounted) {
          _repeatIntervalTimer = Timer.periodic(const Duration(milliseconds: 65), (timer) {
            if (!context.mounted || _repeatButton != button) {
              timer.cancel();
              return;
            }
            _dispatchButton(GoRouter.of(context).location, button);
          });
        }
      });
    }
  }

  void _onButtonUp(GamepadButton button) {
    if (_repeatButton == button) {
      _cancelRepeat();
    }
  }

  void _cancelRepeat() {
    _repeatButton = null;
    _initialRepeatTimer?.cancel();
    _initialRepeatTimer = null;
    _repeatIntervalTimer?.cancel();
    _repeatIntervalTimer = null;
  }

  void _dispatchButton(String currentLocation, GamepadButton button) {
    hook.listener(currentLocation, button);
  }

  void _handleNativeGamepadEvent(gp.NormalizedGamepadEvent event) {
    if (!context.mounted) return;
    if (FocusManager.instance.primaryFocus?.context?.widget is EditableText) {
      return;
    }

    // Handle digital button presses & releases
    if (event.button != null) {
      final btn = _mapNativeButton(event.button!);
      if (btn != null) {
        if (event.value == 1.0) {
          _onButtonDown(btn);
        } else if (event.value == 0.0) {
          _onButtonUp(btn);
        }
      }
    }

    // Handle analog axes navigation and analog triggers
    if (event.axis != null) {
      const double threshold = 0.45;
      const double resetThreshold = 0.2;

      if (event.axis == gp.GamepadAxis.leftStickX) {
        if (event.value > threshold) {
          if (!_stickRightActive) {
            _stickRightActive = true;
            _stickLeftActive = false;
            _onButtonUp(GamepadButton.left);
            _onButtonDown(GamepadButton.right);
          }
        } else if (event.value < -threshold) {
          if (!_stickLeftActive) {
            _stickLeftActive = true;
            _stickRightActive = false;
            _onButtonUp(GamepadButton.right);
            _onButtonDown(GamepadButton.left);
          }
        } else if (event.value.abs() < resetThreshold) {
          if (_stickRightActive) {
            _stickRightActive = false;
            _onButtonUp(GamepadButton.right);
          }
          if (_stickLeftActive) {
            _stickLeftActive = false;
            _onButtonUp(GamepadButton.left);
          }
        }
      } else if (event.axis == gp.GamepadAxis.leftStickY) {
        if (event.value > threshold) {
          if (!_stickUpActive) {
            _stickUpActive = true;
            _stickDownActive = false;
            _onButtonUp(GamepadButton.down);
            _onButtonDown(GamepadButton.up);
          }
        } else if (event.value < -threshold) {
          if (!_stickDownActive) {
            _stickDownActive = true;
            _stickUpActive = false;
            _onButtonUp(GamepadButton.up);
            _onButtonDown(GamepadButton.down);
          }
        } else if (event.value.abs() < resetThreshold) {
          if (_stickUpActive) {
            _stickUpActive = false;
            _onButtonUp(GamepadButton.up);
          }
          if (_stickDownActive) {
            _stickDownActive = false;
            _onButtonUp(GamepadButton.down);
          }
        }
      } else if (event.axis == gp.GamepadAxis.leftTrigger) {
        if (event.value > 0.3) {
          if (!_ltActive) {
            _ltActive = true;
            _onButtonDown(GamepadButton.l2);
          }
        } else if (event.value < 0.15) {
          if (_ltActive) {
            _ltActive = false;
            _onButtonUp(GamepadButton.l2);
          }
        }
      } else if (event.axis == gp.GamepadAxis.rightTrigger) {
        if (event.value > 0.3) {
          if (!_rtActive) {
            _rtActive = true;
            _onButtonDown(GamepadButton.r2);
          }
        } else if (event.value < 0.15) {
          if (_rtActive) {
            _rtActive = false;
            _onButtonUp(GamepadButton.r2);
          }
        }
      }
    }
  }

  GamepadButton? _mapNativeButton(gp.GamepadButton button) {
    switch (button) {
      case gp.GamepadButton.dpadUp:
        return GamepadButton.up;
      case gp.GamepadButton.dpadDown:
        return GamepadButton.down;
      case gp.GamepadButton.dpadLeft:
        return GamepadButton.left;
      case gp.GamepadButton.dpadRight:
        return GamepadButton.right;
      case gp.GamepadButton.a:
        return GamepadButton.a;
      case gp.GamepadButton.b:
        return GamepadButton.b;
      case gp.GamepadButton.x:
        return GamepadButton.x;
      case gp.GamepadButton.y:
        return GamepadButton.y;
      case gp.GamepadButton.leftBumper:
        return GamepadButton.l1;
      case gp.GamepadButton.rightBumper:
        return GamepadButton.r1;
      case gp.GamepadButton.leftTrigger:
        return GamepadButton.l2;
      case gp.GamepadButton.rightTrigger:
        return GamepadButton.r2;
      case gp.GamepadButton.start:
        return GamepadButton.start;
      case gp.GamepadButton.back:
        return GamepadButton.select;
      default:
        return null;
    }
  }

  bool listener(KeyEvent e) {
    if (FocusManager.instance.primaryFocus?.context?.widget is EditableText) {
      return false;
    }
    final button = _mapKeyToGamepadButton(e.logicalKey);
    if (button != null) {
      if (e is KeyDownEvent) {
        _onButtonDown(button);
        return true;
      } else if (e is KeyUpEvent) {
        _onButtonUp(button);
        return true;
      } else if (e is KeyRepeatEvent) {
        // Handled by our auto-repeat timer
        return true;
      }
    } else if (e is KeyDownEvent) {
      if (e.logicalKey == LogicalKeyboardKey.audioVolumeUp) {
        FlutterVolumeController.raiseVolume(null).then((value) => debugPrint("Volume raised"));
        return true;
      } else if (e.logicalKey == LogicalKeyboardKey.audioVolumeDown) {
        FlutterVolumeController.lowerVolume(null).then((value) => debugPrint("Volume lowered"));
        return true;
      } else if (e.logicalKey == LogicalKeyboardKey.audioVolumeMute) {
        FlutterVolumeController.toggleMute().then((value) => debugPrint("Volume muted"));
        return true;
      }
    }
    return false;
  }

  GamepadButton? _mapKeyToGamepadButton(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowUp) return GamepadButton.up;
    if (key == LogicalKeyboardKey.arrowDown) return GamepadButton.down;
    if (key == LogicalKeyboardKey.arrowLeft) return GamepadButton.left;
    if (key == LogicalKeyboardKey.arrowRight) return GamepadButton.right;
    if (key == LogicalKeyboardKey.gameButtonA || key == LogicalKeyboardKey.numpad2 || key == LogicalKeyboardKey.space) {
      return GamepadButton.a;
    }
    if (key == LogicalKeyboardKey.gameButtonB ||
        key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.numpad6) {
      return GamepadButton.b;
    }
    if (key == LogicalKeyboardKey.gameButtonX || key == LogicalKeyboardKey.numpad4 || key == LogicalKeyboardKey.keyX) {
      return GamepadButton.x;
    }
    if (key == LogicalKeyboardKey.gameButtonY || key == LogicalKeyboardKey.numpad8 || key == LogicalKeyboardKey.keyY) {
      return GamepadButton.y;
    }
    if (key == LogicalKeyboardKey.gameButtonC) return GamepadButton.c;
    if (key == LogicalKeyboardKey.gameButtonZ) return GamepadButton.z;
    if (key == LogicalKeyboardKey.gameButtonLeft1) return GamepadButton.l1;
    if (key == LogicalKeyboardKey.gameButtonRight1) return GamepadButton.r1;
    if (key == LogicalKeyboardKey.gameButtonLeft2) return GamepadButton.l2;
    if (key == LogicalKeyboardKey.gameButtonRight2) return GamepadButton.r2;
    if (key == LogicalKeyboardKey.gameButtonStart || key == LogicalKeyboardKey.enter) return GamepadButton.start;
    if (key == LogicalKeyboardKey.gameButtonSelect ||
        key == LogicalKeyboardKey.insert ||
        key == LogicalKeyboardKey.tab) {
      return GamepadButton.select;
    }
    return null;
  }
}
