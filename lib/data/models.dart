import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

const systemAllGames = System(
  id: 'all',
  name: 'All Games',
  logo: "",
  folders: [],
  emulators: [],
  isMulti: true,
);

const systemFavourites = System(
  id: 'favourites',
  name: 'Favourites',
  logo: "",
  folders: [],
  emulators: [],
  isMulti: true,
);

const systemRecent = System(
  id: 'recent',
  name: 'Recent',
  logo: "",
  folders: [],
  emulators: [],
  isMulti: true,
);

const collections = [systemAllGames, systemRecent, systemFavourites];

class System {
  final String id;
  final String name;
  final String logo;
  final List<String> folders;
  final List<Emulator> emulators;
  final bool isMulti;

  const System(
      {required this.id,
      required this.name,
      required this.logo,
      required this.folders,
      required this.emulators,
      this.isMulti = false});

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
        json['intent']['component'],
        Map<String, dynamic>.from(json['intent']['args'] ?? {}),
        List<String>.from(json['intent']['flags'] ?? []),
      ),
    );
  }

  get isStandalone => !intent.target.startsWith('com.retroarch.aarch64/');

  AndroidIntent toIntent(Game selectedGame) {
    final flags = this.intent.flags.map((e) {
      switch (e) {
        case "--activity-clear-task":
          return Flag.FLAG_ACTIVITY_CLEAR_TASK;
        case "--activity-clear-top":
          return Flag.FLAG_ACTIVITY_CLEAR_TOP;
        case "--activity-no-history":
          return Flag.FLAG_ACTIVITY_NO_HISTORY;
      }
      return Flag.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS;
    }).toList();
    final args = {
      for (var k in this.intent.args.keys)
        k: this.intent.args[k] == "{file.path}" ? selectedGame.romPath : this.intent.args[k],
    };
    final parts = this.intent.target.split('/');
    final intent = AndroidIntent(
      action: 'action_main',
      package: parts[0],
      componentName: parts.length > 1 ? parts[1] : null,
      arguments: args,
      flags: flags,
    );
    return intent;
  }
}

class LaunchIntent {
  final String target;
  final Map<String, dynamic> args;
  final List<String> flags;

  LaunchIntent(this.target, this.args, this.flags);
}

class Game {
  final System system;
  final Emulator? emulator;
  final String name;
  final String path;
  final String folder;
  final String rom;
  final String? description;
  final String? genre;
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

  Game(
    this.system,
    this.emulator,
    this.name,
    this.path,
    this.folder,
    this.rom, {
    this.description,
    this.genre,
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
  });

  String get romPath => "$path/${rom.replaceFirst("./", "")}";
}
