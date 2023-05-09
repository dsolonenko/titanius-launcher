part of '../filter.dart';

class GenresFilterPage extends HookConsumerWidget {
  final String system;
  const GenresFilterPage({super.key, required this.system});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = ref.watch(gamesInFolderProvider(system));
    final filter = ref.watch(temporaryGameFilterProvider(system));

    final selected = useState<GameGenres?>(null);

    useGamepad(ref, (location, key) {
      if (location != "/games/$system/filter/genres") return;
      if (key == GamepadButton.b) {
        GoRouter.of(context).go("/games/$system/filter");
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Genres'),
      ),
      bottomNavigationBar: const PromptBar(
        navigations: [],
        actions: [
          GamepadPrompt([GamepadButton.a], "Change"),
          GamepadPrompt([GamepadButton.b], "Apply"),
        ],
      ),
      body: games.when(
        data: (gamelist) {
          final gameGenres = gamelist.games.map((game) => game.genreId).toSet();
          final genres = [...Genres.orderedList];
          genres.retainWhere((element) => gameGenres.contains(element));
          return GroupedListView<GameGenres, String>(
            key: PageStorageKey("filter/$system/genres"),
            elements: genres,
            groupBy: (genre) => Genres.getName(Genres.getTopGenre(genre)),
            groupSeparatorBuilder: (String value) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                value,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            indexedItemBuilder: (context, genre, index) {
              final isSelected = filter.genres.contains(genre);
              return ListTile(
                autofocus: selected.value == genre || (selected.value == null && index == 0),
                onFocusChange: (value) {
                  if (value) {
                    selected.value = genre;
                  }
                },
                onTap: () {
                  ref.read(temporaryGameFilterProvider(system).notifier).toggleGenre(genre);
                },
                title: Text(Genres.getName(genre)),
                trailing: isSelected ? checkBoxOnIcon : checkBoxOffIcon,
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => const Center(
          child: Text('Error'),
        ),
      ),
    );
  }
}
