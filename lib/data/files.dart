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
  final allFiles = dir.listSync(recursive: true, followLinks: false);
  allFiles.removeWhere((element) => _nonRom(element));
  final gamesFromFiles = allFiles.map((file) => Game.fromFile(file, system, romsFolder, folder)).toList();
  return gamesFromFiles;
}

bool _nonRom(FileSystemEntity element) {
  if (element is Directory) {
    return true;
  }
  final fileName = element.uri.pathSegments.last;
  if (fileName.contains("gamelist") || fileName == "neogeo.zip") {
    return true;
  }
  if (fileName.startsWith(".") || fileName.startsWith("ZZZ")) {
    return true;
  }
  return fileName.endsWith(".mp4") ||
      fileName.endsWith(".png") ||
      fileName.endsWith(".jpg") ||
      fileName.endsWith(".jpeg") ||
      fileName.endsWith(".gif") ||
      fileName.endsWith(".txt") ||
      fileName.endsWith(".sav") ||
      fileName.endsWith(".p2k") ||
      fileName.endsWith(".cfg") ||
      fileName.endsWith(".bak");
}
