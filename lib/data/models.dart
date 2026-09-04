import 'dart:io';

import 'package:screenscraper/screenscraper.dart';
import 'package:xml/xml.dart';
import 'package:collection/collection.dart';

import 'package:titanius/data/android_intent.dart';
import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

enum ControllerLayout {
  retro("Retro"),
  nintendo("Nintendo"),
  xbox("Xbox"),
  generic("Generic");

  final String label;
  const ControllerLayout(this.label);

  static ControllerLayout fromString(String? value) {
    switch (value) {
      case "retro":
        return ControllerLayout.retro;
      case "xbox":
        return ControllerLayout.xbox;
      case "generic":
        return ControllerLayout.generic;
      case "nintendo":
        return ControllerLayout.nintendo;
      default:
        return ControllerLayout.retro;
    }
  }
}

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

const systemNoMetadata = System(
  id: 'no_metadata',
  screenScraperId: 0,
  name: 'No Metadata',
  logo: "",
  folders: [],
  builtInEmulators: [],
  isCollection: true,
);

const systemRetroAchievements = System(
  id: 'retroachievements',
  screenScraperId: 0,
  name: 'RetroAchievements',
  logo: "",
  folders: [],
  builtInEmulators: [],
  isCollection: true,
);

const collections = [
  systemRecent,
  systemFavourites,
  systemAllGames,
  systemNoMetadata,
  systemRetroAchievements,
];

class System {
  final String id;
  final int screenScraperId;
  final int? retroAchievementsId;
  final String name;
  final String logo;
  final List<String> folders;
  final List<Emulator> builtInEmulators;
  final bool isCollection;

  const System({
    required this.id,
    required this.screenScraperId,
    this.retroAchievementsId,
    required this.name,
    required this.logo,
    required this.folders,
    required this.builtInEmulators,
    this.isCollection = false,
  });

  bool get isAndroid => id == "android";
  bool get isRetroAchievements => id == "retroachievements";
  bool get hasRetroAchievements =>
      retroAchievementsId != null && retroAchievementsId! > 0;

  @override
  String toString() {
    return 'System{id: $id, name: $name, folders: $folders}';
  }

  factory System.fromJson(Map<String, dynamic> json) {
    return System(
      id: json['id'],
      screenScraperId: json['screenScraperId'] ?? 0,
      retroAchievementsId: json['retroAchievementsId'],
      name: json['name'],
      logo: json['logo'],
      folders: List<String>.from(json['folders']),
      builtInEmulators: json.containsKey("emulators")
          ? List<Emulator>.from(
              json['emulators'].map((x) => Emulator.fromJson(x)),
            )
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'screenScraperId': screenScraperId,
      if (retroAchievementsId != null)
        'retroAchievementsId': retroAchievementsId,
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
  final String? amStartArguments;

  Emulator({
    required this.id,
    required this.name,
    required this.intent,
    this.amStartArguments,
  });

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
      amStartArguments: json['amStartArguments'],
    );
  }

  bool get isStandalone => intent.isStandalone;
  bool get isCustom => id.startsWith("custom:");
  bool get isDaijisho => id.startsWith("daijisho:");
  bool get isInternal => !isCustom && !isDaijisho;
  bool get isBuiltIn => isInternal;
}

