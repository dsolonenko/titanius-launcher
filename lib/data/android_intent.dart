import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/foundation.dart';

import 'package:titanius/data/models.dart';

import 'android_saf.dart' as saf;

class RomLocation {
  String path;
  String? uri;
  String? documentUri;
  String? documentMime;

  RomLocation({required this.path, this.uri, this.documentUri, this.documentMime});

  @override
  String toString() {
    return 'RomLocation{path: $path, uri: $uri, documentUri: $documentUri, documentMime: $documentMime}';
  }
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
      return 0;
    }).toList();
    if (needsUri || needsDocumentUri) {
      flags.add(Flag.FLAG_GRANT_READ_URI_PERMISSION);
    }
    final parts = target.split('/');
    final package = parts[0];
    final component = parts.length > 1
        ? parts[1].startsWith(".")
            ? "$package${parts[1]}"
            : parts[1]
        : null;
    final romLocation = await _locateRom(game.absoluteRomPath);
    debugPrint("Rom location: $romLocation");
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
      //type: romLocation.documentMime,
    );
    return intent;
  }

  Future<RomLocation> _locateRom(String path) async {
    final uri = needsUri ? await saf.getMediaUri(path) : null;
    final document = needsDocumentUri ? await saf.getDocumentFile(path) : null;
    return RomLocation(
      path: path,
      uri: uri?.toString(),
      documentUri: document?.uri.toString(),
      documentMime: document?.type,
    );
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

  static LaunchIntent parseAmStartCommand(String command) {
    LaunchIntent intent = LaunchIntent(target: '', action: '', data: '', args: {}, flags: []);
    List<String> parts = command.split(' ');

    for (int i = 0; i < parts.length; i++) {
      switch (parts[i]) {
        case '-n':
          intent = LaunchIntent(
            target: parts[i + 1],
            action: intent.action,
            data: intent.data,
            args: intent.args,
            flags: intent.flags,
          );
          i++;
          break;
        case '-a':
          intent = LaunchIntent(
            target: intent.target,
            action: trim(parts[i + 1]),
            data: intent.data,
            args: intent.args,
            flags: intent.flags,
          );
          i++;
          break;
        case '-d':
          intent = LaunchIntent(
            target: intent.target,
            action: intent.action,
            data: trim(parts[i + 1]),
            args: intent.args,
            flags: intent.flags,
          );
          i++;
          break;
        case '-e':
          var args = intent.args;
          if (i + 2 < parts.length && parts[i + 2].startsWith('-')) {
            args[parts[i + 1]] = '';
            i++;
          } else if (i + 2 == parts.length) {
            args[parts[i + 1]] = '';
            i++;
          } else {
            args[parts[i + 1]] = parts[i + 2];
            i += 2;
          }
          intent = LaunchIntent(
            target: intent.target,
            action: intent.action,
            data: intent.data,
            args: args,
            flags: intent.flags,
          );
          break;
        default:
          if (parts[i].startsWith('--')) {
            intent = LaunchIntent(
              target: intent.target,
              action: intent.action,
              data: intent.data,
              args: intent.args,
              flags: [...intent.flags, parts[i]],
            );
          }
          break;
      }
    }

    return intent;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LaunchIntent &&
        other.target == target &&
        other.action == action &&
        other.data == data &&
        mapEquals(other.args, args) &&
        listEquals(other.flags, flags);
  }

  @override
  int get hashCode {
    return target.hashCode ^ action.hashCode ^ data.hashCode ^ args.hashCode ^ flags.hashCode;
  }

  @override
  String toString() {
    return 'LaunchIntent(target: $target, action: $action, data: $data, args: $args, flags: $flags)';
  }
}

trim(String s) {
  return s.replaceAll("'", '').replaceAll('"', '').trim();
}
