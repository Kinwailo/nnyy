import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class NnyyCheckbox extends HookWidget {
  const NnyyCheckbox({
    super.key,
    this.value = false,
    this.label = '',
    required this.onChanged,
  });

  final bool value;
  final String label;
  final void Function(bool value)? onChanged;

  @override
  Widget build(BuildContext context) {
    final checked = useState(value);
    final state = useMemoized(
        () => WidgetStatesController(value ? {WidgetState.selected} : {}));
    final callback = useCallback(() {
      checked.value = !checked.value;
      onChanged?.call(checked.value);
    });
    useValueChanged(value, (_, void __) => checked.value = value);
    useValueChanged(
      checked.value,
      (_, void __) => state.value = {
        ...state.value..remove(WidgetState.selected),
        if (checked.value) WidgetState.selected
      },
    );
    final colorScheme = Theme.of(context).colorScheme;
    final color =
        checked.value ? colorScheme.onTertiaryContainer : colorScheme.onSurface;
    final style = DefaultTextStyle.of(context).style.copyWith(color: color);
    final icon =
        checked.value ? Icons.check_box : Icons.check_box_outline_blank;
    return TextButton.icon(
      statesController: state,
      onPressed: callback,
      label: Text(label, style: style),
      icon: Icon(icon, color: color),
      style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12))
          .copyWith(
        overlayColor: WidgetStateProperty.resolveWith((set) =>
            set.contains(WidgetState.focused) &&
                    !set.contains(WidgetState.hovered)
                ? colorScheme.onSecondaryFixedVariant
                : null),
      ),
    );
  }
}
