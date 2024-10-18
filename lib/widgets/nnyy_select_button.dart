import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class NnyySelectButton<T> extends HookWidget {
  const NnyySelectButton({
    super.key,
    required this.segments,
    required this.selected,
    this.onChanged,
  });

  final List<T> segments;
  final T selected;
  final void Function(T)? onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final set = useState({selected});
    useValueChanged(selected, (_, void __) => set.value = {selected});
    return SegmentedButton(
      segments: segments
          .map((e) => ButtonSegment(value: e, label: Text(e.toString())))
          .toList(),
      showSelectedIcon: false,
      selected: set.value,
      onSelectionChanged: (v) {
        set.value = {v.first};
        onChanged?.call(v.first);
      },
      style: SegmentedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8))),
      ).copyWith(
        backgroundColor: WidgetStateProperty.resolveWith((set) =>
            set.contains(WidgetState.selected)
                ? colorScheme.tertiaryContainer
                : null),
        foregroundColor: WidgetStateProperty.resolveWith((set) =>
            set.contains(WidgetState.focused) ? colorScheme.primary : null),
        overlayColor: WidgetStateProperty.resolveWith((set) =>
            set.contains(WidgetState.focused) &&
                    !set.contains(WidgetState.selected) &&
                    !set.contains(WidgetState.hovered)
                ? colorScheme.onSecondaryFixedVariant
                : null),
      ),
    );
  }
}
