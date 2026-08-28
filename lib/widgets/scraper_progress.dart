import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';

class ScraperProgress {
  final int total;
  final int pending;
  final int success;
  final int error;
  final String system;
  final String rom;
  final String message;

  bool get isRunning =>
      message.isNotEmpty &&
      message != "Done" &&
      message != "Cancelled" &&
      message != "Quota exceeded";

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
  final scrapeController = StreamController<Map<String, dynamic>?>.broadcast();
  final updateController = StreamController<Map<String, dynamic>?>.broadcast();
  final stopController = StreamController<Map<String, dynamic>?>.broadcast();
  bool _running = false;

  @override
  void invoke(String method, [Map<String, dynamic>? args]) {
    debugPrint("Invoking $method with $args");
    if (method == "scrape") {
      _running = true;
      scrapeController.add(args);
    } else if (method == "update") {
      final msg = args?["msg"] as String?;
      if (msg == "Done" || msg == "Cancelled" || msg == "Quota exceeded") {
        _running = false;
      }
      updateController.add(args);
    } else if (method == "stop") {
      _running = false;
      stopController.add(args);
    }
  }

  @override
  Stream<Map<String, dynamic>?> on(String method) {
    debugPrint("Listening to $method");
    if (method == "scrape") {
      return scrapeController.stream;
    } else if (method == "update") {
      return updateController.stream;
    } else if (method == "stop") {
      return stopController.stream;
    }
    return const Stream.empty();
  }

  @override
  Future<void> stopSelf() async {
    debugPrint("Stopping service");
    _running = false;
  }

  Future<bool> isRunning() async {
    return _running;
  }
}

final scraperServiceProvider = Provider<dynamic>((ref) {
  if (Platform.isAndroid) {
    return FlutterBackgroundService();
  } else {
    return FakeServiceInstance();
  }
});

class ScraperProgressStateNotifier extends Notifier<ScraperProgress> {
  @override
  ScraperProgress build() {
    return ScraperProgress(total: 0, pending: 0, success: 0, error: 0, system: "", rom: "", message: "");
  }

  void set(ScraperProgress progress) {
    state = progress;
  }
}

final scraperProgressStateProvider = NotifierProvider<ScraperProgressStateNotifier, ScraperProgress>(
  ScraperProgressStateNotifier.new,
);

final f = NumberFormat("0.0%");

class ScraperProgressWidget extends HookConsumerWidget {
  const ScraperProgressWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressState = ref.watch(scraperProgressStateProvider);

    if (!progressState.isRunning) {
      return const SizedBox.shrink();
    }

    final double percent =
        progressState.total > 0 ? (progressState.total - progressState.pending) / progressState.total : 0;

    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    final lineHeight = 16.0 * scale;
    final width = 100.0 * scale;

    return LinearPercentIndicator(
      width: width,
      lineHeight: lineHeight,
      percent: percent,
      progressColor: Colors.green,
      backgroundColor: Colors.grey,
      center: Text(
        f.format(percent),
        style: const TextStyle(
          fontSize: 10,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      barRadius: Radius.circular(lineHeight / 2),
      leading: Text(progressState.system),
    );
  }
}
