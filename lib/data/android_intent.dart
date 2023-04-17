import 'dart:async';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/services.dart';
import 'package:media_store_plus/media_store_plus.dart';

import 'models.dart';

class FileUtils {
  static const MethodChannel _channel = MethodChannel('file_utils');

  static Future<String> getUriFromPath(String path) async {
    final String uri = await _channel.invokeMethod('getUriFromPath', {'path': path});
    return uri;
  }

  static Future<String> getMimeType(String path) async {
    final String? mimeType = await _channel.invokeMethod('getMimeType', {'path': path});
    return mimeType ?? 'application/octet-stream';
  }
}

final mediaStorePlugin = MediaStore();

class LaunchIntent {
  final String target;
  final String? action;
  final String? data;
  final Map<String, dynamic> args;
  final List<String> flags;

  LaunchIntent(
      {required this.target, required this.action, required this.data, required this.args, required this.flags});

  Future<AndroidIntent> toIntent(Game selectedGame) async {
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
    final uri = await mediaStorePlugin.getUriFromFilePath(path: selectedGame.romPath);
    final args = {
      for (var k in this.args.keys) k: _value(this.args[k], selectedGame.romPath, uri),
    };
    final parts = target.split('/');
    final intent = AndroidIntent(
      action: action ?? 'action_view',
      package: parts[0],
      componentName: parts.length > 1 ? parts[1] : null,
      arguments: args,
      flags: flags,
      data: _value(data, selectedGame.romPath, uri),
    );
    return intent;
  }

  _value(String? v, String romPath, Uri? uri) {
    if (v == null) return null;
    switch (v) {
      case "{file.path}":
        return romPath;
      case "{file.uri}":
        return uri?.toString();
      default:
        return v;
    }
  }
}
