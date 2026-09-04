import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:titanius/data/android_intent.dart';
import 'package:titanius/data/models.dart';

const Map<String, String> daijishoSystemAliases = {
  'megadrive': 'genesis',
  'psvita': 'vita',
  'amigacd32': 'amiga',
  'gx4000': 'cpc',
};

String toDaijishoShortname(String systemId) {
  return daijishoSystemAliases[systemId] ?? systemId;
}

class DaijishoPlatformIndexItem {
  final String filename;
  final String platformName;
  final String platformShortname;
  final String platformUniqueId;
  final int revisionNumber;

  DaijishoPlatformIndexItem({
    required this.filename,
    required this.platformName,
    required this.platformShortname,
    required this.platformUniqueId,
    required this.revisionNumber,
  });

  factory DaijishoPlatformIndexItem.fromJson(Map<String, dynamic> json) {
    return DaijishoPlatformIndexItem(
      filename: json['filename'] ?? '',
      platformName: json['platformName'] ?? '',
      platformShortname: json['platformShortname'] ?? '',
      platformUniqueId: json['platformUniqueId'] ?? '',
      revisionNumber: json['revisionNumber'] ?? 0,
    );
  }
}

class DaijishoPlatformIndex {
  final String baseUri;
  final List<DaijishoPlatformIndexItem> platformList;

  DaijishoPlatformIndex({required this.baseUri, required this.platformList});

  factory DaijishoPlatformIndex.fromJson(Map<String, dynamic> json) {
    final list = (json['platformList'] as List<dynamic>? ?? [])
        .map(
          (e) => DaijishoPlatformIndexItem.fromJson(e as Map<String, dynamic>),
        )
        .toList();
    return DaijishoPlatformIndex(
      baseUri:
          json['baseUri'] ??
          'https://raw.githubusercontent.com/TapiocaFox/Daijishou/main/platforms/',
      platformList: list,
    );
  }

  DaijishoPlatformIndexItem? findByShortname(String shortname) {
    final sn = shortname.toLowerCase();
    return platformList.firstWhereOrNull(
      (e) => e.platformShortname.toLowerCase() == sn,
    );
  }
}

class DaijishoPlayer {
  final String name;
  final String uniqueId;
  final String? description;
  final String? acceptedFilenameRegex;
  final String amStartArguments;

  DaijishoPlayer({
    required this.name,
    required this.uniqueId,
    this.description,
    this.acceptedFilenameRegex,
    required this.amStartArguments,
  });

  factory DaijishoPlayer.fromJson(Map<String, dynamic> json) {
    return DaijishoPlayer(
      name: json['name'] ?? '',
      uniqueId: json['uniqueId'] ?? '',
      description: json['description'],
      acceptedFilenameRegex: json['acceptedFilenameRegex'],
      amStartArguments: json['amStartArguments'] ?? '',
    );
  }

  Emulator toEmulator() {
    final cleanName = name.contains(" - ")
        ? name.split(" - ").skip(1).join(" - ")
        : name;
    final intent = LaunchIntent.parseAmStartCommand(amStartArguments);
    return Emulator(
      id: "daijisho:$uniqueId",
      name: cleanName,
      intent: intent,
      amStartArguments: amStartArguments,
    );
  }
}

class DaijishoPlatformFile {
  final String shortname;
  final String name;
  final List<DaijishoPlayer> playerList;

  DaijishoPlatformFile({
    required this.shortname,
    required this.name,
    required this.playerList,
  });

  factory DaijishoPlatformFile.fromJson(Map<String, dynamic> json) {
    final platform = json['platform'] as Map<String, dynamic>? ?? {};
    final players = (json['playerList'] as List<dynamic>? ?? [])
        .map((p) => DaijishoPlayer.fromJson(p as Map<String, dynamic>))
        .toList();
    return DaijishoPlatformFile(
      shortname: platform['shortname'] ?? '',
      name: platform['name'] ?? '',
      playerList: players,
    );
  }
}

class DaijishoPlatformsService {
  static const String defaultBaseUrl =
      'https://raw.githubusercontent.com/TapiocaFox/Daijishou/main/platforms';

  DaijishoPlatformIndex? _cachedIndex;
  final Map<String, DaijishoPlatformFile> _cachedPlatforms = {};

