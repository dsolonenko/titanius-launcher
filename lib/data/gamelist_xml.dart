import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

import 'models.dart';

Future<bool> setFavouriteInGamelistXml(Game game, bool favourite) {
  return _setNodeInGamelistXml(game.absoluteFolderPath, game.rom, "favorite", favourite ? "true" : "false");
}

Future<bool> setHiddenGameInGamelistXml(Game game, bool hidden) {
  return _setNodeInGamelistXml(game.absoluteFolderPath, game.rom, "hidden", hidden ? "true" : "false");
}

Future<bool> _setNodeInGamelistXml(String systemFolderPath, String romPath, String nodeName, String nodeValue) async {
  final stopwatch = Stopwatch()..start();
  try {
    debugPrint(
        'Updating gamelist.xml for systemFolderPath=$systemFolderPath, romPath=$romPath, nodeName=$nodeName, nodeValue=$nodeValue');
    final xmlFile = File('$systemFolderPath/gamelist.xml');
    if (await xmlFile.exists()) {
      final xmlContent = await xmlFile.readAsString();
      final (updatedXmlContent, isUpdated) = _setNode(xmlContent, romPath, nodeName, nodeValue);
      if (isUpdated) {
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

(String, bool) _setNode(String xmlContent, String romPath, String nodeName, String nodeValue) {
  final document = XmlDocument.parse(xmlContent);
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

  return (document.toXmlString(pretty: true, indent: '  '), updated);
}
