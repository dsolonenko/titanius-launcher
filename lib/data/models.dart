import 'dart:io';

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
  builtInEmulators: [],
  isCollection: true,
);

const systemFavourites = System(
  id: 'favourites',
  screenScraperId: 0,
  name: 'Favourites',
  logo: "",
  folders: [],
  builtInEmulators: [],
  isCollection: true,
);

const systemRecent = System(
  id: 'recent',
  screenScraperId: 0,
  name: 'Recent',
  logo: "",
  folders: [],
  builtInEmulators: [],
  isCollection: true,
);

const collections = [systemRecent, systemFavourites, systemAllGames];

class System {
  final String id;
  final int screenScraperId;
  final String name;
  final String logo;
  final List<String> folders;
  final List<Emulator> builtInEmulators;
  final bool isCollection;

  const System(
      {required this.id,
      required this.screenScraperId,
      required this.name,
      required this.logo,
      required this.folders,
      required this.builtInEmulators,
      this.isCollection = false});

  bool get isAndroid => id == "android";

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
      builtInEmulators:
          json.containsKey("emulators") ? List<Emulator>.from(json['emulators'].map((x) => Emulator.fromJson(x))) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'screenScraperId': screenScraperId,
      'name': name,
      'logo': logo,
      'folders': folders,
      //'emulators': emulators.map((e) => e.id).toList(),
    };
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
  get isCustom => id.startsWith("custom:");
}

@JsonSerializable()
class Game {
  final System system;
  final String volumePath;
  final String systemFolder;
  final String folder;
  final String rom;
  String? id;
  String name;
  String? description;
  String? genre;
  GameGenre? genreId;
  String? developer;
  String? publisher;
  String? players;
  int? year;
  String? imageUrl;
  String? videoUrl;
  String? thumbnailUrl;
  double? rating;
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
      if (imageUrl != null) XmlElement(XmlName("image"), [], [XmlText(imageUrl ?? "")]),
      if (thumbnailUrl != null) XmlElement(XmlName("thumbnail"), [], [XmlText(thumbnailUrl ?? "")]),
      if (videoUrl != null) XmlElement(XmlName("video"), [], [XmlText(videoUrl ?? "")]),
      XmlElement(XmlName("favorite"), [], [XmlText(favorite ? "true" : "false")]),
      XmlElement(XmlName("hidden"), [], [XmlText(hidden ? "true" : "false")]),
    ]);
  }

  factory Game.fromFile(FileSystemEntity file, System system, String volumePath, String systemFolder) {
    final romsPath = "$volumePath/$systemFolder";
    final path = file.absolute.path.replaceFirst(romsPath, ".");
    final fileName = file.uri.pathSegments.last;
    final name = fileName.substring(0, fileName.lastIndexOf("."));
    //debugPrint("Game from file romsPath=$romsPath path=$path fileName=$fileName");
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

  @override
  String toString() {
    return 'Game{${system.id}/$rom}';
  }

  factory Game.fromJson(Map<String, dynamic> json) => _$GameFromJson(json);

  Map<String, dynamic> toJson() => _$GameToJson(this);

  void update(Game scrapedGame) {
    id = scrapedGame.id;
    name = scrapedGame.name;
    description = scrapedGame.description;
    genre = scrapedGame.genre;
    genreId = scrapedGame.genreId;
    rating = scrapedGame.rating;
    developer = scrapedGame.developer;
    publisher = scrapedGame.publisher;
    players = scrapedGame.players;
    year = scrapedGame.year;
    favorite = scrapedGame.favorite;
    hidden = scrapedGame.hidden;
    final romsPath = "$volumePath/$systemFolder";
    imageUrl = scrapedGame.imageUrl != null ? "$romsPath/${scrapedGame.imageUrl!.replaceFirst("./", "")}" : null;
    videoUrl = scrapedGame.videoUrl != null ? "$romsPath/${scrapedGame.videoUrl!.replaceFirst("./", "")}" : null;
    thumbnailUrl =
        scrapedGame.thumbnailUrl != null ? "$romsPath/${scrapedGame.thumbnailUrl!.replaceFirst("./", "")}" : null;
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
