import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:titanius/data/repo.dart';
import 'package:titanius/data/retroachievements.dart';
import 'package:titanius/data/state.dart';
import 'package:titanius/gamepad.dart';
import 'package:titanius/widgets/prompt_bar.dart';
import 'package:titanius/widgets/selected_scroll_tile.dart';

class GameAchievementsPage extends HookConsumerWidget {
  final String system;
  final int hash;

  const GameAchievementsPage({
    super.key,
    required this.system,
    required this.hash,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGame = ref.watch(selectedGameProvider(system));
    final gamelist = ref.watch(filteredGamesInFolderProvider(system)).value;
    final game = (selectedGame?.hash == hash ? selectedGame : null) ??
        selectedGame ??
        gamelist?.games.firstWhereOrNull((g) => g.hash == hash);
    if (game == null) {
      return const Scaffold(body: Center(child: Text("Game not found")));
    }

    final gameRaAsync = ref.watch(gameRetroAchievementsProvider(game));
    final raGame = gameRaAsync.value;
    final raGameId = raGame?.raGameId;

    final achievementsAsync = raGameId != null
        ? ref.watch(gameRetroAchievementsDetailsProvider(raGameId))
        : null;

    final isRefreshing = useState<bool>(false);

    final selectedIndex = usePersistentSelection(
      '/games/$system/game/$hash/achievements',
      initialIndex: 0,
    );

    final achievementsList = achievementsAsync?.value?.achievements.values.toList()
      ?..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    useGamepad(ref, (location, key) async {
      if (location != "/games/$system/game/$hash/achievements" &&
          !location.endsWith("/achievements")) {
        return;
      }
      if (key == GamepadButton.back) {
        GoRouter.of(context).pop();
      }
      if (key == GamepadButton.y && raGameId != null) {
        if (isRefreshing.value) return;
        isRefreshing.value = true;
        Fluttertoast.showToast(
          msg: "Refreshing achievements...",
          toastLength: Toast.LENGTH_SHORT,
        );
        try {
          final auth = ref.read(retroAchievementsAuthProvider);
          if (auth != null) {
            final cacheRepo = ref.read(retroAchievementsCacheRepoProvider);
            final updated = await fetchGameInfoAndUserProgressWithCache(
              auth: auth,
              gameId: raGameId,
              cacheRepo: cacheRepo,
              forceRefresh: true,
              allowNetwork: true,
            );
            if (updated != null) {
              ref.read(retroAchievementsProgressMapProvider.notifier).set(raGameId, updated);
            }
            ref.invalidate(gameRetroAchievementsDetailsProvider(raGameId));
            Fluttertoast.showToast(
              msg: "Achievements updated",
              toastLength: Toast.LENGTH_SHORT,
            );
          }
        } catch (e) {
          Fluttertoast.showToast(
            msg: "Failed to refresh: $e",
            toastLength: Toast.LENGTH_LONG,
          );
        } finally {
          isRefreshing.value = false;
        }
      }
      final count = achievementsList?.length ?? 0;
      if (count == 0) return;

      if (key == GamepadButton.up) {
        selectedIndex.value = (selectedIndex.value - 1).clamp(0, count - 1);
      }
      if (key == GamepadButton.down) {
        selectedIndex.value = (selectedIndex.value + 1).clamp(0, count - 1);
      }
      if (key == GamepadButton.rightStickUp || key == GamepadButton.l1) {
        selectedIndex.value = (selectedIndex.value - 5).clamp(0, count - 1);
      }
      if (key == GamepadButton.rightStickDown || key == GamepadButton.r1) {
        selectedIndex.value = (selectedIndex.value + 5).clamp(0, count - 1);
      }
    });

    Widget buildBody() {
      if (gameRaAsync.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (gameRaAsync.hasError) {
        return Center(
          child: Text(
            "Error matching game: ${gameRaAsync.error}",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        );
      }
      if (raGameId == null || raGameId == 0) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.sports_esports_outlined, size: 48, color: Colors.white38),
              SizedBox(height: 12),
              Text(
                "No RetroAchievements match found for this game",
                style: TextStyle(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
      if (achievementsAsync == null || achievementsAsync.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return achievementsAsync.when(
        data: (details) {
          if (details == null) {
            return const Center(
              child: Text(
                "Unable to load achievements for this title.\nPlease check your RetroAchievements login in Settings.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

                final list = achievementsList ?? [];
                final earnedList = list
                    .where((a) => a.dateEarned != null || a.dateEarnedHardcore != null)
                    .toList();
                final unlockedCount = details.numAwardedToUser > 0
                    ? details.numAwardedToUser
                    : earnedList.length;
                final totalCount = details.numAchievements > 0
                    ? details.numAchievements
                    : list.length;
                final totalPoints = list.fold<int>(0, (sum, a) => sum + a.points);
                final earnedPoints = earnedList.fold<int>(0, (sum, a) => sum + a.points);

                final progressFraction =
                    totalCount > 0 ? (unlockedCount / totalCount).clamp(0.0, 1.0) : 0.0;

                return Column(
                  children: [
                    // Header progress card
                    Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.amberAccent.withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (details.imageIcon.isNotEmpty)
                                Container(
                                  width: 48,
                                  height: 48,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.amberAccent,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(5),
                                    child: CachedNetworkImage(
                                      imageUrl: MediaUrls.gameImageUrl(
                                        details.imageIcon,
                                      ),
                                      fit: BoxFit.cover,
                                      errorWidget: (_, _, _) => const Icon(
                                        Icons.sports_esports,
                                        color: Colors.amberAccent,
                                      ),
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      details.title,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "$unlockedCount / $totalCount Unlocked • $earnedPoints / $totalPoints Points",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.amberAccent,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (details.highestAwardKind != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amberAccent.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.amberAccent,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Text(
                                    details.highestAwardKind == AwardKind.mastered
                                        ? "🟡 Mastered"
                                        : "⚪ Beaten",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progressFraction,
                              minHeight: 6,
                              backgroundColor: Colors.white12,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.amberAccent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Achievements List
                    Expanded(
                      child: ControllerListView.builder(
                        key: PageStorageKey(
                          'games/$system/game/$hash/achievements',
                        ),
                        selectedIndex: selectedIndex.value,
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final achievement = list[index];
                          final isSelected = index == selectedIndex.value;
                          final isUnlocked =
                              achievement.dateEarned != null ||
                              achievement.dateEarnedHardcore != null;

                          return SelectedScrollTile(
                            isSelected: isSelected,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              height: 58,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : (isUnlocked
                                          ? Colors.amberAccent.withValues(alpha: 0.3)
                                          : Colors.white10),
                                ),
                              ),
                              child: InkWell(
                                onTap: () => selectedIndex.value = index,
                                borderRadius: BorderRadius.circular(6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(
                                      width: 58,
                                      height: 58,
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.horizontal(
                                          left: Radius.circular(5),
                                        ),
                                        child: CachedNetworkImage(
                                          imageUrl: MediaUrls.badgeUrl(
                                            achievement.badgeName,
                                            isUnlocked: isUnlocked,
                                          ),
                                          fit: BoxFit.cover,
                                          errorWidget: (_, _, _) => Container(
                                            color: Colors.black26,
                                            child: Center(
                                              child: isUnlocked
                                                  ? const Text(
                                                      "\u{1F3C6}",
                                                      style: TextStyle(
                                                        fontFamily: "Prompt",
                                                        fontSize: 20,
                                                        color: Colors.amber,
                                                      ),
                                                    )
                                                  : const Icon(
                                                      Icons.lock_outline,
                                                      size: 20,
                                                      color: Colors.grey,
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              achievement.title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                                height: 1.1,
                                                color: isSelected
                                                    ? Colors.black
                                                    : (isUnlocked
                                                        ? Colors.white
                                                        : Colors.white70),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              achievement.description,
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                height: 1.1,
                                                color: isSelected
                                                    ? Colors.black87
                                                    : Colors.grey,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 2,
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "${achievement.points} pts",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                              height: 1.1,
                                              color: isSelected
                                                  ? Colors.black87
                                                  : (isUnlocked
                                                      ? Colors.amberAccent
                                                      : Colors.grey),
                                            ),
                                          ),
                                          if (isUnlocked) ...[
                                            const SizedBox(height: 1),
                                            Text(
                                              _formatDateEarned(
                                                achievement.dateEarnedHardcore ??
                                                    achievement.dateEarned,
                                                isHardcore:
                                                    achievement.dateEarnedHardcore !=
                                                        null,
                                              ),
                                              style: TextStyle(
                                                fontSize: 8.5,
                                                height: 1.1,
                                                fontStyle: FontStyle.italic,
                                                color: isSelected
                                                    ? Colors.black54
                                                    : Colors.amberAccent.withValues(
                                                        alpha: 0.8,
                                                      ),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      "Fetching achievements...",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              error: (error, _) => Center(
                child: Text(
                  "Error loading achievements: $error",
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(
          game.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (isRefreshing.value)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.amberAccent,
                  ),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.white24, height: 1.0),
        ),
      ),
      bottomNavigationBar: PromptBar(
        navigations: const [
          GamepadPrompt([GamepadButton.upDown], "Navigate"),
          GamepadPrompt([GamepadButton.rightStickUp, GamepadButton.rightStickDown], "Scroll"),
        ],
        actions: [
          if (raGameId != null)
            const GamepadPrompt([GamepadButton.y], "Refresh"),
          const GamepadPrompt([GamepadButton.back], "Back"),
        ],
      ),
      body: buildBody(),
    );
  }

  String _formatDateEarned(String? dateStr, {required bool isHardcore}) {
    if (dateStr == null) return isHardcore ? "Hardcore" : "Unlocked";
    try {
      final parsed = DateTime.parse(dateStr);
      final formatted = DateFormat('d MMM yyyy').format(parsed);
      return isHardcore ? "$formatted (HC)" : formatted;
    } catch (_) {
      return isHardcore ? "$dateStr (HC)" : dateStr;
    }
  }
}
