import 'package:flutter/material.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final batteryProvider = StreamProvider.autoDispose<BatteryInfo>((ref) {
  final battery = Battery();
  return battery.onBatteryStateChanged.asyncMap(
      (event) async => BatteryInfo(event, await battery.batteryLevel));
});

class BatteryInfo {
  final BatteryState state;
  final int level;

  BatteryInfo(this.state, this.level);
}

class BatteryWidget extends ConsumerWidget {
  const BatteryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final battery = ref.watch(batteryProvider);
    return battery.when(
      data: (b) => Row(mainAxisSize: MainAxisSize.max, children: [
        _imageForBattery(b),
        Text("${b.level}%"),
      ]),
      loading: () => const Text("Loading..."),
      error: (error, stack) => const Text("Error"),
    );
  }

  Icon _imageForBattery(BatteryInfo b) {
    const iconColor = Colors.white;
    const iconSize = 24.0;
    if (b.state == BatteryState.unknown) {
      return const Icon(
        Icons.battery_unknown_sharp,
        color: iconColor,
        size: iconSize,
      );
    } else if (b.state == BatteryState.charging) {
      return const Icon(
        Icons.battery_charging_full_sharp,
        color: iconColor,
        size: iconSize,
      );
    } else if (b.level > 75) {
      return const Icon(
        Icons.battery_5_bar_sharp,
        color: iconColor,
        size: iconSize,
      );
    } else if (b.level > 50) {
      return const Icon(
        Icons.battery_4_bar_sharp,
        color: iconColor,
        size: iconSize,
      );
    } else if (b.level > 25) {
      return const Icon(
        Icons.battery_3_bar_sharp,
        color: iconColor,
        size: iconSize,
      );
    } else if (b.level > 10) {
      return const Icon(
        Icons.battery_2_bar_sharp,
        color: iconColor,
        size: iconSize,
      );
    } else {
      return const Icon(
        Icons.battery_1_bar_sharp,
        color: iconColor,
        size: iconSize,
      );
    }
  }
}
