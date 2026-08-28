import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
    return Future.value([
      GrantedUri(Uri.parse("file:///D:/Roms"), "D:/Roms"),
    ]);
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
  return persistedUris.where((element) {
    final grantedFullPath = element.grantedFullPath;
    return filePath.startsWith(grantedFullPath);
  }).firstOrNull;
}

Future<SafDocumentFile?> getDocumentFile(String filePath) async {
  final matchingUri = await getMatchingPersistedUri(filePath);
  if (matchingUri != null) {
    final relativeFilePath = filePath.substring(matchingUri.grantedFullPath.length + 1);
    final segments = relativeFilePath.split('/').where((s) => s.isNotEmpty).toList();
    final matchingDoc = await _saf.child(matchingUri.uri.toString(), segments);
    if (matchingDoc != null) {
      debugPrint("file:$filePath uri:${Uri.decodeFull(matchingDoc.uri)} name:${matchingDoc.name}");
      return matchingDoc;
    }
  }

  Fluttertoast.showToast(
      msg: "Unable to run $filePath in a standalone emulator due to SAF restrictions.",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0);
  return null;
}

const platform = MethodChannel('file_utils');

Future<String?> getMediaUri(String filePath) async {
  try {
    final String contentUri = await platform.invokeMethod('getContentUri', {'path': filePath});
    return contentUri;
  } on PlatformException catch (e) {
    debugPrint('Error: ${e.message}');
    return null;
  }
}
