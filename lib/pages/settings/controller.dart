part of 'package:titanius/pages/settings.dart';

class ControllerSettingsPage extends HookConsumerWidget {
  const ControllerSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final selectedIndex = usePersistentSelection('/settings/controller');

    final s = settings.value;

    void cycleControllerLayout(int direction) {
      final current = ref.read(settingsProvider).value;
      if (current == null) return;
      final values = ControllerLayout.values;
      final currentIndex = values.indexOf(current.controllerLayout);
      final newIndex = (currentIndex + direction + values.length) % values.length;
      final newLayout = values[newIndex];
      final repo = ref.read(settingsRepoProvider);
      repo
          .setControllerLayout(newLayout)
          .then((value) => ref.invalidate(settingsProvider));
    }

    String getLayoutSubtitle(ControllerLayout layout) {
      switch (layout) {
        case ControllerLayout.nintendo:
          return "Nintendo style: B / A / Y / X";
        case ControllerLayout.generic:
          return "Positional / directional button indicators";
        case ControllerLayout.xbox:
          return "Xbox style: A / B / X / Y";
      }
    }

    String getSwapConfirmSubtitle(Settings settings) {
      final layout = settings.controllerLayout;
      final swap = settings.swapConfirm;
      if (layout == ControllerLayout.nintendo) {
        return swap
            ? "A (East) confirms, B (South) cancels"
            : "B (South) confirms, A (East) cancels";
      } else if (layout == ControllerLayout.generic) {
        return swap
            ? "East button confirms, South button cancels"
            : "South button confirms, East button cancels";
      } else {
        return swap
            ? "B (East) confirms, A (South) cancels"
            : "A (South) confirms, B (East) cancels";
      }
    }

    final items = s == null
        ? <_UiSettingItem>[]
        : [
            _UiSettingItem(
              title: 'Controller Layout',
              subtitle: getLayoutSubtitle(s.controllerLayout),
              trailing: SelectorWidget(text: s.controllerLayout.label),
              enabled: true,
              onAction: (repo) async => cycleControllerLayout(1),
              onLeft: (repo) async => cycleControllerLayout(-1),
              onRight: (repo) async => cycleControllerLayout(1),
            ),
            _UiSettingItem(
              title: 'Swap A/B for Confirm',
              subtitle: getSwapConfirmSubtitle(s),
              trailing: s.swapConfirm ? toggleOnIcon : toggleOffIcon,
              enabled: true,
              onAction: (repo) => repo.setSwapConfirm(!s.swapConfirm),
            ),
          ];

