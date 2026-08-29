import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

import 'package:titanius/data/models.dart';

Future<bool> deleteGame(Game game) async {
  try {
    await File(game.absoluteRomPath).delete();
    tryDelete(game.imageUrl);
    tryDelete(game.videoUrl);
    tryDelete(game.thumbnailUrl);
    // Removing stale metadata is best-effort. A missing gamelist.xml or a ROM
    // that was never listed there must not turn a successful file deletion
    // into a reported failure.
    try {
      await removeGameFromGamelistXml(game);
    } catch (error) {
      debugPrint('Error removing deleted game from gamelist.xml: $error');
    }
    return true;
  } catch (error) {
    debugPrint('Error deleting game ${game.absoluteRomPath}: $error');
    return false;
  }
}

void tryDelete(String? url) {
  if (url != null) {
    File(url).delete().then(
      (value) {
        debugPrint('Deleted $url');
      },
      onError: (error) {
        debugPrint('Error deleting $url: $error');
      },
    );
  }
}

Future<bool> setFavouriteInGamelistXml(Game game, bool favourite) {
  return _updateGamelistXml(
    game,
    true,
    (document, romPath) => _setNode(
      document,
      romPath,
      "favorite",
      favourite ? "true" : "false",
      game,
    ),
  );
}

Future<bool> setHiddenGameInGamelistXml(Game game, bool hidden) {
  return _updateGamelistXml(
    game,
    true,
    (document, romPath) =>
        _setNode(document, romPath, "hidden", hidden ? "true" : "false", game),
  );
}

Future<bool> removeGameFromGamelistXml(Game game) {
  return _updateGamelistXml(
    game,
    false,
    (document, romPath) => _removeNode(document, romPath),
  );
}

Future<bool> updateGameInGamelistXml(Game game) {
  return _updateGamelistXml(
    game,
    true,
    (document, romPath) => _rewriteNode(document, romPath, game),
  );
}

Future<bool> _updateGamelistXml(
  Game game,
  bool createNew,
  bool Function(XmlDocument document, String romPath) update,
) async {
  final stopwatch = Stopwatch()..start();
  try {
    final systemFolderPath = game.absoluteFolderPath;
    final romPath = game.rom;
    debugPrint(
      'Updating gamelist.xml for systemFolderPath=$systemFolderPath, romPath=$romPath',
    );
    final xmlFile = File('$systemFolderPath/gamelist.xml');
    if (await xmlFile.exists()) {
      final xmlContent = await xmlFile.readAsString();
      final document = XmlDocument.parse(xmlContent);
      return await _updateDocument(xmlFile, document, romPath, update);
    } else {
      if (createNew) {
        debugPrint('Creating new gamelist.xml');
        final document = XmlDocument([
          XmlElement(XmlName.qualified("gameList"), [], []),
        ]);
        return await _updateDocument(xmlFile, document, romPath, update);
      } else {
        debugPrint('Gamelist.xml not found');
        return false;
      }
    }
  } finally {
    stopwatch.stop();
    debugPrint("Gamelist update took ${stopwatch.elapsedMilliseconds}ms");
  }
}

Future<bool> _updateDocument(
  File xmlFile,
  XmlDocument document,
  String romPath,
  bool Function(XmlDocument document, String romPath) update,
) async {
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
}

bool _setNode(
  XmlDocument document,
  String romPath,
  String nodeName,
  String nodeValue, [
  Game? game,
]) {
  final games = document.findAllElements('game');
  for (final g in games) {
    final pathElement = g.findElements('path').firstOrNull;
    if (pathElement?.innerText == romPath ||
        pathElement?.innerText == romPath.replaceFirst("./", "") ||
        "./${pathElement?.innerText}" == romPath) {
      final targetNode = g.findElements(nodeName).firstOrNull;
      if (targetNode != null) {
        targetNode.innerText = nodeValue;
      } else {
        g.children.add(
          XmlElement(XmlName.qualified(nodeName), [], [XmlText(nodeValue)]),
        );
      }
      return true;
    }
  }
  if (game != null) {
    var gamelistElement = document.findElements("gameList").firstOrNull;
    if (gamelistElement == null) {
      gamelistElement = XmlElement(XmlName.qualified("gameList"), [], []);
      document.children.add(gamelistElement);
    }
    final gameNode = game.toXmlNode();
    final targetNode = gameNode.findElements(nodeName).firstOrNull;
    if (targetNode != null) {
      targetNode.innerText = nodeValue;
    } else {
      gameNode.children.add(
        XmlElement(XmlName.qualified(nodeName), [], [XmlText(nodeValue)]),
      );
    }
    gamelistElement.children.add(gameNode);
    return true;
  }
  return false;
}

bool _removeNode(XmlDocument document, String romPath) {
  final games = document.findAllElements('game');
  for (final game in games) {
    final pathElement = game.findElements('path').firstOrNull;
    if (pathElement?.innerText == romPath ||
        pathElement?.innerText == romPath.replaceFirst("./", "") ||
        "./${pathElement?.innerText}" == romPath) {
      return game.parent?.children.remove(game) ?? false;
    }
  }
  return false;
}

bool _rewriteNode(XmlDocument document, String romPath, Game game) {
  _removeNode(document, romPath);
  var gamelistElement = document.findElements("gameList").firstOrNull;
  if (gamelistElement == null) {
    gamelistElement = XmlElement(XmlName.qualified("gameList"), [], []);
    document.children.add(gamelistElement);
  }
  gamelistElement.children.add(game.toXmlNode());
  return true;
}
