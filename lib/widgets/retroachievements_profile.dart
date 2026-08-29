import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:titanius/data/repo.dart';
import 'package:titanius/data/retroachievements.dart';

class RetroAchievementsProfileWidget extends ConsumerWidget {
  const RetroAchievementsProfileWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider).value;
    if (settings == null ||
        !settings.hasRetroAchievements ||
        !settings.showRetroAchievementsInAppBar) {
      return const SizedBox.shrink();
    }

    final userAwardsAsync = ref.watch(retroAchievementsUserAwardsProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        onTap: () {
          GoRouter.of(context).push('/settings/retroachievements');
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF141414).withValues(alpha: 0.95),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            border: Border.all(
              color: Colors.amberAccent.withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.amberAccent,
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: MediaUrls.userPicUrl(
                      settings.retroAchievementsUser!,
                    ),
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const Icon(
                      Icons.emoji_events_outlined,
                      size: 24,
                      color: Colors.amberAccent,
                    ),
                    placeholder: (context, url) => Container(
                      color: Colors.white24,
                      child: const Icon(
                        Icons.person,
                        size: 22,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Username
              Text(
                settings.retroAchievementsUser!,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.3,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),

              // Divider
              Container(
                height: 16,
                width: 1.5,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: Colors.white30,
              ),

              // Beaten & Mastered Stats
              userAwardsAsync.when(
                data: (awards) {
                  final masteredCount = awards?.masteryAwardsCount ?? 0;
                  final beatenCount = awards != null
                      ? (awards.beatenHardcoreAwardsCount - masteredCount)
                          .clamp(0, awards.beatenHardcoreAwardsCount)
                      : 0;

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _statusDot(const Color(0xFFE2E2E2)),
                      const SizedBox(width: 5),
                      Text(
                        '$beatenCount',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEDEDED),
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _statusDot(const Color(0xFFFFD700)),
                      const SizedBox(width: 5),
                      Text(
                        '$masteredCount',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFD700),
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                  ),
                ),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusDot(Color color) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.7),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}
