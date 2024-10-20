import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'nnyy_focus.dart';

class SpinNotification extends Notification {
  final int index;
  final bool isActive;
  const SpinNotification(this.index, this.isActive);
}

class NnyyDurationBox extends HookWidget {
  const NnyyDurationBox({
    super.key,
    this.value = Duration.zero,
    this.label = '',
    required this.onChanged,
  });

  final Duration value;
  final String label;
  final void Function(Duration value)? onChanged;

  Duration set(Duration dur, {int? min, int? sec}) {
    min ??= dur.inSeconds ~/ 60;
    sec ??= dur.inSeconds % 60;
    return Duration(minutes: min, seconds: sec);
  }

  @override
  Widget build(BuildContext context) {
    final dur = useState(value);
    final focus = useFocusNode();
    final keys = useMemoized(() => [UniqueKey(), UniqueKey()]);
    final active = useState(false);
    final actives = useState([false, false]);
    final min = dur.value.inSeconds ~/ 60;
    final sec = dur.value.inSeconds % 60;
    final colorScheme = Theme.of(context).colorScheme;
    final color = (active.value && actives.value.every((e) => !e)) ||
            focus.hasPrimaryFocus
        ? colorScheme.primary
        : colorScheme.onSurface;
    useListenable(focus);
    return NotificationListener(
      onNotification: (SpinNotification n) {
        var a = [...actives.value];
        a[n.index] = n.isActive;
        actives.value = a;
        return true;
      },
      child: NnyyFocusGroup(
        child: FocusTraversalOrder(
          order: const NumericFocusOrder(0),
          child: TextButton(
            focusNode: focus,
            onHover: (v) => active.value = v,
            onPressed: () {
              dur.value = Duration.zero;
              keys.replaceRange(0, 2, [UniqueKey(), UniqueKey()]);
              onChanged?.call(dur.value);
            },
            style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12))
                .copyWith(
              overlayColor: WidgetStateProperty.resolveWith((set) =>
                  set.contains(WidgetState.focused) &&
                          !set.contains(WidgetState.selected) &&
                          !set.contains(WidgetState.hovered)
                      ? colorScheme.onSecondaryFixedVariant
                      : null),
            ),
            child: DefaultTextStyle(
              style: DefaultTextStyle.of(context).style.copyWith(color: color),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label),
                  const SizedBox(width: 4),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(1),
                    child: _SpinValue(
                      index: 0,
                      value: min,
                      onChanged: (v) {
                        dur.value = set(dur.value, min: v);
                        onChanged?.call(dur.value);
                      },
                    ),
                  ),
                  const Text(':'),
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(2),
                    child: _SpinValue(
                      index: 1,
                      value: sec,
                      onChanged: (v) {
                        dur.value = set(dur.value, sec: v);
                        onChanged?.call(dur.value);
                      },
                    ),
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

class _SpinValue extends HookWidget {
  const _SpinValue({
    this.value = 0,
    required this.index,
    this.onChanged,
  });

  final int value;
  final int index;
  final void Function(int value)? onChanged;

  @override
  Widget build(BuildContext context) {
    final spin = useState(value);
    final active = useState(false);
    final onActive = useCallback((bool v) {
      SpinNotification(index, v).dispatch(context);
      return active.value = v;
    });
    final onSpin = useCallback((int v) {
      spin.value += v;
      spin.value += 60;
      spin.value = spin.value.remainder(60);
      onChanged?.call(spin.value);
      return true;
    });
    useValueChanged(value, (_, void __) => spin.value = value);
    final text = spin.value < 10 ? "0${spin.value}" : "${spin.value}";
    final colorScheme = Theme.of(context).colorScheme;
    final color = active.value ? colorScheme.primary : colorScheme.onSurface;
    final style = DefaultTextStyle.of(context).style.copyWith(color: color);
    return GestureDetector(
      onVerticalDragUpdate: (d) => onSpin(-(d.primaryDelta?.round() ?? 0)),
      child: NnyyFocusKeyBuilder(
        keyMap: {
          LogicalKeyboardKey.arrowUp: () => onSpin(1),
          LogicalKeyboardKey.arrowDown: () => onSpin(-1),
        },
        builder: (_, focus) {
          return InkWell(
            focusNode: focus,
            onTap: () => onSpin(1),
            onHover: onActive,
            onFocusChange: onActive,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(text, style: style),
            ),
          );
        },
      ),
    );
  }
}
