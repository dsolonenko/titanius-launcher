import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:titanius/data/repo.dart';
import 'package:titanius/data/retroachievements.dart';
import 'package:titanius/data/state.dart';
import 'package:titanius/data/systems.dart';
import 'package:titanius/gamepad.dart';
import 'package:titanius/widgets/appbar.dart';
import 'package:titanius/widgets/prompt_bar.dart';
import 'package:titanius/widgets/retroachievements_card.dart';

class PlayerRetroAchievementsPage extends HookConsumerWidget {
  const PlayerRetroAchievementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasRetroAchievements = ref.watch(
      settingsProvider.select(
        (settings) => settings.value?.hasRetroAchievements ?? false,
      ),
    );
    final summaryAsync = ref.watch(retroAchievementsUserSummaryProvider);
    final awardsAsync = ref.watch(retroAchievementsUserAwardsProvider);
    final wantToPlayAsync = ref.watch(
      retroAchievementsUserWantToPlayListProvider,
    );
    final progressAsync = ref.watch(
      retroAchievementsUserCompletionProgressProvider,
    );

    final scrollController = useScrollController();
    final isRefreshing = useState<bool>(false);

    final summary = summaryAsync.value;
    final awards = awardsAsync.value;
    final wantToPlay = wantToPlayAsync.value;
    final progress = progressAsync.value;

    // Flatten recent achievements from summary
    final recentAchievementsList = useMemoized(() {
      if (summary == null) return <ExtendedRecentAchievementEntity>[];
      final list = <ExtendedRecentAchievementEntity>[];
      for (final gameMap in summary.recentAchievements.values) {
        list.addAll(gameMap.values);
      }
      list.sort((a, b) => b.dateAwarded.compareTo(a.dateAwarded));
      return list;
    }, [summary]);

    final completionList =
        progress?.results ?? const <UserCompletionProgressEntity>[];
    final wantToPlayList =
        wantToPlay?.results ?? const <UserWantToPlayItem>[];
    final visibleAwards = useMemoized(() {
      final list = List<UserAward>.from(
        awards?.visibleUserAwards ?? const <UserAward>[],
      );
      list.sort((a, b) {
        final dateA = DateTime.tryParse(a.awardedAt);
        final dateB = DateTime.tryParse(b.awardedAt);
        if (dateA != null && dateB != null) {
          return dateB.compareTo(dateA);
        }
        return b.awardedAt.compareTo(a.awardedAt);
      });
      return list;
    }, [awards]);
    final recent10 = recentAchievementsList.take(10).toList();

    useGamepad(ref, (location, key) async {
      if (location != "/games/retroachievements") return;

      if (key == GamepadButton.up || key == GamepadButton.down) {
        if (!scrollController.hasClients) return;
        const scrollStep = 80.0;
        final delta = key == GamepadButton.up ? -scrollStep : scrollStep;
        final position = scrollController.position;
        final target = (scrollController.offset + delta).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
        scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
      if (key == GamepadButton.rightStickUp ||
          key == GamepadButton.rightStickDown) {
        if (!scrollController.hasClients) return;
        const scrollStep = 80.0;
        final delta = key == GamepadButton.rightStickUp
            ? -scrollStep
            : scrollStep;
        final position = scrollController.position;
        final target = (scrollController.offset + delta).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
        scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
      if (key == GamepadButton.l1 || key == GamepadButton.r1) {
        if (!scrollController.hasClients) return;
        const scrollStep = 240.0;
        final delta = key == GamepadButton.l1 ? -scrollStep : scrollStep;
        final position = scrollController.position;
        final target = (scrollController.offset + delta).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
        scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
      if (key == GamepadButton.l2 || key == GamepadButton.r2) {
        final allSystems = ref.read(detectedSystemsProvider).value ?? [];
        if (allSystems.isNotEmpty) {
          final currentIdx = allSystems.indexWhere(
            (s) => s.id == "retroachievements",
          );
          final baseIdx = currentIdx != -1 ? currentIdx : 0;
          final nextIdx = key == GamepadButton.r2
              ? (baseIdx + 1) % allSystems.length
              : (baseIdx - 1 + allSystems.length) % allSystems.length;
          ref.read(selectedSystemProvider.notifier).state = nextIdx;
          GoRouter.of(context).go("/games/${allSystems[nextIdx].id}");
        }
      }
      if (key == GamepadButton.y) {
        if (isRefreshing.value) return;
        isRefreshing.value = true;
        try {
          await refreshAllPlayerRetroAchievementsData(ref);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("RetroAchievements progress updated"),
                duration: Duration(seconds: 2),
              ),
            );
          }
        } finally {
          isRefreshing.value = false;
        }
      }
      if (key == GamepadButton.back) {
        if (context.mounted) {
          GoRouter.of(context).go("/");
        }
      }
      if (key == GamepadButton.start) {
        if (context.mounted) {
          GoRouter.of(context).go("/settings?source=retroachievements");
        }
      }
    });

