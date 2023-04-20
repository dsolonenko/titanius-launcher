import 'dart:io';

import 'package:async_task/async_task_extension.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_storage/saf.dart' as saf;

part 'android_saf.g.dart';

class GrantedUri {
  final Uri uri;
  final String grantedFullPath;

  GrantedUri(this.uri, this.grantedFullPath);
}

String _uriToFullPath(Uri uri) {
  final String decodedPath = Uri.decodeComponent(uri.path);
  final String volumeAndPath = decodedPath.replaceFirst('/tree/', '');
  final List<String> segments = volumeAndPath.split(':');
  final String grantedVolume = segments[0];
  final String grantedPath = segments.length > 1 ? segments[1] : '';
  final String grantedFullPath = "/storage/${grantedVolume == "primary" ? "emulated/0" : grantedVolume}/$grantedPath";
  if (grantedFullPath.endsWith("/")) {
    return grantedFullPath.substring(0, grantedFullPath.length - 1);
  } else {
    return grantedFullPath;
  }
}

@Riverpod(keepAlive: true)
Future<List<GrantedUri>> grantedUris(GrantedUrisRef ref) {
  if (Platform.isAndroid) {
    return _allGrantedReads();
  }
  if (Platform.isMacOS) {
    return Future.value([
      GrantedUri(Uri.parse("file:///Users/ds/Roms"), "/Users/ds/Roms"),
    ]);
  }
  if (Platform.isWindows) {
    return Future.value([
      GrantedUri(Uri.parse("file:///D:/Roms"), "D:/Roms"),
    ]);
  }
  return Future.value([]);
}

Future<List<GrantedUri>> _allGrantedReads() async {
  final persistedUris = await saf.persistedUriPermissions();
  debugPrint("persistedUris: ${persistedUris.toString()}");
  return persistedUris?.where((element) => element.isTreeDocumentFile && element.isReadPermission).map((e) {
        final uri = e.uri;
        final grantedFullPath = _uriToFullPath(uri);
        debugPrint("grantedFullPath: $grantedFullPath");
        return GrantedUri(uri, grantedFullPath);
      }).toList() ??
      [];
}

Future<GrantedUri?> getMatchingPersistedUri(String filePath) async {
  final persistedUris = await _allGrantedReads();
  return persistedUris.where((element) {
    final grantedFullPath = element.grantedFullPath;
    return filePath.startsWith(grantedFullPath);
  }).firstOrNull;
}

Future<saf.DocumentFile?> getDocumentFile(String filePath) async {
  Future<saf.DocumentFile?> findFileInSubdirectory(Uri parentUri, String relativeFilePath) async {
    List<String> pathSegments = relativeFilePath.split('/');

    saf.DocumentFile? currentDoc;
    for (int i = 0; i < pathSegments.length; i++) {
      final currentSegment = pathSegments[i];
      final documentFile = await saf.findFile(currentDoc?.uri ?? parentUri, currentSegment);
      if (documentFile == null) {
        return null;
      }
      currentDoc = documentFile;
    }

    return currentDoc;
  }

  final matchingUri = await getMatchingPersistedUri(filePath);
  if (matchingUri != null) {
    final relativeFilePath = filePath.substring(matchingUri.grantedFullPath.length + 1);
    final matchingDoc = await findFileInSubdirectory(matchingUri.uri, relativeFilePath);
    if (matchingDoc != null) {
      final exists = await matchingDoc.exists();
      debugPrint("file:$filePath uri:${Uri.decodeFull(matchingDoc.uri.toString())} exists:$exists");
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
