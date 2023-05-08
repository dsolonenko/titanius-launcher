import 'auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

const String apiBaseUrl = 'https://retroachievements.org/API';

String buildRequestUrl(
  String baseUrl,
  String endpointUrl,
  AuthObject authObject, {
  Map<String, dynamic> args = const {},
}) {
  final concatenated = '$baseUrl/$endpointUrl';
  final withoutDoubleSlashes = concatenated.replaceAll(RegExp(r'([^:]\/)\/+'), r'$1');

  String withArgs = withoutDoubleSlashes;

  // `z` and `y` are expected query params from the RA API.
  // Authentication is handled purely by query params.
  final queryParamValues = {
    'z': authObject.userName,
    'y': authObject.webApiKey,
  };

  for (final entry in args.entries) {
    final argKey = entry.key;
    final argValue = entry.value;

    // "abc.com/some-route/:foo/some-path" & {"foo": 4} --> "abc.com/some-route/4/some-path"
    if (withArgs.contains(':$argKey')) {
      withArgs = withArgs.replaceFirst(':$argKey', argValue.toString());
    } else if (argValue != null) {
      queryParamValues[argKey] = argValue.toString();
    }
  }

  final queryString = MapToQueryString(queryParamValues).toString();
  return '$withArgs?$queryString';
}

class MapToQueryString {
  final Map<String, String> map;
  MapToQueryString(this.map);

  @override
  String toString() {
    final pairs = map.entries.map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}');
    return pairs.join('&');
  }
}

/// Fetch an HTTP resource. This is publicly exposed in the
/// event you would like to access an endpoint that this
/// library does not currently support.
///
/// UNLESS YOU'RE SURE OF WHAT YOU'RE DOING, YOU PROBABLY
/// SHOULDN'T USE THIS FUNCTION.
///
/// At the time of writing, Node.js LTS (16.x)
/// does not yet support fetch. As a result, we pull in
/// isomorphic-unfetch for Node.js compatibility. Our support
/// matrix includes 14.x and 16.x.
///
/// @FIXME - When Node.js 20.x is released, remove the
/// isomorphic-unfetch dependency. At that point we will have
/// two major LTS versions that include a native fetch API.
Future<T> call<T>({
  required String url,
}) async {
  final response = await http.get(Uri.parse(url));

  return jsonDecode(response.body) as T;
}

typedef ID = Object; // Can be either String or num (int or double)

Map<String, dynamic> serializeProperties(
  dynamic originalData, {
  List<String>? shouldCastToNumbers,
  List<String>? shouldMapToBooleans,
}) {
  dynamic returnValue = originalData;

  if (originalData is List) {
    List<dynamic> cleanedArray = [];

    for (final entity in originalData) {
      cleanedArray.add(
        serializeProperties(
          entity,
          shouldCastToNumbers: shouldCastToNumbers,
          shouldMapToBooleans: shouldMapToBooleans,
        ),
      );
    }

    returnValue = cleanedArray;
  } else if (originalData is Map) {
    Map<String, dynamic> cleanedObject = {};

    originalData.forEach((originalKey, originalValue) {
      dynamic sanitizedValue = originalValue;
      if (shouldCastToNumbers?.contains(originalKey) == true) {
        sanitizedValue = originalValue == null ? null : num.tryParse(originalValue.toString());
      }

      if (shouldMapToBooleans?.contains(originalKey) == true) {
        if (originalValue == null) {
          sanitizedValue = null;
        } else {
          sanitizedValue = originalValue.toString() == '1' ? true : false;
        }
      }

      cleanedObject[naiveCamelCase(originalKey)] = serializeProperties(
        sanitizedValue,
        shouldCastToNumbers: shouldCastToNumbers,
        shouldMapToBooleans: shouldMapToBooleans,
      );
    });

    returnValue = cleanedObject;
  }

  return returnValue as Map<String, dynamic>;
}

String naiveCamelCase(String originalValue) {
  // "ID" --> "id", "URL" --> "url"
  if (originalValue.toUpperCase() == originalValue) {
    return originalValue.toLowerCase();
  }

  // "GameID" -> "gameID"
  String camelCased = originalValue[0].toLowerCase() + originalValue.substring(1);

  // "gameID" -> "gameId"
  camelCased = camelCased.replaceAll('ID', 'Id');

  // "badgeURL" --> "badgeUrl"
  camelCased = camelCased.replaceAll('URL', 'Url');

  // "rAPoints" -> "raPoints"
  camelCased = camelCased.replaceAll('rA', 'ra');

  return camelCased;
}
