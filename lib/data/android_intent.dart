import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:async_task/async_task_extension.dart';
import 'package:flutter/material.dart';

import 'models.dart';
import 'android_saf.dart' as saf;

class LaunchIntent {
  final String target;
  final String? action;
  final String? data;
  final Map<String, dynamic> args;
  final List<String> flags;

  LaunchIntent(
      {required this.target, required this.action, required this.data, required this.args, required this.flags});

  bool get isStandalone => !target.startsWith('com.retroarch.aarch64/');

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
    final parts = target.split('/');
    final package = parts[0];
    final component = parts.length > 1
        ? parts[1].startsWith(".")
            ? "$package${parts[1]}"
            : parts[1]
        : null;
    final documentFile = isStandalone ? await saf.getDocumentFile(game.romPath) : null;
    debugPrint("path: ${game.romPath} uri: ${documentFile?.uri.toString()} mime: ${documentFile?.type}");
    final args = {
      for (var k in this.args.keys) k: _value(this.args[k], game.romPath, documentFile?.uri.toString()),
    };
    final intent = AndroidIntent(
      action: action ?? 'action_view',
      package: parts[0],
      componentName: component,
      arguments: args,
      flags: flags,
      data: _value(data, game.romPath, documentFile?.uri.toString()),
      type: documentFile?.type,
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
