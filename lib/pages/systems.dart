import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:titanius/gamepad.dart';
import 'package:page_view_dot_indicator/page_view_dot_indicator.dart';
import 'package:titanius/widgets/prompt_bar.dart';

import '../data/state.dart';
import '../data/systems.dart';
import '../widgets/appbar.dart';

class SystemsPage extends HookConsumerWidget {
  const SystemsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSystems = ref.watch(detectedSystemsProvider);
    final selectedSystem = ref.watch(selectedSystemProvider);
    final pageController = PageController(initialPage: selectedSystem);

    useGamepad(ref, (location, key) {
      if (location != "/") return;
      if (allSystems.value == null || allSystems.value!.isEmpty) return;
      if (key == GamepadButton.r2 || key == GamepadButton.right) {
        final currentSystem = ref.read(selectedSystemProvider);
        final next = (currentSystem + 1) % allSystems.value!.length;
        pageController.animateToPage(next,
            duration: const Duration(milliseconds: 200), curve: Curves.ease);
      }
      if (key == GamepadButton.l2 || key == GamepadButton.left) {
        final currentSystem = ref.read(selectedSystemProvider);
        final prev = currentSystem - 1 < 0
            ? allSystems.value!.length - 1
            : currentSystem - 1;
        pageController.animateToPage(prev,
            duration: const Duration(milliseconds: 200), curve: Curves.ease);
      }
      if (key == GamepadButton.a) {
        final currentSystemIndex = ref.read(selectedSystemProvider);
        final system = allSystems.value![currentSystemIndex];
        if (system.id == "android") {
          GoRouter.of(context).go("/android");
        } else {
          GoRouter.of(context).go("/games/${system.id}");
        }
      }
      if (key == GamepadButton.start) {
        GoRouter.of(context).push("/settings");
      }
    });

    return Scaffold(
      appBar: const CustomAppBar(),
      bottomNavigationBar: const PromptBar(
        navigations: {
          GamepadButton.leftRight: "Choose",
          GamepadButton.start: "Menu",
        },
        actions: {GamepadButton.a: "Select"},
      ),
      body: allSystems.when(
        data: (systems) {
          return Stack(
            children: [
              PageView.builder(
                onPageChanged: (value) {
                  ref.read(selectedSystemProvider.notifier).set(value);
                },
                controller: pageController,
                itemCount: systems.length,
                itemBuilder: (context, index) {
                  if (index >= systems.length) return Container();
                  final system = systems[index];
                  return Row(children: [
                    const Spacer(flex: 1),
                    Expanded(
                      flex: 3,
                      child: GestureDetector(
                        onTap: () =>
                            GoRouter.of(context).go("/games/${system.id}"),
                        child: Image.asset(
                          "assets/images/big/${system.logo}",
                          fit: BoxFit.fitWidth,
                          errorBuilder: (context, url, error) =>
                              const Icon(Icons.error),
                        ),
                      ),
                    ),
                    const Spacer(flex: 1),
                  ]);
                },
              ),
              systems.isNotEmpty
                  ? Container(
                      alignment: Alignment.bottomCenter,
                      child: PageViewDotIndicator(
                        currentItem: selectedSystem < systems.length
                            ? selectedSystem
                            : 0,
                        count: systems.length,
                        unselectedColor: Colors.black26,
                        selectedColor: Colors.orange,
                      ),
                    )
                  : Container(),
            ],
          );
        },
        loading: () => const CircularProgressIndicator(),
        error: (error, stackTrace) => Text(error.toString()),
      ),
    );
  }
}
