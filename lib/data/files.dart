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
  final romsPath = "$romsFolder/$folder";
  final pathExists = await Directory(romsPath).exists();
  if (!pathExists) {
    return [];
  }
  final dir = Directory(romsPath);
  final allFiles = await dir.list(recursive: true, followLinks: false).toList();
  allFiles.removeWhere((element) => _nonRom(element));
  final gamesFromFiles = allFiles.map((file) => Game.fromFile(file, system, romsFolder, folder)).toList();
  return gamesFromFiles;
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
