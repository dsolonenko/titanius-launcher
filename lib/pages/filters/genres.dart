part of '../filter.dart';

class GenresFilterPage extends HookConsumerWidget {
  final String system;
  const GenresFilterPage({super.key, required this.system});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final games = ref.watch(gamesInFolderProvider(system));

    final selected = useState(GameGenres.None);

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
          GamepadPrompt([GamepadButton.b], "Back"),
        ],
      ),
      body: games.when(
        data: (gamelist) {
          final genres = gamelist.games.map((game) => Genres.lookupFromId(game.genreId)).toSet().toList()..sort();
          return ListView.builder(
            key: PageStorageKey("filter/$system/genres"),
            itemCount: genres.length,
            itemBuilder: (context, index) {
              final genre = genres[index];
              return ListTile(
                autofocus: selected.value == genre,
                onFocusChange: (value) {
                  if (value) {
                    selected.value = genre;
                  }
                },
                onTap: () {},
                title: Text(genre.name),
                trailing: checkBoxOffIcon,
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
