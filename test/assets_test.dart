import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

        final allSystemsWithCollections = await container.read(allSupportedSystemsProvider.future);
        expect(allSystemsWithCollections.length, 76);
        final allSystems = allSystemsWithCollections.where((element) => !element.isCollection);
        expect(allSystems.length, 73);
        for (final system in allSystems) {
          await rootBundle.load("assets/images/white/${system.logo}");
          await rootBundle.load("assets/images/color/${system.logo}");
        }
      });
    },
  );
}
