import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saf/saf.dart';

class GrantedUri {
  final Uri uri;
  final String grantedFullPath;

  GrantedUri(this.uri, this.grantedFullPath);
}

final _saf = Saf();

final grantedUrisProvider = FutureProvider<List<GrantedUri>>((ref) {
  if (Platform.isAndroid) {
    return _allGrantedReads();
  }
  if (Platform.isMacOS) {
    final home = Platform.environment['HOME'] ?? '';
    final macRomsPath = "$home/Roms";
    return Future.value([
      GrantedUri(Uri.parse("file://$macRomsPath"), macRomsPath),
    ]);
  }
  if (Platform.isWindows) {
    return Future.value([GrantedUri(Uri.parse("file:///D:/Roms"), "D:/Roms")]);
  }
  return Future.value([]);
});

String? pathFromTreeUri(Uri uri) {
  if (uri.scheme == 'file') {
    return uri.toFilePath();
  }
  final decoded = Uri.decodeFull(uri.toString());
  final treeIndex = decoded.indexOf('/tree/');
  if (treeIndex != -1) {
    String docId = decoded.substring(treeIndex + 6);
    final docIndex = docId.indexOf('/document/');
    if (docIndex != -1) {
      docId = docId.substring(docIndex + 10);
    }
    final queryIndex = docId.indexOf('?');
    if (queryIndex != -1) {
      docId = docId.substring(0, queryIndex);
    }
    if (docId.startsWith('primary:')) {
      final sub = docId.substring(8);
      return sub.isEmpty ? '/storage/emulated/0' : '/storage/emulated/0/$sub';
    } else if (docId == 'primary') {
      return '/storage/emulated/0';
    } else if (docId.contains(':')) {
      final colon = docId.indexOf(':');
      final root = docId.substring(0, colon);
      final sub = docId.substring(colon + 1);
      return sub.isEmpty ? '/storage/$root' : '/storage/$root/$sub';
    } else {
      return '/storage/$docId';
    }
  }
  return null;
}

Future<List<GrantedUri>> _allGrantedReads() async {
  try {
    final perms = await _saf.persistedPermissions();
    return perms.where((p) => p.read).map((p) {
      final uri = Uri.parse(p.uri);
      final path = pathFromTreeUri(uri) ?? uri.toString();
      return GrantedUri(uri, path);
    }).toList();
  } catch (e) {
    debugPrint('Error fetching persisted SAF permissions: $e');
    return [];
  }
}

Future<GrantedUri?> getMatchingPersistedUri(String filePath) async {
  final persistedUris = await _allGrantedReads();
  final lowerFilePath = filePath.toLowerCase();
  return persistedUris.firstWhereOrNull((element) {
    final grantedFullPath = element.grantedFullPath.toLowerCase();
    return lowerFilePath.startsWith(grantedFullPath);
  });
}

Future<SafDocumentFile?> getDocumentFile(String filePath) async {
  if (!Platform.isAndroid) return null;
  final matchingUri = await getMatchingPersistedUri(filePath);
  if (matchingUri != null) {
    final len = matchingUri.grantedFullPath.length;
    final relativeFilePath = filePath.length > len
        ? filePath.substring(len + (filePath[len] == '/' ? 1 : 0))
        : '';
    final segments = relativeFilePath
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList();
    final matchingDoc = await _saf.child(matchingUri.uri.toString(), segments);
    if (matchingDoc != null) {
      debugPrint(
        "file:$filePath uri:${Uri.decodeFull(matchingDoc.uri)} name:${matchingDoc.name}",
      );
      return matchingDoc;
    }
  }
  return null;
}

String pathToDocumentUri(String filePath) {
  String path = filePath.replaceAll(r'\', '/');
  if (path.startsWith('/storage/emulated/0/')) {
    final rel = path.substring('/storage/emulated/0/'.length);
    final docId = 'primary:$rel';
    return 'content://com.android.externalstorage.documents/document/${Uri.encodeComponent(docId)}';
  } else if (path.startsWith('/sdcard/')) {
    final rel = path.substring('/sdcard/'.length);
    final docId = 'primary:$rel';
    return 'content://com.android.externalstorage.documents/document/${Uri.encodeComponent(docId)}';
  } else if (path.startsWith('/storage/')) {
    final sub = path.substring('/storage/'.length);
    final slash = sub.indexOf('/');
    if (slash != -1) {
      final rootId = sub.substring(0, slash);
      final rel = sub.substring(slash + 1);
      final docId = '$rootId:$rel';
      return 'content://com.android.externalstorage.documents/document/${Uri.encodeComponent(docId)}';
    }
  }
  return 'content://com.android.externalstorage.documents/document/${Uri.encodeComponent("primary:$path")}';
}

/// Constructs a full SAF Tree Document URI (`content://.../tree/<treeId>/document/<docId>`)
/// matching the Uri format expected by standalone Android emulators (e.g. melonDS, Dolphin, PPSSPP).
String pathToTreeDocumentUri(String filePath, {String? systemFolder}) {
  String path = filePath.replaceAll(r'\', '/');
  String storageRoot;
  String relPath;
  if (path.startsWith('/storage/emulated/0/')) {
    storageRoot = 'primary';
    relPath = path.substring('/storage/emulated/0/'.length);
  } else if (path.startsWith('/sdcard/')) {
    storageRoot = 'primary';
    relPath = path.substring('/sdcard/'.length);
  } else if (path.startsWith('/storage/')) {
    final sub = path.substring('/storage/'.length);
    final slash = sub.indexOf('/');
    if (slash != -1) {
      storageRoot = sub.substring(0, slash);
      relPath = sub.substring(slash + 1);
    } else {
      storageRoot = 'primary';
      relPath = path;
    }
  } else {
    storageRoot = 'primary';
    relPath = path.startsWith('/') ? path.substring(1) : path;
  }

  String treeRelPath;
  if (systemFolder != null &&
      systemFolder.isNotEmpty &&
      relPath.contains(systemFolder)) {
    final idx = relPath.indexOf(systemFolder);
    treeRelPath = relPath.substring(0, idx + systemFolder.length);
  } else {
    final lastSlash = relPath.lastIndexOf('/');
    treeRelPath = lastSlash != -1 ? relPath.substring(0, lastSlash) : relPath;
  }

  final treeId = '$storageRoot:$treeRelPath';
  final docId = '$storageRoot:$relPath';

  return 'content://com.android.externalstorage.documents/tree/${Uri.encodeComponent(treeId)}/document/${Uri.encodeComponent(docId)}';
}

/// Resolves the document URI for a ROM file, using persisted SAF DocumentFile if available,
/// or falling back to canonical SAF tree document URI.
Future<String> resolveDocumentUri(
  String filePath, {
  String? systemFolder,
}) async {
  final safDoc = await getDocumentFile(filePath);
  if (safDoc != null) {
    return safDoc.uri.toString();
  }
  return pathToTreeDocumentUri(filePath, systemFolder: systemFolder);
}

const platform = MethodChannel('file_utils');

Future<String?> getMediaUri(String filePath) async {
  try {
    final String contentUri = await platform.invokeMethod('getContentUri', {
      'path': filePath,
    });
    return contentUri;
  } catch (e) {
    debugPrint('Error: $e');
    return null;
  }
}
