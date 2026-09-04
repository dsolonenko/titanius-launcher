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

  RomLocation({
    required this.path,
    this.uri,
    this.documentUri,
    this.documentMime,
  });

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
  final String? category;
  final String? type;
  final Map<String, List<String>> arrayArgs;

  LaunchIntent({
    required this.target,
    required this.action,
    required this.data,
    required this.args,
    required this.flags,
    this.category,
    this.type,
    this.arrayArgs = const {},
  });

  bool get isStandalone =>
      !target.startsWith('com.retroarch') && !target.contains('retroactivity');
  bool get needsUri =>
      (data?.contains("{file.uri}") ?? false) ||
      (type?.contains("{file.uri}") ?? false);
  bool get needsDocumentUri => _hasToken("{file.documenturi}");

  bool _hasToken(String token) =>
      (data?.contains(token) ?? false) ||
      (type?.contains(token) ?? false) ||
      args.values.any((e) => e.toString().contains(token)) ||
      arrayArgs.values.any((list) => list.any((e) => e.contains(token)));

  Future<AndroidIntent> toIntent(Game game) async {
    final flags = this.flags
        .map((e) {
          switch (e) {
            case "--activity-clear-task":
              return Flag.FLAG_ACTIVITY_CLEAR_TASK;
            case "--activity-clear-top":
              return Flag.FLAG_ACTIVITY_CLEAR_TOP;
            case "--activity-no-history":
              return Flag.FLAG_ACTIVITY_NO_HISTORY;
          }
          return 0;
        })
        .where((f) => f != 0)
        .toList();
    final parts = target.split('/');
    final package = parts[0].isNotEmpty ? parts[0] : null;
    final component = parts.length > 1 && parts[1].isNotEmpty
        ? parts[1].startsWith(".")
              ? "${package ?? ''}${parts[1]}"
              : parts[1]
        : null;
    final romLocation = await _locateRom(game.absoluteRomPath);
    debugPrint("Rom location: $romLocation");
    final args = <String, dynamic>{};
    for (var k in this.args.keys) {
      final val = _tokenValue(this.args[k]?.toString(), romLocation);
      if (val != null) {
        args[k] = val;
      }
    }
    final arrayArgs = <String, List<dynamic>>{};
    for (var k in this.arrayArgs.keys) {
      final list = this.arrayArgs[k]!
          .map((e) => _tokenValue(e, romLocation) ?? e)
          .toList();
      arrayArgs[k] = list;
    }
    final intent = AndroidIntent(
      action: (action != null && action!.isNotEmpty)
          ? action!
          : 'android.intent.action.VIEW',
      package: package,
      componentName: component,
      arguments: args.isNotEmpty ? args : null,
      arrayArguments: arrayArgs.isNotEmpty ? arrayArgs : null,
      flags: flags,
      data: (data != null && data!.isNotEmpty)
          ? _tokenValue(data, romLocation, isDataUri: true)
          : null,
      category: (category != null && category!.isNotEmpty) ? category : null,
      type: (type != null && type!.isNotEmpty)
          ? _tokenValue(type, romLocation)
          : null,
    );
    return intent;
  }

  Future<RomLocation> _locateRom(String path) async {
    final uri = needsUri ? await saf.getMediaUri(path) : null;
    final document = needsDocumentUri ? await saf.getDocumentFile(path) : null;
    final documentUri =
        document?.uri.toString() ??
        (needsDocumentUri ? saf.pathToDocumentUri(path) : null);
    return RomLocation(
      path: path,
      uri: uri?.toString(),
      documentUri: documentUri,
      documentMime: document != null
          ? (document.isDir ? 'resource/folder' : 'application/octet-stream')
          : null,
    );
  }

  String? _tokenValue(
    String? v,
    RomLocation romLocation, {
    bool isDataUri = false,
  }) {
    if (v == null || v.isEmpty) return null;
    switch (v) {
      case "{file.path}":
        if (isDataUri && !romLocation.path.contains('://')) {
          return Uri.file(romLocation.path).toString();
        }
        return romLocation.path;
      case "{file.uri}":
        if (isDataUri) {
          return romLocation.uri ?? Uri.file(romLocation.path).toString();
        }
        return romLocation.path;
      case "{file.documenturi}":
        return romLocation.documentUri ??
            saf.pathToDocumentUri(romLocation.path);
      case "{file.mime}":
        return romLocation.documentMime ?? 'application/octet-stream';
      default:
        return v;
    }
  }

  static LaunchIntent parseAmStartCommand(String command) {
    String target = '';
    String? action;
    String? data;
    String? category;
    String? type;
    final Map<String, dynamic> args = {};
    final Map<String, List<String>> arrayArgs = {};
    final List<String> flags = [];

    final parts = command
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    for (int i = 0; i < parts.length; i++) {
      switch (parts[i]) {
        case 'am':
        case 'start':
          break;
        case '-n':
          if (i + 1 < parts.length) {
            target = trim(parts[i + 1]);
            i++;
          }
          break;
        case '-a':
          if (i + 1 < parts.length) {
            action = trim(parts[i + 1]);
            i++;
          }
          break;
        case '-d':
          if (i + 1 < parts.length) {
            data = trim(parts[i + 1]);
            i++;
          }
          break;
        case '-c':
          if (i + 1 < parts.length) {
            category = trim(parts[i + 1]);
            i++;
          }
          break;
        case '-t':
          if (i + 1 < parts.length) {
            type = trim(parts[i + 1]);
            i++;
          }
          break;
        case '-e':
        case '--es':
          if (i + 1 < parts.length) {
            final key = parts[i + 1];
            if (i + 2 < parts.length && !parts[i + 2].startsWith('-')) {
              args[key] = trim(parts[i + 2]);
              i += 2;
            } else {
              args[key] = '';
              i++;
            }
          }
          break;
        case '--ei':
          if (i + 1 < parts.length) {
            final key = parts[i + 1];
            if (i + 2 < parts.length && !parts[i + 2].startsWith('-')) {
              final raw = trim(parts[i + 2]);
              args[key] = int.tryParse(raw) ?? raw;
              i += 2;
            } else {
              args[key] = 0;
              i++;
            }
          }
          break;
        case '--ez':
          if (i + 1 < parts.length) {
            final key = parts[i + 1];
            if (i + 2 < parts.length && !parts[i + 2].startsWith('-')) {
              final raw = trim(parts[i + 2]);
              args[key] = raw.toLowerCase() == 'true';
              i += 2;
            } else {
              args[key] = false;
              i++;
            }
          }
          break;
        case '--esa':
          if (i + 1 < parts.length) {
            final key = parts[i + 1];
            if (i + 2 < parts.length && !parts[i + 2].startsWith('-')) {
              final raw = trim(parts[i + 2]);
              arrayArgs[key] = raw.split(',');
              i += 2;
            } else {
              arrayArgs[key] = [];
              i++;
            }
          }
          break;
        default:
          if (parts[i].startsWith('--')) {
            flags.add(parts[i]);
          }
          break;
      }
    }

    return LaunchIntent(
      target: target,
      action: action ?? '',
      data: data ?? '',
      args: args,
      flags: flags,
      category: category,
      type: type,
      arrayArgs: arrayArgs,
    );
  }

  String toAmStartCommand() {
    final buffer = StringBuffer('am start');
    if (target.isNotEmpty) buffer.write(' -n $target');
    if (action != null && action!.isNotEmpty) buffer.write(' -a $action');
    if (data != null && data!.isNotEmpty) buffer.write(' -d $data');
    if (category != null && category!.isNotEmpty) buffer.write(' -c $category');
    if (type != null && type!.isNotEmpty) buffer.write(' -t $type');
    for (final e in args.entries) {
      buffer.write(' -e ${e.key} ${e.value}');
    }
    for (final e in arrayArgs.entries) {
      buffer.write(' --esa ${e.key} ${e.value.join(",")}');
    }
    for (final f in flags) {
      buffer.write(' $f');
    }
    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LaunchIntent &&
        other.target == target &&
        other.action == action &&
        other.data == data &&
        other.category == category &&
        other.type == type &&
        mapEquals(other.args, args) &&
        mapEquals(other.arrayArgs, arrayArgs) &&
        listEquals(other.flags, flags);
  }

  @override
  int get hashCode {
    return target.hashCode ^
        action.hashCode ^
        data.hashCode ^
        category.hashCode ^
        type.hashCode ^
        args.hashCode ^
        arrayArgs.hashCode ^
        flags.hashCode;
  }

  @override
  String toString() {
    return 'LaunchIntent(target: $target, action: $action, data: $data, args: $args, flags: $flags, category: $category, type: $type, arrayArgs: $arrayArgs)';
  }
}

String trim(String s) {
  return s.replaceAll("'", '').replaceAll('"', '').trim();
}