    if (!hasRetroAchievements) {
      return Scaffold(
        appBar: const CustomAppBar(),
        bottomNavigationBar: const PromptBar(
          navigations: [
            GamepadPrompt([GamepadButton.start], "Menu"),
          ],
          actions: [
            GamepadPrompt([GamepadButton.back], "Back"),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "\u{1F3C6}",
                style: TextStyle(
                  fontFamily: "Prompt",
                  fontSize: 48,
                  color: Colors.amberAccent,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "RetroAchievements Not Configured",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Please configure your RetroAchievements username and Web API key in Settings.",
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  GoRouter.of(context).push("/settings/retroachievements");
                },
                icon: const Icon(Icons.settings),
                label: const Text("Open RetroAchievements Settings"),
              ),
            ],
          ),
        ),
      );
    }

    final isLoading = summaryAsync.isLoading && summary == null;

    return Scaffold(
      appBar: const CustomAppBar(),
      bottomNavigationBar: PromptBar(
        navigations: const [
          GamepadPrompt([
            GamepadButton.upDown,
            GamepadButton.rightStickUp,
            GamepadButton.rightStickDown,
          ], "Scroll"),
          GamepadPrompt([GamepadButton.l1, GamepadButton.r1], "Page"),
          GamepadPrompt([GamepadButton.l2, GamepadButton.r2], "System"),
          GamepadPrompt([GamepadButton.start], "Menu"),
        ],
        actions: [
          GamepadPrompt(const [
            GamepadButton.y,
          ], isRefreshing.value ? "Refreshing..." : "Refresh"),
          const GamepadPrompt([GamepadButton.back], "Back"),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const RetroAchievementsPlayerHeaderCard(),
                    const RetroAchievementsGamesOverviewBar(),
                    if (wantToPlayList.isNotEmpty) ...[
                      _buildSectionHeader(
                        "Want to Play",
                        wantToPlayList.length,
                      ),
                      for (final game in wantToPlayList)
                        _buildWantToPlayTile(context, game),
                    ],
                    if (visibleAwards.isNotEmpty) ...[
                      _buildSectionHeader("Game Awards", visibleAwards.length),
                      for (final award in visibleAwards)
                        _buildUserAwardTile(context, award),
                    ],
                    if (recent10.isNotEmpty) ...[
                      _buildSectionHeader(
                        "Recent Achievements",
                        recent10.length,
                      ),
                      for (final achievement in recent10)
                        _buildRecentAchievementTile(context, achievement),
                    ],
                    if (completionList.isNotEmpty) ...[
                      _buildSectionHeader(
                        "Game Progress",
                        completionList.length,
                      ),
                      for (final game in completionList)
                        _buildGameProgressTile(context, game),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWantToPlayTile(
    BuildContext context,
    UserWantToPlayItem item,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white10),
      ),
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
              child: item.imageIcon.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: MediaUrls.gameImageUrl(item.imageIcon),
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Container(
                        color: Colors.black26,
                        child: const Center(
                          child: Icon(
                            Icons.bookmark_outline,
                            size: 24,
                            color: Colors.amberAccent,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.black26,
                      child: const Center(
                        child: Icon(
                          Icons.bookmark_outline,
                          size: 24,
                          color: Colors.amberAccent,
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
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.1,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${item.consoleName} • ${item.achievementsPublished} achievements • ${item.pointsTotal} pts",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      height: 1.1,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.bookmark,
                    size: 14,
                    color: Colors.amberAccent,
                  ),
                  const SizedBox(height: 1),
                  Text(
                    "${item.pointsTotal} pts",
                    style: const TextStyle(
                      fontSize: 7.5,
                      height: 1.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.amberAccent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserAwardTile(BuildContext context, UserAward award) {
    final isMastery = award.awardType == AwardType.masteryCompletion;
    final isBeaten = award.awardType == AwardType.gameBeaten;
    final trophyColor = isMastery
        ? Colors.amberAccent
        : (isBeaten ? Colors.lightBlueAccent : Colors.purpleAccent);

    final awardLabel = isMastery
        ? "Mastery"
        : (isBeaten ? "Beaten" : (award.awardType?.value ?? 'Award'));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white10),
      ),
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
              child: award.imageIcon.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: MediaUrls.gameImageUrl(award.imageIcon),
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Container(
                        color: Colors.black26,
                        child: const Center(
                          child: Icon(
                            Icons.emoji_events,
                            size: 24,
                            color: Colors.amberAccent,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.black26,
                      child: const Center(
                        child: Icon(
                          Icons.emoji_events,
                          size: 24,
                          color: Colors.amberAccent,
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
                    award.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.1,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${award.consoleName} • ${_formatAwardDate(award.awardedAt)}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      height: 1.1,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "\u{1F3C6}",
                    style: TextStyle(
                      fontFamily: "Prompt",
                      fontSize: 14,
                      color: trophyColor,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    awardLabel,
                    style: TextStyle(
                      fontSize: 7.5,
                      height: 1.0,
                      fontWeight: FontWeight.bold,
                      color: trophyColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatAwardDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      final parsed = DateTime.parse(dateStr);
      return DateFormat.yMMMd().format(parsed);
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 2),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            "($count)",
            style: const TextStyle(fontSize: 10, color: Colors.white38),
          ),
        ],
      ),
    );
  }

  Widget _buildGameProgressTile(
    BuildContext context,
    UserCompletionProgressEntity game,
  ) {
    final isMastered =
        game.highestAwardKind == AwardKind.mastered ||
        (game.numAwardedHardcore == game.maxPossible && game.maxPossible > 0);
    final isCompleted =
        game.highestAwardKind == AwardKind.completed ||
        (game.numAwarded == game.maxPossible && game.maxPossible > 0);
    final trophyColor = isMastered
        ? Colors.amberAccent
        : (isCompleted ? Colors.lightBlueAccent : Colors.white70);

    final pct = game.maxPossible > 0
        ? (game.numAwarded / game.maxPossible * 100).toInt()
        : 0;
    final hcText = game.numAwardedHardcore > 0
        ? " • ${game.numAwardedHardcore} HC"
        : "";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white10),
      ),
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
              child: game.imageIcon.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: MediaUrls.gameImageUrl(game.imageIcon),
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Container(
                        color: Colors.black26,
                        child: const Center(
                          child: Icon(
                            Icons.videogame_asset,
                            size: 24,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.black26,
                      child: const Center(
                        child: Icon(
                          Icons.videogame_asset,
                          size: 24,
                          color: Colors.white54,
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
                    game.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.1,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${game.consoleName} • ${game.numAwarded}/${game.maxPossible} ($pct%)$hcText",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      height: 1.1,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              child: Text(
                "\u{1F3C6}",
                style: TextStyle(
                  fontFamily: "Prompt",
                  fontSize: 14,
                  color: trophyColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAchievementTile(
    BuildContext context,
    ExtendedRecentAchievementEntity achievement,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white10),
      ),
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
              child: achievement.badgeName.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: MediaUrls.badgeUrl(achievement.badgeName),
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Container(
                        color: Colors.black26,
                        child: const Center(
                          child: Icon(
                            Icons.emoji_events,
                            size: 24,
                            color: Colors.amberAccent,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.black26,
                      child: const Center(
                        child: Icon(
                          Icons.emoji_events,
                          size: 24,
                          color: Colors.amberAccent,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.1,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${achievement.gameTitle} • ${achievement.description}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      height: 1.1,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              child: Text(
                "+${achievement.points} pts",
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: FontWeight.bold,
                  color: Colors.amberAccent,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
