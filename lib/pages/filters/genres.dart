part of 'package:titanius/pages/filter.dart';

class GenresFilterPage extends HookConsumerWidget {
  final String system;
  const GenresFilterPage({super.key, required this.system});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = ref.watch(gamesInFolderProvider(system));
    final filter = ref.watch(temporaryGameFilterProvider(system));
    final selectedIndex = usePersistentSelection(
      '/games/$system/filter/genres',
    );

    useGamepad(ref, (location, key) {
      if (location != "/games/$system/filter/genres") return;
      final gamelist = games.value;
      if (gamelist == null) return;
      final gameGenres = gamelist.games.map((game) => game.genreId).toSet();
      final genres = [...GameGenre.values];
      genres.retainWhere((element) => gameGenres.contains(element));
      if (genres.isEmpty) return;

      if (key == GamepadButton.up) {
        selectedIndex.value = (selectedIndex.value - 1).clamp(
          0,
          genres.length - 1,
        );
      }
      if (key == GamepadButton.down) {
        selectedIndex.value = (selectedIndex.value + 1).clamp(
          0,
          genres.length - 1,
        );
      }
      if (key == GamepadButton.confirm) {
        final genre = genres[selectedIndex.value.clamp(0, genres.length - 1)];
        ref
            .read(temporaryGameFilterProvider(system).notifier)
            .toggleGenre(genre);
      }
      if (key == GamepadButton.back) {
        GoRouter.of(context).go("/games/$system/filter");
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Genres')),
      bottomNavigationBar: const PromptBar(
        navigations: [],
        actions: [
          GamepadPrompt([GamepadButton.confirm], "Change"),
          GamepadPrompt([GamepadButton.back], "Apply"),
        ],
      ),
      body: games.when(
        data: (gamelist) {
          final gameGenres = gamelist.games.map((game) => game.genreId).toSet();
          final genres = [...GameGenre.values];
          genres.retainWhere((element) => gameGenres.contains(element));
          return ControllerGroupedListView<GameGenre, String>(
            key: PageStorageKey("filter/$system/genres"),
            selectedIndex: selectedIndex.value,
            elements: genres,
            groupBy: (genre) => GameGenre.getTopGenre(genre).longName,
            groupSeparatorBuilder: (String value) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(value, style: const TextStyle(color: Colors.grey)),
            ),
            indexedItemBuilder: (context, genre, index) {
              final isChecked = filter.genres.contains(genre);
              final isSelected = index == selectedIndex.value;
              return SelectedScrollTile(
                isSelected: isSelected,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  child: Material(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    child: ListTile(
                      selected: isSelected,
                      selectedColor: Colors.black,
                      selectedTileColor: Colors.transparent,
                      dense: true,
                      onTap: () {
                        selectedIndex.value = index;
                        ref
                            .read(temporaryGameFilterProvider(system).notifier)
                            .toggleGenre(genre);
                      },
                      title: Text(
                        genre.longName,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: isChecked ? checkBoxOnIcon : checkBoxOffIcon,
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const Center(child: Text('Error')),
      ),
    );
  }
}
