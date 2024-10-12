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
    final focus = useFocusNode();
    final checked = useState(selected);
    final callback = useCallback(() {
      checked.value = !checked.value;
      onPressed?.call();
      onChanged?.call(checked.value);
    });
    return (isToggle ? checked.value : selected)
        ? FilledButton.tonal(
            focusNode: focusNode ?? focus,
            onPressed: callback,
            style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12)),
            child: child,
          )
        : OutlinedButton(
            focusNode: focusNode ?? focus,
            onPressed: callback,
            style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12)),
            child: child,
          );
  }
}
