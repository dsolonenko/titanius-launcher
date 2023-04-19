import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:async_task/async_task_extension.dart';
import 'package:flutter/material.dart';

import 'models.dart';
import 'android_saf.dart' as saf;

class RomLocation {
  String path;
  String? uri;
  String? documentUri;
  String? documentMime;

  RomLocation({required this.path, this.uri, this.documentUri, this.documentMime});
}

class LaunchIntent {
  final String target;
  final String? action;
  final String? data;
  final Map<String, dynamic> args;
  final List<String> flags;

  LaunchIntent(
      {required this.target, required this.action, required this.data, required this.args, required this.flags});

  bool get isStandalone => !target.startsWith('com.retroarch.aarch64/');
  bool get needsUri => _hasToken("{file.uri}");
  bool get needsDocumentUri => _hasToken("{file.documenturi}");

  bool _hasToken(String token) => data?.contains(token) ?? args.values.any((e) => e.toString().contains(token));

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
    final romLocation = await _locateRom(game.romPath);
    final args = {
      for (var k in this.args.keys) k: _tokenValue(this.args[k], romLocation),
    };
    final intent = AndroidIntent(
      action: action ?? 'action_view',
      package: parts[0],
      componentName: component,
      arguments: args,
      flags: flags,
      data: _tokenValue(data, romLocation),
      type: romLocation.documentMime,
    );
    return intent;
  }

  Future<RomLocation> _locateRom(String path) async {
    final uri = needsUri ? await saf.getMediaUri(path) : null;
    final document = needsDocumentUri ? await saf.getDocumentFile(path) : null;
    return RomLocation(
        path: path, uri: uri?.toString(), documentUri: document?.uri.toString(), documentMime: document?.type);
  }

  _tokenValue(String? v, RomLocation romLocation) {
    if (v == null) return null;
    switch (v) {
      case "{file.path}":
        return romLocation.path;
      case "{file.uri}":
        return romLocation.uri;
      case "{file.documenturi}":
        return romLocation.documentUri;
      default:
        return v;
    }
  }
}
