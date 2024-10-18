import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class NnyyButton extends HookWidget {
  const NnyyButton({
    super.key,
    this.selected = false,
    this.focusNode,
    this.onPressed,
    this.onChanged,
    this.child,
  }) : isToggle = false;
  const NnyyButton.toggle({
    super.key,
    this.selected = false,
    this.focusNode,
    this.onPressed,
    this.onChanged,
    this.child,
  }) : isToggle = true;

  final bool isToggle;
  final bool selected;
  final FocusNode? focusNode;
  final Widget? child;
  final void Function()? onPressed;
  final void Function(bool)? onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final focus = focusNode ?? useFocusNode();
    final checked = useState(selected);
    final state = useMemoized(
        () => WidgetStatesController(selected ? {WidgetState.selected} : {}));
    final callback = useCallback(() {
      checked.value = !checked.value;
      onPressed?.call();
      onChanged?.call(checked.value);
    });
    useValueChanged(selected, (_, void __) => checked.value = selected);
    useValueChanged(
      checked.value,
      (_, void __) => state.value = {
        ...state.value..remove(WidgetState.selected),
        if (checked.value) WidgetState.selected
      },
    );
    return OutlinedButton(
      focusNode: focus,
      statesController: state,
      onPressed: callback,
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((set) =>
            set.contains(WidgetState.selected)
                ? colorScheme.tertiaryContainer
                : null),
        foregroundColor: WidgetStateProperty.resolveWith(
            (set) => set.contains(WidgetState.focused)
                ? colorScheme.primary
                : set.contains(WidgetState.selected)
                    ? colorScheme.onTertiaryContainer
                    : colorScheme.onSurface),
        overlayColor: WidgetStateProperty.resolveWith((set) =>
            set.contains(WidgetState.focused) &&
                    !set.contains(WidgetState.selected) &&
                    !set.contains(WidgetState.hovered)
                ? colorScheme.onSecondaryFixedVariant
                : null),
      ),
      child: child,
    );
  }
}
