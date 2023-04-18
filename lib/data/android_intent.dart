import 'dart:async';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'models.dart';

class LaunchIntent {
  final String target;
  final String? action;
  final String? data;
  final Map<String, dynamic> args;
  final List<String> flags;

  LaunchIntent(
      {required this.target, required this.action, required this.data, required this.args, required this.flags});

  Future<AndroidIntent> toIntent(Game game) async {
    final flags = this.flags.map((e) {
      switch (e) {
        case "--activity-clear-task":
          return Flag.FLAG_ACTIVITY_CLEAR_TASK;
        case "--activity-clear-top":
          return Flag.FLAG_ACTIVITY_CLEAR_TOP;
        case "--activity-no-history":
          return Flag.FLAG_ACTIVITY_NO_HISTORY;
      }
      return Flag.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS;
    }).toList();
    if (data != null) {
      flags.add(Flag.FLAG_GRANT_READ_URI_PERMISSION);
    }
    final uri = await _getContentUri(game.romPath);
    debugPrint("path: ${game.romPath} uri: $uri");
    final args = {
      for (var k in this.args.keys) k: _value(this.args[k], game.romPath, uri),
    };
    final parts = target.split('/');
    final intent = AndroidIntent(
      action: action ?? 'action_view',
      package: parts[0],
      componentName: parts.length > 1 ? parts[1] : null,
      arguments: args,
      flags: flags,
      data: _value(data, game.romPath, uri),
    );
    return intent;
  }

  _value(String? v, String romPath, String? uri) {
    if (v == null) return null;
    switch (v) {
      case "{file.path}":
        return romPath;
      case "{file.uri}":
        return uri;
      default:
        return v;
    }
  }
}

const platform = MethodChannel('file_utils');

Future<String?> _getContentUri(String filePath) async {
  try {
    final String contentUri = await platform.invokeMethod('getContentUri', {'path': filePath});
    return contentUri;
  } on PlatformException catch (e) {
    debugPrint('Error: ${e.message}');
    return null;
  }
}
