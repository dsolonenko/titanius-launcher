part of 'package:titanius/pages/settings.dart';

class DaijishoWallpaperPacksPage extends HookConsumerWidget {
  const DaijishoWallpaperPacksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packs = ref.watch(daijishoPlatformWallpapersPacksProvider);

    final selected = useState("");

    useGamepad(ref, (location, key) {
      if (location != "/settings/daijisho") return;
      if (key == GamepadButton.b) {
        GoRouter.of(context).pop();
      }
      if (key == GamepadButton.x) {
        ref
            .read(settingsRepoProvider)
            .value!
            .resetDaijishoWallpaperPack()
            .then((value) => ref.refresh(settingsProvider));
        GoRouter.of(context).go("/");
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daijishō Wallpaper Packs'),
      ),
      bottomNavigationBar: const PromptBar(
        navigations: [],
        actions: [
          GamepadPrompt([GamepadButton.a], "Apply"),
          GamepadPrompt([GamepadButton.x], "Do not use wallpapers"),
          GamepadPrompt([GamepadButton.b], "Back"),
        ],
      ),
      body: packs.when(
        data: (packs) {
          return ListView.builder(
            key: const PageStorageKey("settings/emulators"),
            itemCount: packs.length,
            itemBuilder: (context, index) {
              final isSelected = selected.value == packs[index].rootPath || (selected.value.isEmpty && index == 0);
              final pack = packs[index];
              return ListTile(
                autofocus: isSelected,
                onFocusChange: (value) {
                  if (value) {
                    selected.value = pack.rootPath;
                  }
                },
                onTap: () {
                  ref
                      .read(settingsRepoProvider)
                      .value!
                      .setDaijishoWallpaperPack(pack.rootPath)
                      .then((value) => ref.refresh(settingsProvider));
                  GoRouter.of(context).go("/");
                },
                isThreeLine: true,
                title: Row(
                  children: [
                    Text(pack.name),
                    const SizedBox(width: 8),
                    const Text("by", textScaleFactor: 0.6, style: TextStyle(color: Colors.grey)),
                    const SizedBox(width: 4),
                    Text(pack.authors.join(", "), textScaleFactor: 0.8, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                subtitle: Text(pack.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: CachedNetworkImage(
                  imageUrl: pack.thumbnailUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.contain,
                ),
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
