import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retroachievements/retroachievements.dart';
import 'package:titanius/data/repo.dart';

export 'package:retroachievements/retroachievements.dart';

final retroAchievementsAuthProvider = Provider<AuthObject?>((ref) {
  final settings = ref.watch(settingsProvider).value;
  if (settings == null || !settings.hasRetroAchievements) {
    return null;
  }
  try {
    return buildAuthorization(
      username: settings.retroAchievementsUser!,
      webApiKey: settings.retroAchievementsApiKey!,
    );
  } catch (e) {
    debugPrint("Failed to build RA authorization: $e");
    return null;
  }
});

final retroAchievementsUserSummaryProvider =
    FutureProvider<UserSummary?>((ref) async {
  final auth = ref.watch(retroAchievementsAuthProvider);
  if (auth == null) {
    return null;
  }

  try {
    return await getUserSummary(
      auth,
      username: auth.username,
      recentGamesCount: 5,
      recentAchievementsCount: 5,
    );
  } on RetroAchievementsApiException catch (e) {
    debugPrint("RA API Error (${e.statusCode}): ${e.message}");
    return null;
  } catch (e, stack) {
    debugPrint("Failed to fetch RA user summary: $e\n$stack");
    return null;
  }
});

final retroAchievementsUserAwardsProvider =
    FutureProvider<UserAwards?>((ref) async {
  final auth = ref.watch(retroAchievementsAuthProvider);
  if (auth == null) {
    return null;
  }

  try {
    final awards = await getUserAwards(
      auth,
      username: auth.username,
    );
    debugPrint(
      "RA Awards: beatenHc=${awards.beatenHardcoreAwardsCount}, beatenSc=${awards.beatenSoftcoreAwardsCount}, mastery=${awards.masteryAwardsCount}, completion=${awards.completionAwardsCount}, total=${awards.totalAwardsCount}",
    );
    return awards;
  } on RetroAchievementsApiException catch (e) {
    debugPrint("RA API Error (${e.statusCode}): ${e.message}");
    return null;
  } catch (e, stack) {
    debugPrint("Failed to fetch RA user awards: $e\n$stack");
    return null;
  }
});

/// Validates RetroAchievements credentials by attempting to fetch the user profile.
/// Returns the [UserProfile] on success or throws an exception on failure.
Future<UserProfile> testRetroAchievementsCredentials({
  required String username,
  required String webApiKey,
}) async {
  final auth = buildAuthorization(
    username: username,
    webApiKey: webApiKey,
  );
  return getUserProfile(auth, username: username);
}
