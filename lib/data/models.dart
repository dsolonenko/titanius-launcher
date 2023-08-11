import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:screenscraper/screenscraper.dart';
import 'package:xml/xml.dart';
import 'package:collection/collection.dart';

import 'package:titanius/data/android_intent.dart';
import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

const systemAllGames = System(
  id: 'all',
  screenScraperId: 0,
  name: 'All Games',
  logo: "",
  folders: [],
  emulators: [],
  isCollection: true,
);

const systemFavourites = System(
  id: 'favourites',
  screenScraperId: 0,
  name: 'Favourites',
  logo: "",
  folders: [],
  emulators: [],
  isCollection: true,
);

const systemRecent = System(
  id: 'recent',
  screenScraperId: 0,
  name: 'Recent',
  logo: "",
  folders: [],
  emulators: [],
  isCollection: true,
);

const collections = [systemRecent, systemFavourites, systemAllGames];

class System {
  final String id;
  final int screenScraperId;
  final String name;
  final String logo;
  final List<String> folders;
  final List<Emulator> emulators;
  final bool isCollection;

  const System(
      {required this.id,
      required this.screenScraperId,
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
      screenScraperId: json['screenScraperId'],
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

@JsonSerializable()
class RomToScrape {
  final int systemScreenScraperId;
  final String folder;
  final String rom;
  final String absoluteRomPath;
  final String volumePath;
  final String systemFolder;
  final String? imageUrl;
  final String? videoUrl;
  final String? thumbnailUrl;
  final bool favorite;
  final bool hidden;

  RomToScrape({
    required this.systemScreenScraperId,
    required this.folder,
    required this.rom,
    required this.absoluteRomPath,
    required this.volumePath,
    required this.systemFolder,
    this.imageUrl,
    this.videoUrl,
    this.thumbnailUrl,
    this.favorite = false,
    this.hidden = false,
  });

  factory RomToScrape.fromJson(Map<String, dynamic> json) => _$RomToScrapeFromJson(json);
  Map<String, dynamic> toJson() => _$RomToScrapeToJson(this);
}

class Game {
  final System system;
  final String name;
  final String volumePath;
  final String systemFolder;
  final String folder;
  final String rom;
  final String? id;
  final String? description;
  final String? genre;
  final GameGenre? genreId;
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
  bool fromGamelistXml;

  Game(
    this.system,
    this.name,
    this.volumePath,
    this.systemFolder,
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
    this.fromGamelistXml = false,
  });

  String get absoluteFolderPath => "$volumePath/$systemFolder";
  String get absoluteRomPath => "$volumePath/$romPath";
  String get romPath => "$systemFolder/${rom.replaceFirst("./", "")}";
  String get uniqueKey => id != null ? "id/$id" : "${system.id}/$name";
  String get genreToShow => genreId?.longName ?? "-";
  int get hash => fastHash(rom);

  factory Game.fromXmlNode(XmlNode node, System system, String volumePath, String systemFolder) {
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
    final year = yearString != null && yearString.length >= 4 ? int.parse(yearString.substring(0, 4)) : null;
    final image = node.findElements("image").firstOrNull?.innerText;
    final video = node.findElements("video").firstOrNull?.innerText;
    final thumbnail = node.findElements("thumbnail").firstOrNull?.innerText;
    final favorite = node.findElements("favorite").firstOrNull?.innerText == "true";
    final hidden = node.findElements("hidden").firstOrNull?.innerText == "true";
    final romsPath = "$volumePath/$systemFolder";
    return Game(
      system,
      name,
      volumePath,
      systemFolder,
      path.substring(0, path.lastIndexOf("/")),
      path,
      id: id,
      description: description,
      genre: genre,
      genreId: genreId != null ? GameGenre.lookupFromId(int.tryParse(genreId)) : null,
      rating: rating != null ? 10 * rating : null,
      imageUrl: image != null ? "$romsPath/${image.replaceFirst("./", "")}" : null,
      videoUrl: video != null ? "$romsPath/${video.replaceFirst("./", "")}" : null,
      thumbnailUrl: thumbnail != null ? "$romsPath/${thumbnail.replaceFirst("./", "")}" : null,
      developer: developer,
      publisher: publisher,
      players: players,
      year: year,
      favorite: favorite,
      isFolder: node is XmlElement && node.name.local == "folder",
      hidden: hidden,
      fromGamelistXml: true,
    );
  }

  XmlNode toXmlNode() {
    return XmlElement(XmlName("game"), [
      XmlAttribute(XmlName("id"), id ?? ""),
      XmlAttribute(XmlName("source"), "ScreenScraper.fr"),
    ], [
      XmlElement(XmlName("path"), [], [XmlText(rom)]),
      XmlElement(XmlName("name"), [], [XmlText(name)]),
      XmlElement(XmlName("desc"), [], [XmlText(description ?? "")]),
      XmlElement(XmlName("rating"), [], [XmlText(((rating ?? 0) / 10).toString())]),
      XmlElement(XmlName("releasedate"), [], [XmlText(year?.toString() ?? "")]),
      XmlElement(XmlName("developer"), [], [XmlText(developer ?? "")]),
      XmlElement(XmlName("publisher"), [], [XmlText(publisher ?? "")]),
      XmlElement(XmlName("genre"), [], [XmlText(genre ?? "")]),
      XmlElement(XmlName("genreid"), [], [XmlText(genreId?.id.toString() ?? "")]),
      XmlElement(XmlName("players"), [], [XmlText(players ?? "")]),
      XmlElement(XmlName("image"), [], [XmlText(imageUrl ?? "")]),
      XmlElement(XmlName("thumbnail"), [], [XmlText(thumbnailUrl ?? "")]),
      XmlElement(XmlName("video"), [], [XmlText(videoUrl ?? "")]),
      XmlElement(XmlName("favorite"), [], [XmlText(favorite ? "true" : "false")]),
      XmlElement(XmlName("hidden"), [], [XmlText(hidden ? "true" : "false")]),
    ]);
  }

  factory Game.fromFile(FileSystemEntity file, System system, String volumePath, String systemFolder) {
    final romsPath = "$volumePath/$systemFolder";
    final path = file.absolute.path.replaceFirst(romsPath, ".");
    final fileName = file.uri.pathSegments.last;
    final name = fileName.substring(0, fileName.lastIndexOf("."));
    debugPrint("Game from file romsPath=$romsPath path=$path fileName=$fileName");
    return Game(
      system,
      name,
      volumePath,
      systemFolder,
      path.substring(0, path.lastIndexOf("/")),
      path,
      fromGamelistXml: false,
    );
  }

  bool get needsScraping =>
      id == null ||
      description == null ||
      genre == null ||
      genreId == null ||
      rating == null ||
      developer == null ||
      publisher == null ||
      players == null ||
      year == null ||
      imageUrl == null ||
      videoUrl == null ||
      thumbnailUrl == null;

  RomToScrape asRomToScrape() {
    return RomToScrape(
      systemScreenScraperId: system.screenScraperId,
      folder: folder,
      rom: rom,
      absoluteRomPath: absoluteRomPath,
      volumePath: volumePath,
      systemFolder: systemFolder,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      favorite: favorite,
      hidden: hidden,
    );
  }
}

/// FNV-1a 64bit hash algorithm optimized for Dart Strings
int fastHash(String string) {
  var hash = 0xcbf29ce484222325;

  var i = 0;
  while (i < string.length) {
    final codeUnit = string.codeUnitAt(i++);
    hash ^= codeUnit >> 8;
    hash *= 0x100000001b3;
    hash ^= codeUnit & 0xFF;
    hash *= 0x100000001b3;
  }

  return hash;
}
