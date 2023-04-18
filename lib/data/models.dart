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

const collections = [systemAllGames, systemRecent, systemFavourites];

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

  get isStandalone => !intent.target.startsWith('com.retroarch.aarch64/');
}

class Game {
  final System system;
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
