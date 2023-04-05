import 'dart:convert';
import 'dart:io';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xml/xml.dart';
import 'package:xml/xml_events.dart';
import 'package:collection/collection.dart';

import '../data/settings.dart';
import 'emulators.dart';
import 'models.dart';
import 'systems.dart';

part 'games.g.dart';

class GameList {
  final System? system;
  final List<Game> games;
  final Emulator? emulator;

  const GameList(this.system, this.games, this.emulator);
}

@Riverpod(keepAlive: true)
Future<GameList> games(GamesRef ref, String systemId) async {
  final detectedSystems = await ref.watch(detectedSystemsProvider.future);
  final settings = await ref.watch(settingsProvider.future);

  final allGames = List<Game>.empty(growable: true);

  if (detectedSystems.isEmpty) {
    return const GameList(null, [], null);
  }

  final system =
      detectedSystems.firstWhere((element) => element.id == systemId);
  final emulator = defaultEmulator(
      system.emulators,
      settings.perSystemConfigurations
          .firstWhereOrNull((e) => e.system == system.id));

  final favouritesMap = {
    for (var favourite in settings.favourites)
      favourite.romPath: favourite.favourite
  };

  for (var romsFolder in settings.romsFolders) {
    for (var folder in system.folders) {
      final romsPath = "$romsFolder/$folder";
      final gamelistPath = "$romsPath/gamelist.xml";

      final file = File(gamelistPath);
      final exists = await file.exists();
      if (exists) {
        final games = await file
            .openRead()
            .transform(utf8.decoder)
            .toXmlEvents()
            .normalizeEvents()
            .selectSubtreeEvents(
                (event) => event.name == 'game' || event.name == 'folder')
            .toXmlNodes()
            .expand((nodes) => nodes)
            .map((node) => _fromNode(node, romsPath))
            .toList();
        for (var game in games) {
          if (favouritesMap.containsKey(game.romPath)) {
            game.favorite = favouritesMap[game.romPath]!;
          }
        }
        allGames.addAll(games);
      }
    }
  }

  bool favouriteOnTop = settings.favouritesOnTop;
  final games = allGames.sorted((a, b) {
    // folders on top
    if (a.isFolder) {
      return -1;
    }
    if (b.isFolder) {
      return 1;
    }
    if (favouriteOnTop) {
      if (a.favorite && b.favorite) {
        return a.name.compareTo(b.name);
      }
      if (a.favorite) {
        return -1;
      }
      if (b.favorite) {
        return 1;
      }
    }
    return a.name.compareTo(b.name);
  });
  return GameList(system, games, emulator);
}

Game _fromNode(XmlNode node, String romsPath) {
  final name = node.findElements("name").first.text;
  final path = node.findElements("path").first.text;
  final description = node.findElements("desc").firstOrNull?.text;
  final genre = node.findElements("genre").firstOrNull?.text;
  final developer = node.findElements("developer").firstOrNull?.text;
  final ratingString = node.findElements("rating").firstOrNull?.text;
  final rating = ratingString != null ? double.tryParse(ratingString) : null;
  final yearString = node.findElements("releasedate").firstOrNull?.text;
  final year = yearString != null && yearString.length > 4
      ? int.parse(yearString.substring(0, 4))
      : null;
  final image = node.findElements("image").firstOrNull?.text;
  final video = node.findElements("video").firstOrNull?.text;
  final thumbnail = node.findElements("thumbnail").firstOrNull?.text;
  final favorite = node.findElements("favorite").firstOrNull?.text == "true";
  return Game(name, romsPath, path.substring(0, path.lastIndexOf("/")), path,
      description: description,
      genre: genre,
      rating: rating != null ? 10 * rating : null,
      imageUrl: image != null ? "$romsPath/$image" : null,
      videoUrl: video != null ? "$romsPath/$video" : null,
      thumbnailUrl: thumbnail != null ? "$romsPath/$thumbnail" : null,
      developer: developer,
      year: year,
      favorite: favorite,
      isFolder: node is XmlElement && node.name.local == "folder");
}
