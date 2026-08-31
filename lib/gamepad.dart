import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamepads/gamepads.dart' as gp;
import 'package:go_router/go_router.dart';
import 'package:titanius/data/models.dart';
import 'package:titanius/data/repo.dart';

enum GamepadButton {
  up,
  down,
  upDown,
  left,
  right,
  leftRight,
  rightStickUp,
  rightStickDown,
  confirm,
  back,
  x,
  y,
  c,
  z,
  l1,
  l2,
  l3,
  r1,
  r2,
  r3,
  start,
  select,
}

enum FaceButtonPosition { south, east, west, north }

enum FaceButtonLabel { a, b, x, y }

FaceButtonPosition confirmButtonPosition(
  ControllerLayout layout,
  bool swapConfirm,
) {
  final defaultPosition =
      layout == ControllerLayout.nintendo || layout == ControllerLayout.retro
      ? FaceButtonPosition.east
      : FaceButtonPosition.south;
  if (!swapConfirm) return defaultPosition;
  return defaultPosition == FaceButtonPosition.east
      ? FaceButtonPosition.south
      : FaceButtonPosition.east;
}

GamepadButton mapLabeledFaceButton(FaceButtonLabel button, bool swapConfirm) {
  switch (button) {
    case FaceButtonLabel.a:
      return swapConfirm ? GamepadButton.back : GamepadButton.confirm;
    case FaceButtonLabel.b:
      return swapConfirm ? GamepadButton.confirm : GamepadButton.back;
    case FaceButtonLabel.x:
      return GamepadButton.x;
    case FaceButtonLabel.y:
      return GamepadButton.y;
  }
}

extension GoRouterLocation on GoRouter {
  String get location {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.path;
  }
}

typedef GamepadListener = void Function(String location, GamepadButton key);
typedef GamepadChordListener = void Function(
  String location,
  GamepadButton key,
  Set<GamepadButton> pressed,
);

void useGamepad(
  WidgetRef ref,
  GamepadListener listener,
) {
  final settings = ref.watch(settingsProvider).value;
  return use(
    _GamepadHook(
      (loc, key, pressed) => listener(loc, key),
      swapConfirm: settings?.swapConfirm ?? false,
    ),
  );
}

void useGamepadChord(
  WidgetRef ref,
  GamepadChordListener listener,
) {
  final settings = ref.watch(settingsProvider).value;
  return use(
    _GamepadHook(listener, swapConfirm: settings?.swapConfirm ?? false),
  );
}

class _GamepadHook extends Hook<void> {
  final GamepadChordListener listener;
  final bool swapConfirm;
  const _GamepadHook(this.listener, {this.swapConfirm = false});

  @override
  _GamepadHookState createState() => _GamepadHookState();
}

class _GamepadHookState extends HookState<void, _GamepadHook> {
  StreamSubscription<gp.NormalizedGamepadEvent>? _gamepadSub;

  // Auto-repeat state
  GamepadButton? _repeatButton;
  Timer? _initialRepeatTimer;
  Timer? _repeatIntervalTimer;
  final Set<GamepadButton> _pressedButtons = {};
  final Map<gp.GamepadButton, GamepadButton> _pressedNativeButtons = {};

  // Analog axis state
  bool _stickLeftActive = false;
  bool _stickRightActive = false;
  bool _stickUpActive = false;
  bool _stickDownActive = false;
  bool _rightStickUpActive = false;
  bool _rightStickDownActive = false;
  String? _activeRightStickYAxisKey;
  bool _ltActive = false;
  bool _rtActive = false;

