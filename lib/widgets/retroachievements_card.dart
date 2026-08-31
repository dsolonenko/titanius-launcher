import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:titanius/data/repo.dart';
import 'package:titanius/data/retroachievements.dart';

const Color _raLabelBlue = Color(0xFF5B9BF3);

class RetroAchievementsPlayerHeaderCard extends HookConsumerWidget {
  final EdgeInsetsGeometry? margin;

  const RetroAchievementsPlayerHeaderCard({super.key, this.margin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(
      settingsProvider.select(
        (settings) => (
          enabled: settings.value?.hasRetroAchievements ?? false,
          username: settings.value?.retroAchievementsUser,
        ),
      ),
    );
    final summary = ref.watch(retroAchievementsUserSummaryProvider).value;

    if (!account.enabled) {
      return const SizedBox.shrink();
    }

    final numberFormat = NumberFormat.decimalPattern();

    final pointsFormatted = numberFormat.format(summary?.totalPoints ?? 0);
    final truePointsFormatted = numberFormat.format(
      summary?.totalTruePoints ?? 0,
    );

    // Member Since formatting: "12 Oct 2021"
    String memberSinceFormatted = "--";
    if (summary?.memberSince.isNotEmpty ?? false) {
      final dt = DateTime.tryParse(summary!.memberSince);
      if (dt != null) {
        memberSinceFormatted = DateFormat('d MMM yyyy').format(dt);
      } else {
        memberSinceFormatted = summary.memberSince;
      }
    }

    // Last Activity formatting
    String lastActivityText = "";
    if (summary?.lastActivity?.timestamp.isNotEmpty ?? false) {
      final dt = DateTime.tryParse(summary!.lastActivity!.timestamp);
      if (dt != null) {
        lastActivityText = _formatRelativeTime(dt);
      } else {
        lastActivityText = summary.lastActivity!.timestamp;
      }
    }

    final rank = summary?.rank ?? 0;
    final totalRanked = summary?.totalRanked ?? 0;

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Square avatar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24, width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: CachedNetworkImage(
                imageUrl: MediaUrls.userPicUrl(
                  summary?.userPic.isNotEmpty == true
                      ? summary!.userPic
                      : (account.username ?? ''),
                ),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) =>
                    const Icon(Icons.person, size: 60, color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // User details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Big Username
                Text(
                  account.username ?? summary?.userPic ?? "Player",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _raLabelBlue,
                  ),
                ),
                const SizedBox(height: 6),

                // Points: 1,870 (3,276)
                _buildRow(
                  "Points: ",
                  TextSpan(
                    text: pointsFormatted,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: " ($truePointsFormatted)",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // Site Rank: #57,401 of 161,143 (Top 35.62%)
                if (rank > 0 && totalRanked > 0) ...[
                  _buildRankRow(rank, totalRanked, numberFormat),
                  const SizedBox(height: 4),
                ],

                // Last Activity: 1 second ago
                if (lastActivityText.isNotEmpty) ...[
                  _buildRow(
                    "Last Activity: ",
                    TextSpan(
                      text: lastActivityText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                // Member Since: 12 Oct 2021
                _buildRow(
                  "Member Since: ",
                  TextSpan(
                    text: memberSinceFormatted,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, TextSpan valueSpan) {
    return Text.rich(
      TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: _raLabelBlue,
        ),
        children: [valueSpan],
      ),
    );
  }

  Widget _buildRankRow(int rank, int totalRanked, NumberFormat format) {
    final rankStr = "#${format.format(rank)}";
    final totalStr = " of ${format.format(totalRanked)}";
    final pct = (rank / totalRanked * 100).toStringAsFixed(2);

    return Text.rich(
      TextSpan(
        text: "Site Rank: ",
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: _raLabelBlue,
        ),
        children: [
          TextSpan(
            text: rankStr,
            style: const TextStyle(
              color: Colors.amberAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          TextSpan(
            text: "$totalStr (Top $pct%)",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) {
      final s = diff.inSeconds <= 1 ? 1 : diff.inSeconds;
      return "$s second${s == 1 ? '' : 's'} ago";
    }
    if (diff.inMinutes < 60) {
      return "${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago";
    }
    if (diff.inHours < 24) {
      return "${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago";
    }
    if (diff.inDays < 30) {
      return "${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago";
    }
    return DateFormat('d MMM yyyy').format(dt);
  }
}

class RetroAchievementsGamesOverviewBar extends HookConsumerWidget {
  final EdgeInsetsGeometry? margin;

  const RetroAchievementsGamesOverviewBar({super.key, this.margin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasRetroAchievements = ref.watch(
      settingsProvider.select(
        (settings) => settings.value?.hasRetroAchievements ?? false,
      ),
    );
    if (!hasRetroAchievements) {
      return const SizedBox.shrink();
    }

    final awards = ref.watch(retroAchievementsUserAwardsProvider).value;
    final progress = ref
        .watch(retroAchievementsUserCompletionProgressProvider)
        .value;

    final completionList =
        progress?.results ?? const <UserCompletionProgressEntity>[];
    final playedCount = progress?.total ?? completionList.length;
    final masteredCount = (awards != null && awards.masteryAwardsCount > 0)
        ? awards.masteryAwardsCount
        : completionList
              .where(
                (g) =>
                    g.highestAwardKind == AwardKind.mastered ||
                    (g.numAwardedHardcore == g.maxPossible &&
                        g.maxPossible > 0),
              )
              .length;
    final beatenCount =
        (awards != null &&
            (awards.beatenHardcoreAwardsCount > 0 ||
                awards.beatenSoftcoreAwardsCount > 0 ||
                awards.completionAwardsCount > 0))
        ? (awards.beatenHardcoreAwardsCount +
              awards.beatenSoftcoreAwardsCount +
              awards.completionAwardsCount)
        : completionList
              .where(
                (g) =>
                    g.highestAwardKind == AwardKind.beatenHardcore ||
                    g.highestAwardKind == AwardKind.beatenSoftcore ||
                    g.highestAwardKind == AwardKind.completed,
              )
              .length;
    final unfinishedCount = (playedCount - masteredCount - beatenCount).clamp(
      0,
      playedCount,
    );

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn("Played", playedCount.toString(), Colors.white),
          _buildDivider(),
          _buildStatColumn(
            "Unfinished",
            unfinishedCount.toString(),
            const Color(0xFFFFA726),
          ),
          _buildDivider(),
          _buildStatColumn(
            "Beaten",
            beatenCount.toString(),
            const Color(0xFF42A5F5),
          ),
          _buildDivider(),
          _buildStatColumn(
            "Mastered",
            masteredCount.toString(),
            const Color(0xFFFFD54F),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color valueColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.white60),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 24, width: 1, color: Colors.white12);
  }
}
