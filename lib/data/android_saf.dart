import 'package:async_task/async_task_extension.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_storage/saf.dart' as saf;

class GrantedUri {
  final Uri uri;
  final String grantedFullPath;

  GrantedUri(this.uri, this.grantedFullPath);
}

Future<GrantedUri?> getMatchingPersistedUri(String filePath) async {
  final persistedUris = await saf.persistedUriPermissions();
  debugPrint("persistedUris: ${persistedUris.toString()}");
  final matchingUris = await persistedUris
      ?.where((element) => element.isTreeDocumentFile && element.isReadPermission)
      .map((uriPermission) async {
    debugPrint("uri: ${uriPermission.uri.toString()}");
    final uri = uriPermission.uri;
    final String decodedPath = Uri.decodeComponent(uri.path);
    final String volumeAndPath = decodedPath.replaceFirst('/tree/', '');
    final List<String> segments = volumeAndPath.split(':');
    final String grantedVolume = segments[0];
    final String grantedPath = segments.length > 1 ? segments[1] : '';
    final String grantedFullPath = "/storage/$grantedVolume/$grantedPath";
    debugPrint("grantedFullPath: $grantedFullPath");
    if (filePath.startsWith(grantedFullPath)) {
      return GrantedUri(uri, grantedFullPath);
    }
    return null;
  }).resolveAllNotNull();
  return matchingUris?.firstOrNull;
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
      debugPrint("file: filePath uri:${matchingDoc.uri.toString()}");
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
