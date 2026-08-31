import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:titanius/gamepad.dart';
import 'package:titanius/widgets/prompt_bar.dart';

/// Fullscreen prompt dialog that accommodates any font scale (including 2x+)
/// and virtual keyboards taking 50%+ height on handhelds (e.g. RG406V).
Future<String?> prompt(
  BuildContext context, {
  Widget? title,
  Widget? hint,
  String? initialValue,
  bool isSelectedInitialValue = false,
  Widget? textOK,
  Widget? textCancel,
  bool barrierDismissible = false,
  InputDecoration? decoration,
  String? Function(String?)? validator,
  bool obscureText = false,
  TextEditingController? controller,
  int minLines = 1,
  int maxLines = 1,
  bool autoFocus = true,
  TextInputType? keyboardType,
  TextCapitalization textCapitalization = TextCapitalization.none,
}) {
  return showDialog<String>(
    context: context,
    useSafeArea: false,
    barrierDismissible: barrierDismissible,
    builder: (BuildContext dialogContext) {
      return Dialog.fullscreen(
        child: _FullscreenPromptContent(
          title: title,
          initialValue: initialValue,
          isSelectedInitialValue: isSelectedInitialValue,
          textOK: textOK,
          textCancel: textCancel,
          decoration: decoration,
          validator: validator,
          obscureText: obscureText,
          externalController: controller,
          minLines: minLines,
          maxLines: maxLines,
          autoFocus: autoFocus,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
        ),
      );
    },
  );
}

class _FullscreenPromptContent extends HookConsumerWidget {
  final Widget? title;
  final String? initialValue;
  final bool isSelectedInitialValue;
  final Widget? textOK;
  final Widget? textCancel;
  final InputDecoration? decoration;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextEditingController? externalController;
  final int minLines;
  final int maxLines;
  final bool autoFocus;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  const _FullscreenPromptContent({
    this.title,
    this.initialValue,
    this.isSelectedInitialValue = false,
    this.textOK,
    this.textCancel,
    this.decoration,
    this.validator,
    this.obscureText = false,
    this.externalController,
    this.minLines = 1,
    this.maxLines = 1,
    this.autoFocus = true,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final internalController = useTextEditingController(
      text: initialValue ?? '',
    );
    final controller = externalController ?? internalController;
    final focusNode = useFocusNode();

    useEffect(() {
      if (isSelectedInitialValue && controller.text.isNotEmpty) {
        controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: controller.text.length,
        );
      }
      return null;
    }, const []);

    void submit() {
      if (formKey.currentState?.validate() ?? true) {
        Navigator.of(context).pop(controller.text);
      }
    }

    useGamepad(ref, (location, key) {
      if (key == GamepadButton.back) {
        Navigator.of(context).pop(null);
      }
    });

    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    final effectiveDecoration = (decoration ?? const InputDecoration())
        .copyWith(
          border: decoration?.border ?? const OutlineInputBorder(),
          filled: decoration?.filled ?? true,
          fillColor:
              decoration?.fillColor ?? Colors.white.withValues(alpha: 0.07),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () {
                    controller.clear();
                  },
                )
              : null,
        );

    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.35,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          toolbarHeight: 48,
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancel',
            onPressed: () => Navigator.of(context).pop(null),
          ),
          title: title != null
              ? FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: title,
                )
              : const Text('Input'),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextButton.icon(
                icon: const Icon(Icons.check, size: 18),
                label:
                    textOK ??
                    const Text(
                      'Save',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                onPressed: submit,
              ),
            ),
          ],
        ),
        bottomNavigationBar: isKeyboardOpen
            ? null
            : const PromptBar(
                navigations: [],
                actions: [
                  GamepadPrompt([GamepadButton.confirm], 'Save'),
                  GamepadPrompt([GamepadButton.back], 'Cancel'),
                ],
              ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: autoFocus,
                    obscureText: obscureText,
                    keyboardType: keyboardType,
                    textCapitalization: textCapitalization,
                    minLines: minLines,
                    maxLines: maxLines,
                    cursorWidth: 3.0,
                    cursorColor: Colors.amberAccent,
                    cursorRadius: const Radius.circular(2),
                    textInputAction: TextInputAction.done,
                    scrollPadding: const EdgeInsets.all(24),
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                    decoration: effectiveDecoration,
                    validator: validator,
                    onFieldSubmitted: (_) => submit(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