  Future<Directory> getCacheDir() async {
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory('${supportDir.path}/daijisho/platforms');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<DaijishoPlatformIndex?> getIndex({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedIndex != null) {
      return _cachedIndex;
    }

    final dir = await getCacheDir();
    final indexFile = File('${dir.path}/index.json');

    if (!forceRefresh && await indexFile.exists()) {
      try {
        final content = await indexFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        _cachedIndex = DaijishoPlatformIndex.fromJson(json);
        return _cachedIndex;
      } catch (e) {
        debugPrint("Error reading cached index.json: $e");
      }
    }

    try {
      final response = await http
          .get(Uri.parse('$defaultBaseUrl/index.json'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        await indexFile.writeAsString(response.body);
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        _cachedIndex = DaijishoPlatformIndex.fromJson(json);
        return _cachedIndex;
      } else {
        debugPrint("Failed to fetch index.json: HTTP ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching index.json from GitHub: $e");
    }

    // Fallback to disk if fetch failed
    if (await indexFile.exists()) {
      try {
        final content = await indexFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        _cachedIndex = DaijishoPlatformIndex.fromJson(json);
        return _cachedIndex;
      } catch (e) {
        debugPrint("Error reading fallback index.json: $e");
      }
    }

    return null;
  }

  /// Read cached emulators strictly from local disk without any network requests.
  Future<List<Emulator>> getCachedEmulatorsForSystem(String systemId) async {
    if (systemId == 'android') {
      return [];
    }

    final shortname = toDaijishoShortname(systemId);
    if (_cachedPlatforms.containsKey(shortname)) {
      return _cachedPlatforms[shortname]!.playerList
          .map((p) => p.toEmulator())
          .toList();
    }

    final dir = await getCacheDir();
    final indexFile = File('${dir.path}/index.json');
    if (!await indexFile.exists()) {
      return [];
    }

    try {
      if (_cachedIndex == null) {
        final content = await indexFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        _cachedIndex = DaijishoPlatformIndex.fromJson(json);
      }
      final item = _cachedIndex?.findByShortname(shortname);
      if (item == null) {
        return [];
      }
      final platformFile = File('${dir.path}/${item.filename}');
      if (await platformFile.exists()) {
        final content = await platformFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final platform = DaijishoPlatformFile.fromJson(json);
        _cachedPlatforms[shortname] = platform;
        return platform.playerList.map((p) => p.toEmulator()).toList();
      }
    } catch (e) {
      debugPrint("Error reading cached platform for $systemId: $e");
    }

    return [];
  }

  Future<List<Emulator>> getEmulatorsForSystem(
    String systemId, {
    bool forceRefresh = false,
    bool fetchIfMissing = false,
  }) async {
    if (systemId == 'android') {
      return [];
    }

    if (!forceRefresh) {
      final cached = await getCachedEmulatorsForSystem(systemId);
      if (cached.isNotEmpty || !fetchIfMissing) {
        return cached;
      }
    }

    final shortname = toDaijishoShortname(systemId);
    final index = await getIndex(forceRefresh: forceRefresh);
    final item = index?.findByShortname(shortname);
    if (item == null) {
      return [];
    }

    final dir = await getCacheDir();
    final platformFile = File('${dir.path}/${item.filename}');

    if (!forceRefresh && await platformFile.exists()) {
      try {
        final content = await platformFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final platform = DaijishoPlatformFile.fromJson(json);
        _cachedPlatforms[shortname] = platform;
        return platform.playerList.map((p) => p.toEmulator()).toList();
      } catch (e) {
        debugPrint("Error reading cached platform ${item.filename}: $e");
      }
    }

    // Fetch from GitHub only when explicitly requested
    try {
      final response = await http
          .get(Uri.parse('$defaultBaseUrl/${item.filename}'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        await platformFile.writeAsString(response.body);
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final platform = DaijishoPlatformFile.fromJson(json);
        _cachedPlatforms[shortname] = platform;
        return platform.playerList.map((p) => p.toEmulator()).toList();
      } else {
        debugPrint(
          "Failed to fetch ${item.filename}: HTTP ${response.statusCode}",
        );
      }
    } catch (e) {
      debugPrint("Error fetching ${item.filename} from GitHub: $e");
    }

    // Fallback to disk if fetch failed
    if (await platformFile.exists()) {
      try {
        final content = await platformFile.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        final platform = DaijishoPlatformFile.fromJson(json);
        _cachedPlatforms[shortname] = platform;
        return platform.playerList.map((p) => p.toEmulator()).toList();
      } catch (e) {
        debugPrint("Error reading fallback ${item.filename}: $e");
      }
    }

    return [];
  }

  Future<bool> refreshPlatformForSystem(String systemId) async {
    final shortname = toDaijishoShortname(systemId);
    _cachedPlatforms.remove(shortname);
    final emulators = await getEmulatorsForSystem(systemId, forceRefresh: true);
    return emulators.isNotEmpty;
  }

  Future<int> refreshAll(
    List<String> systemIds, {
    void Function(int current, int total, String status)? onProgress,
  }) async {
    _cachedIndex = null;
    _cachedPlatforms.clear();

    onProgress?.call(0, 1, "Fetching platforms index...");
    final index = await getIndex(forceRefresh: true);
    if (index == null) {
      return 0;
    }

    final Set<String> filenamesToUpdate = {};
    for (final sysId in systemIds) {
      final sn = toDaijishoShortname(sysId);
      final item = index.findByShortname(sn);
      if (item != null) {
        filenamesToUpdate.add(item.filename);
      }
    }

    final dir = await getCacheDir();
    if (await dir.exists()) {
      for (final f in dir.listSync()) {
        if (f is File &&
            f.path.endsWith('.json') &&
            !f.path.endsWith('index.json')) {
          filenamesToUpdate.add(f.uri.pathSegments.last);
        }
      }
    }

    int successCount = 0;
    int processedCount = 0;
    final fileList = filenamesToUpdate.toList();
    final total = fileList.length;
    onProgress?.call(0, total, "Starting download...");

    for (int i = 0; i < fileList.length; i += 6) {
      final batch = fileList.sublist(
        i,
        (i + 6 > fileList.length) ? fileList.length : i + 6,
      );
      await Future.wait(
        batch.map((filename) async {
          try {
            final response = await http
                .get(Uri.parse('$defaultBaseUrl/$filename'))
                .timeout(const Duration(seconds: 10));
            if (response.statusCode == 200) {
              final file = File('${dir.path}/$filename');
              await file.writeAsString(response.body);
              successCount++;
            }
          } catch (e) {
            debugPrint("Error updating platform $filename: $e");
          } finally {
            processedCount++;
            onProgress?.call(
              processedCount,
              total,
              "Downloading platforms ($processedCount/$total)...",
            );
          }
        }),
      );
    }

    return successCount;
  }
}

final daijishoPlatformsServiceProvider = Provider<DaijishoPlatformsService>((
  ref,
) {
  return DaijishoPlatformsService();
});

final daijishoEmulatorsForSystemProvider =
    FutureProvider.family<List<Emulator>, String>((ref, systemId) async {
      final service = ref.watch(daijishoPlatformsServiceProvider);
      return service.getEmulatorsForSystem(systemId);
    });
