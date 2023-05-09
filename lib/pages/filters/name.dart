part of '../filter.dart';

class NameFilterPage extends HookConsumerWidget {
  final String system;

  const NameFilterPage({super.key, required this.system});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(temporaryGameFilterProvider(system));

    useGamepad(ref, (location, key) {
      if (location != "/games/$system/filter/name") return;
      if (key == GamepadButton.b) {
        GoRouter.of(context).go("/games/$system/filter");
      }
    });

    return Scaffold(
        appBar: AppBar(
          title: const Text('Name'),
        ),
        bottomNavigationBar: const PromptBar(
          navigations: [],
          actions: [
            GamepadPrompt([GamepadButton.a], "Change"),
            GamepadPrompt([GamepadButton.b], "Apply"),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(filter.search, style: Theme.of(context).textTheme.headlineLarge),
              SizedBox(
                width: 2 * MediaQuery.of(context).size.width / 3,
                child: OnscreenKeyboard(
                  value: filter.search,
                  buttonColor: Theme.of(context).colorScheme.background.lighten(10),
                  focusColor: Theme.of(context).colorScheme.primary,
                  onChanged: (txt) {
                    ref.read(temporaryGameFilterProvider(system).notifier).setSearch(txt);
                  },
                  initialCase: InitialCase.LOWER_CASE,
                ),
              )
            ],
          ),
        ));
  }
}
