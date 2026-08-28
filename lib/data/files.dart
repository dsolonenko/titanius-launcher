import 'dart:io';

import 'package:titanius/data/models.dart';

Future<File> moveFile(File sourceFile, String newPath) async {
  try {
    return await sourceFile.rename(newPath);
  } on FileSystemException catch (_) {
    final newFile = await sourceFile.copy(newPath);
    await sourceFile.delete();
    return newFile;
  }
}

Future<List<Game>> listGamesFromFiles({
  required String romsFolder,
  required String folder,
  required System system,
}) async {
  return streamGamesFromFiles(romsFolder: romsFolder, folder: folder, system: system).toList();
}

Stream<Game> streamGamesFromFiles({
  required String romsFolder,
  required String folder,
  required System system,
}) async* {
  final directory = Directory("$romsFolder/$folder");
  if (!await directory.exists()) return;
  await for (final file in _scanDirectory(directory)) {
    if (!_nonRom(file)) yield Game.fromFile(file, system, romsFolder, folder);
  }
}

Stream<File> _scanDirectory(Directory directory) async* {
  await for (final entity in directory.list(followLinks: false)) {
    if (entity is File) {
      yield entity;
    } else if (entity is Directory) {
      final name = entity.uri.pathSegments.where((segment) => segment.isNotEmpty).last;
      if (!name.startsWith('.')) yield* _scanDirectory(entity);
    }
  }
}

final _nonRomExtensions = {
  // Media & artwork
  '.png', '.jpg', '.jpeg', '.gif', '.webp', '.bmp', '.svg',
  '.mp4', '.mkv', '.avi', '.webm',

  // Documents & metadata
  '.txt', '.nfo', '.pdf', '.doc', '.md', '.html', '.htm', '.url',
  '.xml', '.json', '.log', '.info', '.ini',

  // Saves & Memory Cards
  '.srm', '.sav', '.save', '.dsv', '.nv', '.nvram', '.rtc', '.eep',
  '.fla', '.flash', '.mcr', '.mem', '.mcd', '.mc', '.gme', '.mpk',

  // Save states & autosaves
  '.auto', '.state', '.fs',

  // Cheats & configs
  '.cht', '.cfg', '.opt', '.remap', '.p2k',

  // Patches
  '.ips', '.bps', '.ups', '.xdelta', '.aps', '.diff', '.patch',

  // Backups & temporary
  '.bak', '.old', '.orig', '.tmp',
};

final _savestatePattern = RegExp(r'\.(state\d*|st\d+|ss\d+)(\.(auto|bak))?$', caseSensitive: false);

bool _nonRom(FileSystemEntity element) {
  if (element is Directory) {
    return true;
  }
  final fileName = element.uri.pathSegments.last;
  final lowerName = fileName.toLowerCase();

  if (lowerName.contains("gamelist") || lowerName == "neogeo.zip") {
    return true;
  }
  if (fileName.startsWith(".") || fileName.startsWith("ZZZ")) {
    return true;
  }

  // Check direct extension match
  final lastDot = lowerName.lastIndexOf('.');
  if (lastDot != -1) {
    final ext = lowerName.substring(lastDot);
    if (_nonRomExtensions.contains(ext)) {
      return true;
    }
  }

  // Check compound / numbered savestate patterns (e.g. .state1, .st0, .state.auto, .srm.auto)
  if (_savestatePattern.hasMatch(lowerName)) {
    return true;
  }

  return false;
}