  @override
  void initHook() {
    super.initHook();
    try {
      _gamepadSub = gp.Gamepads.normalizedEvents.listen(
        _handleNativeGamepadEvent,
      );
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
    super.dispose();
  }

  void _onButtonDown(GamepadButton button) {
    if (!context.mounted) return;
    if (FocusManager.instance.primaryFocus?.context?.widget is EditableText) {
      return;
    }
    final currentLocation = GoRouter.of(context).location;

    // Some controllers emit multiple value=1 events while held. Treat the
    // press as an edge and let our single repeat timer own held navigation.
    if (!_pressedButtons.add(button)) return;

    _cancelRepeat();
    _dispatchButton(currentLocation, button);

    // Auto-repeat for directional navigation and shoulder bumpers
    if (button == GamepadButton.up ||
        button == GamepadButton.down ||
        button == GamepadButton.left ||
        button == GamepadButton.right ||
        button == GamepadButton.rightStickUp ||
        button == GamepadButton.rightStickDown ||
        button == GamepadButton.l1 ||
        button == GamepadButton.r1) {
      _repeatButton = button;
      _initialRepeatTimer = Timer(const Duration(milliseconds: 260), () {
        if (_repeatButton == button && context.mounted) {
          _repeatIntervalTimer = Timer.periodic(
            const Duration(milliseconds: 65),
            (timer) {
              if (!context.mounted || _repeatButton != button) {
                timer.cancel();
                return;
              }
              _dispatchButton(GoRouter.of(context).location, button);
            },
          );
        }
      });
    }
  }

  void _onButtonUp(GamepadButton button) {
    _pressedButtons.remove(button);
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
    hook.listener(currentLocation, button, Set.unmodifiable(_pressedButtons));
  }

  void _handleNativeGamepadEvent(gp.NormalizedGamepadEvent event) {
    if (!context.mounted) return;

    // Handle digital button presses & releases
    if (event.button != null) {
      final nativeButton = event.button!;
      if (event.value == 1.0) {
        // Suppress repeated native down events before remapping. A setting
        // change while held can otherwise turn the same physical press into a
        // different semantic action.
        if (_pressedNativeButtons.containsKey(nativeButton)) return;
        final btn = _mapNativeButton(nativeButton);
        if (btn != null) {
          _pressedNativeButtons[nativeButton] = btn;
          _onButtonDown(btn);
        }
      } else if (event.value == 0.0) {
        // Layout/swap can change in response to the press. Release the action
        // captured on button-down instead of remapping with the new setting.
        final btn =
            _pressedNativeButtons.remove(nativeButton) ??
            _mapNativeButton(nativeButton);
        if (btn != null) {
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
      } else if (event.axis == gp.GamepadAxis.rightStickY) {
        final rawAxisKey = event.rawEvent.key;
        if (event.value.abs() > threshold) {
          _activeRightStickYAxisKey = rawAxisKey;
        } else if (_activeRightStickYAxisKey != null &&
            _activeRightStickYAxisKey != rawAxisKey) {
          return;
        }
        if (event.value > threshold) {
          if (!_rightStickUpActive) {
            _rightStickUpActive = true;
            _rightStickDownActive = false;
            _onButtonUp(GamepadButton.rightStickDown);
            _onButtonDown(GamepadButton.rightStickUp);
          }
        } else if (event.value < -threshold) {
          if (!_rightStickDownActive) {
            _rightStickDownActive = true;
            _rightStickUpActive = false;
            _onButtonUp(GamepadButton.rightStickUp);
            _onButtonDown(GamepadButton.rightStickDown);
          }
        } else if (event.value.abs() < resetThreshold) {
          _activeRightStickYAxisKey = null;
          if (_rightStickUpActive) {
            _rightStickUpActive = false;
            _onButtonUp(GamepadButton.rightStickUp);
          }
          if (_rightStickDownActive) {
            _rightStickDownActive = false;
            _onButtonUp(GamepadButton.rightStickDown);
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
        return mapLabeledFaceButton(FaceButtonLabel.a, hook.swapConfirm);
      case gp.GamepadButton.b:
        return mapLabeledFaceButton(FaceButtonLabel.b, hook.swapConfirm);
      case gp.GamepadButton.x:
        return mapLabeledFaceButton(FaceButtonLabel.x, hook.swapConfirm);
      case gp.GamepadButton.y:
        return mapLabeledFaceButton(FaceButtonLabel.y, hook.swapConfirm);
      case gp.GamepadButton.leftBumper:
        return GamepadButton.l1;
      case gp.GamepadButton.rightBumper:
        return GamepadButton.r1;
      case gp.GamepadButton.leftTrigger:
        return GamepadButton.l2;
      case gp.GamepadButton.rightTrigger:
        return GamepadButton.r2;
      case gp.GamepadButton.leftStick:
        return GamepadButton.l3;
      case gp.GamepadButton.rightStick:
        return GamepadButton.r3;
      case gp.GamepadButton.start:
        return GamepadButton.start;
      case gp.GamepadButton.back:
        return GamepadButton.select;
      default:
        return null;
    }
  }
}
