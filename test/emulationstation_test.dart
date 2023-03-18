// make sure riverpod is imported
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:titanius/data/systems.dart';

Future<void> main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'All logos should be available',
    (tester) async {
      await tester.runAsync(() async {
        // Use `runAsync` to make real asynchronous calls
        final container = ProviderContainer(overrides: [
          // define your overrides here if required
        ]);

        HttpOverrides.global = _MyHttpOverrides();
        final client = http.Client();

        final allSystems =
            await container.read(allSupportedSystemsProvider.future);
        expect(allSystems.length, 70);
        for (final system in allSystems) {
          expect((await client.head(Uri.parse(system.bigLogo))).statusCode, 200,
              reason: system.bigLogo);
          expect(
              (await client.head(Uri.parse(system.smallLogo))).statusCode, 200,
              reason: system.smallLogo);
        }
      });
    },
  );
}

class _MyHttpOverrides extends HttpOverrides {}
