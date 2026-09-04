import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/foundation.dart';
import 'package:titanius/data/android_saf.dart' as saf;
import 'package:titanius/data/models.dart';

/// Dedicated launcher for Daijishō player definitions.
///
/// Follows Daijishō's native engine (`AmStartCommandToIntentConverter` and
/// `DaijishouLibraryModel->playIt`) to ensure 100% compatibility with
/// Daijishō platform player definitions without mixing with built-in Titanius rules.
class DaijishoLauncher {
  /// Launches the given [game] with a Daijishō [emulator].
  static Future<void> launch(Emulator emulator, Game game) async {
    final intent = await createIntent(emulator, game);
    debugPrint("DaijishoLauncher launching intent: $intent");
    await intent.launch();
  }

  /// Creates an [AndroidIntent] for the given [emulator] and [game].
  static Future<AndroidIntent> createIntent(
    Emulator emulator,
    Game game,
  ) async {
    final command =
        emulator.amStartArguments ?? emulator.intent.toAmStartCommand();
    return createIntentFromCommand(command, game);
  }

  /// Converts a Daijishō `am start` command template and [game] into an [AndroidIntent].
  static Future<AndroidIntent> createIntentFromCommand(
    String commandTemplate,
    Game game,
  ) async {
    final filePath = game.absoluteRomPath;
    final documentUri = await saf.resolveDocumentUri(
      filePath,
      systemFolder: game.systemFolder,
    );
    final dptTags = await _readDptTags(filePath);

    // Step 1: Tokenize by whitespace/newlines (matching Daijishō Regex(r"[\n\s]+"))
    final rawTokens = commandTemplate
        .trim()
        .split(RegExp(r'[\n\s]+'))
        .where((t) => t.isNotEmpty)
        .toList();

    // Step 2: Prepare token replacements matching Daijishō's token list
    final replacements = <MapEntry<String, String>>[
      MapEntry('"{file.path}"', filePath),
      MapEntry('{file.path}', filePath),
      MapEntry('"{file.uri}"', documentUri),
      MapEntry('{file.uri}', documentUri),
      MapEntry('"{file.documenturi}"', documentUri),
      MapEntry('{file.documenturi}', documentUri),
      for (final entry in dptTags.entries) ...[
        MapEntry('"{tags.${entry.key}}"', entry.value),
        MapEntry('{tags.${entry.key}}', entry.value),
      ],
    ];

    // Apply token replacement to each token and strip outer quotes if present
    final tokens = rawTokens.map((token) {
      for (final r in replacements) {
        token = token.replaceAll(r.key, r.value);
      }
      if ((token.startsWith('"') && token.endsWith('"')) ||
          (token.startsWith("'") && token.endsWith("'"))) {
        if (token.length >= 2) {
          token = token.substring(1, token.length - 1);
        }
      }
      return token;
    }).toList();

    // Step 3: Parse arguments into Intent components (matching AmStartCommandToIntentConverter)
    String? package;
    String? componentName;
    String? action;
    String? category;
    String? data;
    String? type;
    final args = <String, dynamic>{};
    final arrayArgs = <String, List<dynamic>>{};
    final flags = <int>[
      Flag.FLAG_ACTIVITY_NEW_TASK, // 0x10000000 (always added by Daijishō)
    ];

    int i = 0;
    while (i < tokens.length) {
      final opt = tokens[i++];
      switch (opt) {
        case 'am':
        case 'start':
          break;
        case '-n':
          if (i < tokens.length) {
            final target = tokens[i++];
            final slash = target.indexOf('/');
            if (slash != -1) {
              package = target.substring(0, slash);
              final cls = target.substring(slash + 1);
              componentName = cls.startsWith('.') ? '$package$cls' : cls;
            } else {
              componentName = target;
            }
          }
          break;
        case '-p':
          if (i < tokens.length) {
            package = tokens[i++];
          }
          break;
        case '-a':
          if (i < tokens.length) {
            action = tokens[i++];
          }
          break;
        case '-c':
          if (i < tokens.length) {
            category = tokens[i++];
          }
          break;
        case '-d':
          if (i < tokens.length) {
            data = tokens[i++];
          }
          break;
        case '-t':
          if (i < tokens.length) {
            type = tokens[i++];
          }
          break;
        case '-e':
        case '--es':
          if (i + 1 < tokens.length) {
            final k = tokens[i++];
            final v = tokens[i++];
            args[k] = v;
          } else if (i < tokens.length) {
            args[tokens[i++]] = '';
          }
          break;
        case '--ei':
          if (i + 1 < tokens.length) {
            final k = tokens[i++];
            final v = tokens[i++];
            args[k] = int.tryParse(v) ?? 0;
          }
          break;
        case '--el':
          if (i + 1 < tokens.length) {
            final k = tokens[i++];
            final v = tokens[i++];
            args[k] = int.tryParse(v) ?? 0;
          }
          break;
        case '--ef':
          if (i + 1 < tokens.length) {
            final k = tokens[i++];
            final v = tokens[i++];
            args[k] = double.tryParse(v) ?? 0.0;
          }
          break;
        case '--ez':
          if (i + 1 < tokens.length) {
            final k = tokens[i++];
            final v = tokens[i++].toLowerCase();
            args[k] = (v == 'true' || v == 't');
          }
          break;
        case '--eu':
          if (i + 1 < tokens.length) {
            final k = tokens[i++];
            final v = tokens[i++];
            args[k] = v;
          }
          break;
        case '--esa':
          if (i + 1 < tokens.length) {
            final k = tokens[i++];
            final v = tokens[i++];
            final items = v
                .split(RegExp(r'(?<!\\),'))
                .map((s) => s.replaceAll(r'\,', ','))
                .toList();
            arrayArgs[k] = items;
          }
          break;
        case '--activity-clear-task':
          flags.add(Flag.FLAG_ACTIVITY_CLEAR_TASK);
          break;
        case '--activity-clear-top':
          flags.add(0x04000000); // FLAG_ACTIVITY_CLEAR_TOP
          break;
        case '--activity-no-history':
          flags.add(Flag.FLAG_ACTIVITY_NO_HISTORY);
          break;
        case '--activity-single-top':
          flags.add(0x20000000); // FLAG_ACTIVITY_SINGLE_TOP
          break;
        case '--activity-no-animation':
          flags.add(0x00010000); // FLAG_ACTIVITY_NO_ANIMATION
          break;
        case '--activity-exclude-from-recents':
          flags.add(0x00800000); // FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS
          break;
        case '--grant-read-uri-permission':
        case '--grant-write-uri-permission':
        case '--grant-persistable-uri-permission':
        case '--grant-prefix-uri-permission':
          // Titanius does not grant URI permissions as it uses MANAGE_EXTERNAL_STORAGE
          // and does not hold SAF grants to delegate. Standalone emulators hold their own grants.
          break;
        case '-f':
          if (i < tokens.length) {
            final raw = tokens[i++];
            final parsed =
                int.tryParse(raw) ??
                (raw.startsWith('0x')
                    ? int.tryParse(raw.substring(2), radix: 16)
                    : null);
            if (parsed != null) {
              flags.add(parsed);
            }
          }
          break;
        default:
          break;
      }
    }

    // Default action and category if not specified
    if (action == null || action.isEmpty) {
      if (data != null && data.isNotEmpty) {
        action = 'android.intent.action.VIEW';
      } else {
        action = 'android.intent.action.MAIN';
        category ??= 'android.intent.category.LAUNCHER';
      }
    }

    // Do not pass grant-uri flags as Titanius does not own content providers or hold SAF grants,
    // and Android's UriGrantsManagerService throws SecurityException.
    // Strip grant-uri flags unconditionally (0x1 = read, 0x2 = write, 0x40 = persistable, 0x80 = prefix).
    final cleanedFlags = flags
        .map((f) => f & ~0x000000C3)
        .where((f) => f != 0)
        .toSet()
        .toList();

    return AndroidIntent(
      action: action,
      package: package,
      componentName: componentName,
      data: data,
      type: type,
      category: category,
      arguments: args.isNotEmpty ? args : null,
      arrayArguments: arrayArgs.isNotEmpty ? arrayArgs : null,
      flags: cleanedFlags,
    );
  }

  /// Parses tags from a Daijishō Player Template (`.dpt`) file if present.
  static Future<Map<String, String>> _readDptTags(String filePath) async {
    final tags = <String, String>{};
    if (!filePath.toLowerCase().endsWith('.dpt')) return tags;
    try {
      final file = File(filePath);
      if (!await file.exists()) return tags;
      final lines = await file.readAsLines();
      if (lines.isEmpty) return tags;
      final header = lines.first.trim();
      if (header != '# Daijishou Player Template' && header != '# DST') {
        return tags;
      }
      final tagRegex = RegExp(r'^\[([^\]]+)\]\s*(.*)$');
      for (final line in lines.skip(1)) {
        final match = tagRegex.firstMatch(line.trim());
        if (match != null) {
          tags[match.group(1)!] = match.group(2)!;
        }
      }
    } catch (e) {
      debugPrint('Error reading .dpt template file: $e');
    }
    return tags;
  }
}
