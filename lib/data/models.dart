import 'package:flutter/foundation.dart';
import 'package:titanius/data/genres.dart';
import 'package:xml/xml.dart';
import 'package:collection/collection.dart';

import 'android_intent.dart';

const systemAllGames = System(
  id: 'all',
  name: 'All Games',
  logo: "",
  folders: [],
  emulators: [],
  isCollection: true,
);

const systemFavourites = System(
  id: 'favourites',
  name: 'Favourites',
  logo: "",
  folders: [],
  emulators: [],
  isCollection: true,
);

const systemRecent = System(
  id: 'recent',
  name: 'Recent',
  logo: "",
  folders: [],
  emulators: [],
  isCollection: true,
);

const collections = [systemRecent, systemFavourites, systemAllGames];

class System {
  final String id;
  final String name;
  final String logo;
  final List<String> folders;
  final List<Emulator> emulators;
  final bool isCollection;

  const System(
      {required this.id,
      required this.name,
      required this.logo,
      required this.folders,
      required this.emulators,
      this.isCollection = false});

  @override
  String toString() {
    return 'Person{name: $name, folders: $folders}';
  }

  factory System.fromJson(Map<String, dynamic> json) {
    return System(
      id: json['id'],
      name: json['name'],
      logo: json['logo'],
      folders: List<String>.from(json['folders']),
      emulators: List<Emulator>.from(json['emulators'].map((x) => Emulator.fromJson(x))),
    );
  }
}

class Emulator {
  final String id;
  final String name;
  final LaunchIntent intent;

  Emulator({required this.id, required this.name, required this.intent});

  factory Emulator.fromJson(Map<String, dynamic> json) {
    return Emulator(
      id: json['id'],
      name: json['name'],
      intent: LaunchIntent(
        target: json['intent']['component'],
        action: json['intent']['action'],
        data: json['intent']['data'],
        args: Map<String, dynamic>.from(json['intent']['args'] ?? {}),
        flags: List<String>.from(json['intent']['flags'] ?? []),
      ),
    );
  }

  get isStandalone => intent.isStandalone;
}

class Game {
  final System system;
  final String name;
  final String path;
  final String folder;
  final String rom;
  final String? id;
  final String? description;
  final String? genre;
  final GameGenres? genreId;
  final String? developer;
  final String? publisher;
  final String? players;
  final int? year;
  final String? imageUrl;
  final String? videoUrl;
  final String? thumbnailUrl;
  final double? rating;
  bool favorite;
  bool isFolder;
  bool hidden;

  Game(
    this.system,
    this.name,
    this.path,
    this.folder,
    this.rom, {
    this.id,
    this.description,
    this.genre,
    this.genreId,
    this.imageUrl,
    this.videoUrl,
    this.thumbnailUrl,
    this.rating,
    this.developer,
    this.publisher,
    this.players,
    this.year,
    this.favorite = false,
    this.isFolder = false,
    this.hidden = false,
  });

  String get romPath => "$path/${rom.replaceFirst("./", "")}";
  String get uniqueKey => id != null ? "id/$id" : "${system.id}/$name";
  String get genreToShow => Genres.getName(genreId, ifNull: genre ?? "-");

  factory Game.fromXmlNode(XmlNode node, System system, String romsPath) {
    final id = node.attributes.firstWhereOrNull((element) => element.name.local == "id")?.value;
    final name = node.findElements("name").first.innerText;
    final path = node.findElements("path").first.innerText;
    final description = node.findElements("desc").firstOrNull?.innerText;
    final genre = node.findElements("genre").firstOrNull?.innerText;
    final genreId = node.findElements("genreid").firstOrNull?.innerText;
    final developer = node.findElements("developer").firstOrNull?.innerText;
    final publisher = node.findElements("publisher").firstOrNull?.innerText;
    final players = node.findElements("players").firstOrNull?.innerText;
    final ratingString = node.findElements("rating").firstOrNull?.innerText;
    final rating = ratingString != null ? double.tryParse(ratingString) : null;
    final yearString = node.findElements("releasedate").firstOrNull?.innerText;
    final year = yearString != null && yearString.length > 4 ? int.parse(yearString.substring(0, 4)) : null;
    final image = node.findElements("image").firstOrNull?.innerText;
    final video = node.findElements("video").firstOrNull?.innerText;
    final thumbnail = node.findElements("thumbnail").firstOrNull?.innerText;
    final favorite = node.findElements("favorite").firstOrNull?.innerText == "true";
    final hidden = node.findElements("hidden").firstOrNull?.innerText == "true";
    return Game(system, name, romsPath, path.substring(0, path.lastIndexOf("/")), path,
        id: id,
        description: description,
        genre: genre,
        genreId: genreId != null ? Genres.lookupFromId(int.tryParse(genreId)) : null,
        rating: rating != null ? 10 * rating : null,
        imageUrl: image != null ? "$romsPath/$image" : null,
        videoUrl: video != null ? "$romsPath/$video" : null,
        thumbnailUrl: thumbnail != null ? "$romsPath/$thumbnail" : null,
        developer: developer,
        publisher: publisher,
        players: players,
        year: year,
        favorite: favorite,
        isFolder: node is XmlElement && node.name.local == "folder",
        hidden: hidden);
  }
}
