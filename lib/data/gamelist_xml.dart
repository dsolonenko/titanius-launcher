import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

import 'models.dart';

Future<bool> deleteGame(Game game) async {
  return File(game.absoluteRomPath).delete().then((value) {
    tryDelete(game.imageUrl);
    tryDelete(game.videoUrl);
    tryDelete(game.thumbnailUrl);
    return removeGameFromGamelistXml(game);
  }, onError: (error) {
    debugPrint('Error deleting game ${game.absoluteRomPath}: $error');
    return false;
  });
}

void tryDelete(String? url) {
  if (url != null) {
    File(url).delete().then((value) {
      debugPrint('Deleted $url');
    }, onError: (error) {
      debugPrint('Error deleting $url: $error');
    });
  }
}

Future<bool> setFavouriteInGamelistXml(Game game, bool favourite) {
  return _updateGamelistXml(
      game, (document, romPath) => _setNode(document, romPath, "favorite", favourite ? "true" : "false"));
}

Future<bool> setHiddenGameInGamelistXml(Game game, bool hidden) {
  return _updateGamelistXml(
      game, (document, romPath) => _setNode(document, romPath, "hidden", hidden ? "true" : "false"));
}

Future<bool> removeGameFromGamelistXml(Game game) {
  return _updateGamelistXml(game, (document, romPath) => _removeNode(document, romPath));
}

Future<bool> _updateGamelistXml(Game game, bool Function(XmlDocument document, String romPath) update) async {
  final stopwatch = Stopwatch()..start();
  try {
    final systemFolderPath = game.absoluteFolderPath;
    final romPath = game.rom;
    debugPrint('Updating gamelist.xml for systemFolderPath=$systemFolderPath, romPath=$romPath');
    final xmlFile = File('$systemFolderPath/gamelist.xml');
    if (await xmlFile.exists()) {
      final xmlContent = await xmlFile.readAsString();
      final document = XmlDocument.parse(xmlContent);
      final isUpdated = update(document, romPath);
      if (isUpdated) {
        final updatedXmlContent = document.toXmlString(pretty: true, indent: '  ');
        await xmlFile.writeAsString(updatedXmlContent);
        debugPrint('Gamelist updated successfully');
        return true;
      } else {
        debugPrint('Gamelist not updated');
        return false;
      }
    } else {
      debugPrint('Gamelist.xml not found');
      return false;
    }
  } finally {
    stopwatch.stop();
    debugPrint("Gamelist update took ${stopwatch.elapsedMilliseconds}ms");
  }
}

bool _setNode(XmlDocument document, String romPath, String nodeName, String nodeValue) {
  final games = document.findAllElements('game');
  bool updated = false;
  for (final game in games) {
    final pathElement = game.findElements('path').firstOrNull;
    if (pathElement?.innerText == romPath) {
      final favouriteNode = game.findElements(nodeName).firstOrNull;
      if (favouriteNode != null) {
        favouriteNode.innerText = nodeValue;
      } else {
        game.children.add(XmlElement(XmlName(nodeName), [], [XmlText(nodeValue)]));
      }
      updated = true;
      break;
    }
  }
  return updated;
}

bool _removeNode(XmlDocument document, String romPath) {
  final games = document.findAllElements('game');

  for (final game in games) {
    final pathElement = game.findElements('path').first;
    if (pathElement.innerText == romPath) {
      return game.parent?.children.remove(game) ?? false;
    }
  }

  return false;
}
