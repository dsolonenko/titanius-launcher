import 'dart:async';
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
  final String system;
  final String rom;
  final String message;

  ScraperProgress({
    required this.pending,
    required this.success,
    required this.error,
    required this.system,
    required this.rom,
    required this.message,
  });
}

class FakeServiceInstance extends ServiceInstance {
  final scrapeController = StreamController<Map<String, dynamic>?>();
  final updateController = StreamController<Map<String, dynamic>?>.broadcast();
  @override
  void invoke(String method, [Map<String, dynamic>? args]) {
    debugPrint("Invoking $method with $args");
    if (method == "scrape") {
      scrapeController.add(args);
    }
    if (method == "update") {
      updateController.add(args);
    }
  }

  @override
  Stream<Map<String, dynamic>?> on(String method) {
    debugPrint("Listening to $method");
    if (method == "scrape") {
      return scrapeController.stream;
    }
    if (method == "update") {
      return updateController.stream;
    }
    return const Stream.empty();
  }

  @override
  Future<void> stopSelf() async {
    debugPrint("Stopping service");
    scrapeController.close();
    updateController.close();
  }
}

@Riverpod(keepAlive: true)
class ScraperService extends _$ScraperService {
  @override
  dynamic build() {
    if (Platform.isAndroid) {
      return FlutterBackgroundService();
    } else {
      return FakeServiceInstance();
    }
  }
}

@Riverpod(keepAlive: true)
class ScraperProgressState extends _$ScraperProgressState {
  @override
  ScraperProgress build() {
    return ScraperProgress(pending: 0, success: 0, error: 0, system: "", rom: "", message: "Idle");
  }

  void set(ScraperProgress progress) {
    state = progress;
  }
}

class ScraperProgressWidget extends HookConsumerWidget {
  const ScraperProgressWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressState = ref.watch(scraperProgressStateProvider);
    final scraperService = ref.watch(scraperServiceProvider);
    useEffect(() {
      final sub = scraperService.on("update").listen((event) {
        ref.read(scraperProgressStateProvider.notifier).set(ScraperProgress(
              pending: event!["pending"] as int,
              success: event["success"] as int,
              error: event["error"] as int,
              system: event["system"] as String,
              rom: event["rom"] as String,
              message: event["msg"] as String,
            ));
      });
      return () => sub.cancel();
    }, []);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Scraper"),
        const SizedBox(width: 6),
        if (progressState.pending > 0) const Icon(Icons.pending),
        if (progressState.pending > 0) Text("${progressState.pending}"),
        if (progressState.pending > 0) const SizedBox(width: 4),
        if (progressState.success > 0) const Icon(Icons.check_circle),
        if (progressState.success > 0) Text("${progressState.success}"),
        if (progressState.success > 0) const SizedBox(width: 4),
        if (progressState.error > 0) const Icon(Icons.error),
        if (progressState.error > 0) Text("${progressState.error}"),
        const SizedBox(width: 6),
        if (progressState.system != "") Text(progressState.system),
        if (progressState.rom != "") const Text("> "),
        if (progressState.rom != "") Text(progressState.rom),
        if (progressState.message != "") const Text("> "),
        Text(progressState.message),
      ],
    );
  }
}
