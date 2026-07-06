import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:saf_util/saf_util.dart';
import 'package:saf_util/saf_util_platform_interface.dart';

class GrantedUri {
  final Uri uri;
  final String grantedFullPath;

  GrantedUri(this.uri, this.grantedFullPath);
}

final _safUtil = SafUtil();

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

Future<List<GrantedUri>> _allGrantedReads() async {
  return [];
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
    final segments = relativeFilePath.split('/');
    final matchingDoc = await _safUtil.child(matchingUri.uri.toString(), segments);
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
