import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class NnyySelectButton<T> extends HookWidget {
  const NnyySelectButton({
    super.key,
    required this.segments,
    required this.selected,
    this.onChanged,
    this.getText,
  });

  final List<T> segments;
  final T selected;
  final void Function(T)? onChanged;
  final String Function(T)? getText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final set = useState({selected});
    final list = useMemoized(
        () => List.generate(
            segments.length, (_) => FocusNode(canRequestFocus: false)),
        [segments.length]);
    final index = max(0, segments.indexOf(selected));
    if (list[index].context != null) {
      Scrollable.ensureVisible(
        list[index].context!,
        alignment: 0.9,
        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        duration: Durations.short4,
        curve: Curves.ease,
      );
    }
    useValueChanged(selected, (_, void __) => set.value = {selected});
    return SegmentedButton(
      segments: segments
          .mapIndexed((i, e) => ButtonSegment(
              value: e,
              label: Focus(
                  focusNode: list[i],
                  child: Text(getText == null ? e.toString() : getText!(e)))))
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
