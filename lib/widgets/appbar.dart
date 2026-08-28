import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:titanius/widgets/battery.dart';
import 'package:titanius/widgets/scraper_progress.dart';
import 'package:titanius/widgets/time.dart';
import 'package:titanius/widgets/wifi.dart';

final batteryProvider = StreamProvider<BatteryInfo>((ref) {
  final battery = Battery();
  return battery.onBatteryStateChanged.asyncMap((event) async => BatteryInfo(event, await battery.batteryLevel));
});

class BatteryInfo {
  final BatteryState state;
  final int level;

  BatteryInfo(this.state, this.level);
}

class CustomAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(36);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scale = MediaQuery.textScalerOf(context).scale(1.0);
    final barHeight = (30.0 * scale).clamp(30.0, 60.0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: barHeight,
      color: Colors.black.withValues(alpha: 0.5),
      alignment: Alignment.centerRight,
      child: const Row(mainAxisSize: MainAxisSize.max, children: [
        TimeWidget(),
        Spacer(),
        ScraperProgressWidget(),
        SizedBox(width: 6),
        WifiWidget(),
        SizedBox(width: 6),
        BatteryWidget(),
      ]),
    );
  }
}