@JsonSerializable(explicitToJson: true)
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
  late final int cachedHash = fastHash(romPath);

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
  int get hash => cachedHash;

  factory Game.fromXmlNode(
    XmlNode node,
    System system,
    String volumePath,
    String systemFolder,
  ) {
    final id = node.attributes
        .firstWhereOrNull((element) => element.name.local == "id")
        ?.value;
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
    final year = yearString != null && yearString.length >= 4
        ? int.parse(yearString.substring(0, 4))
        : null;
    final image = node.findElements("image").firstOrNull?.innerText;
    final video = node.findElements("video").firstOrNull?.innerText;
    final thumbnail = node.findElements("thumbnail").firstOrNull?.innerText;
    final favorite =
        node.findElements("favorite").firstOrNull?.innerText == "true";
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
      genreId: genreId != null
          ? GameGenre.lookupFromId(int.tryParse(genreId))
          : null,
      rating: rating != null ? 10 * rating : null,
      imageUrl: image != null
          ? "$romsPath/${image.replaceFirst("./", "")}"
          : null,
      videoUrl: video != null
          ? "$romsPath/${video.replaceFirst("./", "")}"
          : null,
      thumbnailUrl: thumbnail != null
          ? "$romsPath/${thumbnail.replaceFirst("./", "")}"
          : null,
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
    return XmlElement(
      XmlName.qualified("game"),
      [
        XmlAttribute(XmlName.qualified("id"), id ?? ""),
        XmlAttribute(XmlName.qualified("source"), "ScreenScraper.fr"),
      ],
      [
        XmlElement(XmlName.qualified("path"), [], [XmlText(rom)]),
        XmlElement(XmlName.qualified("name"), [], [XmlText(name)]),
        XmlElement(XmlName.qualified("desc"), [], [XmlText(description ?? "")]),
        XmlElement(XmlName.qualified("rating"), [], [
          XmlText(((rating ?? 0) / 10).toString()),
        ]),
        XmlElement(XmlName.qualified("releasedate"), [], [
          XmlText(year?.toString() ?? ""),
        ]),
        XmlElement(XmlName.qualified("developer"), [], [
          XmlText(developer ?? ""),
        ]),
        XmlElement(XmlName.qualified("publisher"), [], [
          XmlText(publisher ?? ""),
        ]),
        XmlElement(XmlName.qualified("genre"), [], [XmlText(genre ?? "")]),
        XmlElement(XmlName.qualified("genreid"), [], [
          XmlText(genreId?.id.toString() ?? ""),
        ]),
        XmlElement(XmlName.qualified("players"), [], [XmlText(players ?? "")]),
        if (imageUrl != null)
          XmlElement(XmlName.qualified("image"), [], [XmlText(imageUrl ?? "")]),
        if (thumbnailUrl != null)
          XmlElement(XmlName.qualified("thumbnail"), [], [
            XmlText(thumbnailUrl ?? ""),
          ]),
        if (videoUrl != null)
          XmlElement(XmlName.qualified("video"), [], [XmlText(videoUrl ?? "")]),
        XmlElement(XmlName.qualified("favorite"), [], [
          XmlText(favorite ? "true" : "false"),
        ]),
        XmlElement(XmlName.qualified("hidden"), [], [
          XmlText(hidden ? "true" : "false"),
        ]),
      ],
    );
  }

  factory Game.fromFile(
    FileSystemEntity file,
    System system,
    String volumePath,
    String systemFolder,
  ) {
    final romsPath = "$volumePath/$systemFolder";
    final path = file.absolute.path.replaceFirst(romsPath, ".");
    final fileName = file.uri.pathSegments.last;
    final extensionIndex = fileName.lastIndexOf(".");
    final name = extensionIndex > 0
        ? fileName.substring(0, extensionIndex)
        : fileName;
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

  bool get hasMetadata =>
      id != null ||
      description != null ||
      imageUrl != null ||
      videoUrl != null ||
      thumbnailUrl != null ||
      developer != null ||
      publisher != null ||
      genre != null;

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

  factory Game.fromJson(Map<String, dynamic> json) {
    if (json['system'] is System) {
      final system = json['system'] as System;
      final map = Map<String, dynamic>.from(json);
      map['system'] = system.toJson();
      return _$GameFromJson(map);
    }
    return _$GameFromJson(json);
  }

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
    imageUrl = scrapedGame.imageUrl != null
        ? "$romsPath/${scrapedGame.imageUrl!.replaceFirst("./", "")}"
        : null;
    videoUrl = scrapedGame.videoUrl != null
        ? "$romsPath/${scrapedGame.videoUrl!.replaceFirst("./", "")}"
        : null;
    thumbnailUrl = scrapedGame.thumbnailUrl != null
        ? "$romsPath/${scrapedGame.thumbnailUrl!.replaceFirst("./", "")}"
        : null;
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
