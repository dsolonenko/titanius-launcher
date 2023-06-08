import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:titanius/widgets/battery.dart';
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
  Size get preferredSize => const Size.fromHeight(30);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      height: preferredSize.height,
      color: Theme.of(context).appBarTheme.backgroundColor?.withOpacity(0),
      alignment: Alignment.centerRight,
      child: const Row(mainAxisSize: MainAxisSize.max, children: [
        TimeWidget(),
        Spacer(),
        WifiWidget(),
        BatteryWidget(),
      ]),
    );
  }
}
