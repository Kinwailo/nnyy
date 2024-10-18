import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class NnyyToggle extends HookWidget {
  const NnyyToggle({
    super.key,
    this.value = false,
    required this.icon,
    this.activeIcon,
    this.color,
    this.activeColor,
    required this.onChanged,
  });

  final bool value;
  final IconData icon;
  final IconData? activeIcon;
  final Color? color;
  final Color? activeColor;
  final void Function(bool value)? onChanged;

  @override
  Widget build(BuildContext context) {
    final checked = useState(value);
    final callback = useCallback(() {
      checked.value = !checked.value;
      onChanged?.call(checked.value);
    });
    useValueChanged(value, (_, void __) => checked.value = value);
    return IconButton(
      onPressed: callback,
      color: checked.value ? activeColor ?? color : color,
      icon: Icon(checked.value ? activeIcon ?? icon : icon),
    );
  }
}
