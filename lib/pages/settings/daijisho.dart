part of 'package:titanius/pages/settings.dart';

class DaijishoWallpaperPacksPage extends HookConsumerWidget {
  const DaijishoWallpaperPacksPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packs = ref.watch(daijishoPlatformWallpapersPacksProvider);
    final selectedIndex = usePersistentSelection('/settings/daijisho');

    useGamepad(ref, (location, key) {
      if (location != "/settings/daijisho") return;
      final packList = packs.value ?? [];
      if (packList.isEmpty) return;

      if (key == GamepadButton.up) {
        selectedIndex.value = (selectedIndex.value - 1).clamp(
          0,
          packList.length - 1,
        );
      }
      if (key == GamepadButton.down) {
        selectedIndex.value = (selectedIndex.value + 1).clamp(
          0,
          packList.length - 1,
        );
      }
      if (key == GamepadButton.a) {
        final pack =
            packList[selectedIndex.value.clamp(0, packList.length - 1)];
        ref
            .read(settingsRepoProvider)
            .setDaijishoWallpaperPack(pack.rootPath)
            .then((value) => ref.refresh(settingsProvider));
        GoRouter.of(context).go("/");
      }
      if (key == GamepadButton.b) {
        GoRouter.of(context).pop();
      }
      if (key == GamepadButton.x) {
        ref
            .read(settingsRepoProvider)
            .resetDaijishoWallpaperPack()
            .then((value) => ref.refresh(settingsProvider));
        GoRouter.of(context).go("/");
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Daijishō Wallpaper Packs')),
      bottomNavigationBar: const PromptBar(
        navigations: [],
        actions: [
          GamepadPrompt([GamepadButton.a], "Apply"),
          GamepadPrompt([GamepadButton.x], "Do not use wallpapers"),
          GamepadPrompt([GamepadButton.b], "Back"),
        ],
      ),
      body: packs.when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        data: (packs) {
          return ControllerListView.builder(
            selectedIndex: selectedIndex.value,
            key: const PageStorageKey("settings/daijisho"),
            itemCount: packs.length,
            itemBuilder: (context, index) {
              final pack = packs[index];
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
                            .read(settingsRepoProvider)
                            .setDaijishoWallpaperPack(pack.rootPath)
                            .then((value) => ref.refresh(settingsProvider));
                        GoRouter.of(context).go("/");
                      },
                      isThreeLine: true,
                      title: Row(
                        children: [
                          Text(
                            pack.name,
                            style: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "by",
                            textScaler: const TextScaler.linear(0.6),
                            style: TextStyle(
                              color: isSelected ? Colors.black54 : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            pack.authors.join(", "),
                            textScaler: const TextScaler.linear(0.8),
                            style: TextStyle(
                              color: isSelected ? Colors.black87 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        pack.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isSelected ? Colors.black87 : Colors.grey,
                        ),
                      ),
                      leading: CachedNetworkImage(
                        imageUrl: pack.thumbnailUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const SizedBox(
                          width: 48,
                          height: 48,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            Icons.broken_image_rounded,
                            color: Colors.grey,
                          ),
                        ),
                      ),
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
