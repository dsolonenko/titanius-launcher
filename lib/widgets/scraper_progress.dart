import 'package:flutter/material.dart';
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

  factory ScraperProgress.fromJson(Map<String, dynamic> json) {
    return ScraperProgress(
      total: json['total'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      success: json['success'] as int? ?? 0,
      error: json['error'] as int? ?? 0,
      system: json['system'] as String? ?? "",
      rom: json['rom'] as String? ?? "",
      message: json['msg'] as String? ?? json['message'] as String? ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'pending': pending,
      'success': success,
      'error': error,
      'system': system,
      'rom': rom,
      'msg': message,
    };
  }
}

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
