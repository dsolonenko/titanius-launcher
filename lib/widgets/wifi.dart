import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Connectivity connectivity = Connectivity();
final connectivityProvider = StreamProvider.autoDispose<ConnectivityResult>((ref) {
  return connectivity.onConnectivityChanged;
});

class WifiWidget extends ConsumerWidget {
  const WifiWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityResult = ref.watch(connectivityProvider);
    return connectivityResult.when(
      data: (result) {
        if (result == ConnectivityResult.wifi) {
          return const Icon(Icons.wifi);
        } else {
          return const Icon(Icons.wifi_off);
        }
      },
      loading: () => const Icon(Icons.wifi_off),
      error: (e, s) => const Icon(Icons.wifi_off),
    );
  }
}
