import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:percent_indicator/percent_indicator.dart';

part 'scraper_progress.g.dart';

class ScraperProgress {
  final int total;
  final int pending;
  final int success;
  final int error;
  final String system;
  final String rom;
  final String message;

  ScraperProgress({
    required this.total,
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

  Future<bool> isRunning() async {
    return false;
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
    return ScraperProgress(total: 0, pending: 0, success: 0, error: 0, system: "", rom: "", message: "");
  }

  void set(ScraperProgress progress) {
    state = progress;
  }
}

final f = NumberFormat("0.0%");

class ScraperProgressWidget extends HookConsumerWidget {
  const ScraperProgressWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressState = ref.watch(scraperProgressStateProvider);

    if (progressState.message == "" || progressState.pending == 0) {
      return const SizedBox.shrink();
    }

    final double percent =
        progressState.total > 0 ? (progressState.total - progressState.pending) / progressState.total : 0;

    return LinearPercentIndicator(
      width: 100,
      lineHeight: 16,
      percent: percent,
      progressColor: Colors.green,
      backgroundColor: Colors.grey,
      center: Text(f.format(percent)),
      barRadius: const Radius.circular(8),
      leading: Text(progressState.system),
    );
  }
}
