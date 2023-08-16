import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'scraper_progress.g.dart';

class ScraperProgress {
  final int pending;
  final int success;
  final int error;
  final String message;

  ScraperProgress({
    required this.pending,
    required this.success,
    required this.error,
    required this.message,
  });
}

@Riverpod(keepAlive: true)
class ScraperProgressState extends _$ScraperProgressState {
  @override
  ScraperProgress build() {
    return ScraperProgress(pending: 0, success: 0, error: 0, message: "");
  }

  void set(ScraperProgress progress) {
    state = progress;
  }
}

class ScraperProgressWidget extends HookConsumerWidget {
  const ScraperProgressWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (Platform.isAndroid) {
      final progressState = ref.watch(scraperProgressStateProvider);
      useEffect(() {
        final service = FlutterBackgroundService();
        final sub = service.on("update").listen((event) {
          ref.read(scraperProgressStateProvider.notifier).set(ScraperProgress(
                pending: event!["pending"] as int,
                success: event["success"] as int,
                error: event["error"] as int,
                message: event["msg"] as String,
              ));
        });
        return () => sub.cancel();
      }, []);

      return Text(
          "Scraper p:${progressState.pending} s:${progressState.success} e:${progressState.error} ${progressState.message}");
    } else {
      return const Text("");
    }
  }
}