    useGamepad(ref, (location, key) {
      if (location != "/settings/controller") return;
      if (items.isEmpty) return;

      if (key == GamepadButton.up) {
        selectedIndex.value = (selectedIndex.value - 1).clamp(
          0,
          items.length - 1,
        );
      }
      if (key == GamepadButton.down) {
        selectedIndex.value = (selectedIndex.value + 1).clamp(
          0,
          items.length - 1,
        );
      }
      if (key == GamepadButton.left) {
        final item = items[selectedIndex.value.clamp(0, items.length - 1)];
        if (item.enabled && item.onLeft != null) {
          final repo = ref.read(settingsRepoProvider);
          item.onLeft!(repo).then((value) => ref.invalidate(settingsProvider));
        }
      }
      if (key == GamepadButton.right) {
        final item = items[selectedIndex.value.clamp(0, items.length - 1)];
        if (item.enabled && item.onRight != null) {
          final repo = ref.read(settingsRepoProvider);
          item.onRight!(repo).then((value) => ref.invalidate(settingsProvider));
        }
      }
      if (key == GamepadButton.a) {
        final item = items[selectedIndex.value.clamp(0, items.length - 1)];
        if (item.enabled && item.onAction != null) {
          final repo = ref.read(settingsRepoProvider);
          item.onAction!(repo).then(
            (value) => ref.invalidate(settingsProvider),
          );
        }
      }
      if (key == GamepadButton.b) {
        GoRouter.of(context).pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Controller Settings')),
      bottomNavigationBar: const PromptBar(
        navigations: [
          GamepadPrompt([GamepadButton.leftRight], "Select"),
        ],
        actions: [
          GamepadPrompt([GamepadButton.a], "Change"),
          GamepadPrompt([GamepadButton.b], "Back"),
        ],
      ),
      body: settings.when(
        skipLoadingOnRefresh: true,
        skipLoadingOnReload: true,
        data: (_) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int index = 0; index < items.length; index++) ...[
                Builder(
                  builder: (context) {
                    final item = items[index];
                    final isSelected = index == selectedIndex.value;
                    return SelectedScrollTile(
                      isSelected: isSelected,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        child: Material(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          child: ListTile(
                            enabled: item.enabled,
                            selected: isSelected,
                            selectedColor: Colors.black,
                            selectedTileColor: Colors.transparent,
                            dense: true,
                            onTap: () {
                              selectedIndex.value = index;
                              if (item.enabled && item.onAction != null) {
                                final repo = ref.read(settingsRepoProvider);
                                item.onAction!(repo).then(
                                  (value) => ref.invalidate(settingsProvider),
                                );
                              }
                            },
                            title: Text(
                              item.title,
                              style: TextStyle(
                                color: !item.enabled
                                    ? Colors.grey
                                    : isSelected
                                    ? Colors.black
                                    : Colors.white,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: item.subtitle != null
                                ? Text(
                                    item.subtitle!,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.black87
                                          : Colors.grey,
                                    ),
                                  )
                                : null,
                            trailing: item.trailing,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 6),
              const Divider(height: 1, color: Colors.white12),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 16.0,
                      ),
                      child: _ControllerDiagram(
                        layout: s?.controllerLayout ?? ControllerLayout.nintendo,
                        swapConfirm: s?.swapConfirm ?? false,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const Center(child: Text('Error')),
      ),
    );
  }
}

class _ControllerDiagram extends StatelessWidget {
  final ControllerLayout layout;
  final bool swapConfirm;

  const _ControllerDiagram({
    required this.layout,
    required this.swapConfirm,
  });

  Widget _buildFaceButton(String? glyph, {bool isFilled = false}) {
    if (glyph != null) {
      return Text(
        glyph,
        style: const TextStyle(
          fontFamily: "Prompt",
          fontSize: 28,
          height: 1.0,
          leadingDistribution: TextLeadingDistribution.even,
        ),
      );
    }
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isFilled ? Colors.white : Colors.transparent,
        border: Border.all(
          color: isFilled ? Colors.white : Colors.white60,
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? northGlyph;
    final String? westGlyph;
    final String? eastGlyph;
    final String? southGlyph;

    final String confirmGlyph;
    final String backGlyph;

    switch (layout) {
      case ControllerLayout.nintendo:
        northGlyph = "\u{21D0}"; // X
        westGlyph = "\u{21D1}"; // Y
        eastGlyph = "\u{21D3}"; // A
        southGlyph = "\u{21D2}"; // B
        confirmGlyph = swapConfirm ? "\u{21D3}" : "\u{21D2}";
        backGlyph = swapConfirm ? "\u{21D2}" : "\u{21D3}";
        break;
      case ControllerLayout.xbox:
        northGlyph = "\u{21D1}"; // Y
        westGlyph = "\u{21D0}"; // X
        eastGlyph = "\u{21D2}"; // B
        southGlyph = "\u{21D3}"; // A
        confirmGlyph = swapConfirm ? "\u{21D2}" : "\u{21D3}";
        backGlyph = swapConfirm ? "\u{21D3}" : "\u{21D2}";
        break;
      case ControllerLayout.generic:
        northGlyph = null;
        westGlyph = null;
        eastGlyph = null;
        southGlyph = null;
        confirmGlyph = swapConfirm ? "\u{21A6}" : "\u{21A7}";
        backGlyph = swapConfirm ? "\u{21A7}" : "\u{21A6}";
        break;
    }

    const double plateSize = 110;
    const double offset = 34;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: plateSize,
          height: plateSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: Colors.white24, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: offset * 2,
                height: 1.5,
                color: Colors.white10,
              ),
              Container(
                width: 1.5,
                height: offset * 2,
                color: Colors.white10,
              ),
              Transform.translate(
                offset: const Offset(0, -offset),
                child: _buildFaceButton(northGlyph),
              ),
              Transform.translate(
                offset: const Offset(0, offset),
                child: _buildFaceButton(
                  southGlyph,
                  isFilled: !swapConfirm,
                ),
              ),
              Transform.translate(
                offset: const Offset(-offset, 0),
                child: _buildFaceButton(westGlyph),
              ),
              Transform.translate(
                offset: const Offset(offset, 0),
                child: _buildFaceButton(
                  eastGlyph,
                  isFilled: swapConfirm,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ActionPrompt(
              label: "Confirm",
              glyph: confirmGlyph,
            ),
            const SizedBox(height: 14),
            _ActionPrompt(
              label: "Back",
              glyph: backGlyph,
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionPrompt extends StatelessWidget {
  final String label;
  final String glyph;

  const _ActionPrompt({
    required this.label,
    required this.glyph,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          glyph,
          style: const TextStyle(
            fontFamily: "Prompt",
            fontSize: 22,
            height: 1.0,
            leadingDistribution: TextLeadingDistribution.even,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            height: 1.0,
            leadingDistribution: TextLeadingDistribution.even,
          ),
        ),
      ],
    );
  }
}
