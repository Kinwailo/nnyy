import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

extension SingleActivatorToMap on SingleActivator {
  Map<String, dynamic> get toMap {
    return {
      'key': trigger.keyId,
      'control': control,
      'shift': shift,
      'alt': alt,
      'repeat': includeRepeats,
    };
  }
}

extension MapToSingleActivator on Map<String, dynamic> {
  SingleActivator get toSingleActivator {
    var key = LogicalKeyboardKey.findKeyByKeyId(this['key']) ??
        LogicalKeyboardKey.space;
    var control = this['control'];
    var shift = this['shift'];
    var alt = this['alt'];
    var repeat = this['repeat'];
    return SingleActivator(key,
        control: control, shift: shift, alt: alt, includeRepeats: repeat);
  }
}

class ShortcutChip extends HookWidget {
  const ShortcutChip(
    this.title,
    this.value, {
    super.key,
    this.onChanged,
  });

  final String title;
  final SingleActivator value;
  final Function(SingleActivator)? onChanged;

  @override
  Widget build(BuildContext context) {
    final shortcut = useState(value);
    final keyLabel = shortcut.value.trigger.keyLabel;
    var keys = [
      if (shortcut.value.control) 'Control',
      if (shortcut.value.shift) 'Shift',
      if (shortcut.value.alt) 'Alt',
      keyLabel == ' ' ? 'Space' : keyLabel,
    ];
    useValueChanged(value, (_, void __) => shortcut.value = value);
    return ActionChip(
      label: Text('$title : ${keys.join(' + ')}'),
      padding: const EdgeInsets.all(0),
      onPressed: () async {
        var result =
            await (ShortcutDialog(context).show(title, shortcut.value));
        if (result != null) {
          shortcut.value = result;
          onChanged?.call(result);
        }
      },
    );
  }
}

class ShortcutTile extends HookWidget {
  const ShortcutTile(
    this.title,
    this.value, {
    super.key,
    this.onChanged,
  });

  final String title;
  final SingleActivator value;
  final Function(SingleActivator)? onChanged;

  @override
  Widget build(BuildContext context) {
    final shortcut = useState(value);
    final keyLabel = shortcut.value.trigger.keyLabel;
    var keys = [
      if (shortcut.value.control) 'Control',
      if (shortcut.value.shift) 'Shift',
      if (shortcut.value.alt) 'Alt',
      keyLabel == ' ' ? 'Space' : keyLabel,
    ];
    useValueChanged(value, (_, void __) => shortcut.value = value);
    return ListTile(
      title: Text(title),
      subtitle: Text(keys.join(' + ')),
      onTap: () async {
        var result =
            await (ShortcutDialog(context).show(title, shortcut.value));
        if (result != null) {
          shortcut.value = result;
          onChanged?.call(result);
        }
      },
    );
  }
}

class ShortcutDialog {
  ShortcutDialog(this.context);

  final BuildContext context;

  Future<SingleActivator?> show(String title, SingleActivator shortcut,
      {double? width, bool dismissible = true}) async {
    var theme = Theme.of(context);
    return showDialog<SingleActivator>(
      barrierDismissible: dismissible,
      context: context,
      builder: (context) => PopScope(
        canPop: dismissible,
        child: Dialog(
          child: SizedBox(
            width: width ?? 300,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  ShortcutSetting(shortcut),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ShortcutSetting extends HookWidget {
  const ShortcutSetting(
    this.shortcut, {
    super.key,
  });

  final SingleActivator shortcut;

  @override
  Widget build(BuildContext context) {
    final control = useState(shortcut.control);
    final shift = useState(shortcut.shift);
    final alt = useState(shortcut.alt);
    final focusNode = useMemoized(() => FocusNode());
    focusNode.requestFocus();
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        ChoiceChip(
          label: const Text('Control'),
          padding: const EdgeInsets.all(0),
          showCheckmark: false,
          selected: control.value,
          onSelected: (v) => control.value = v,
        ),
        ChoiceChip(
          label: const Text('Shift'),
          padding: const EdgeInsets.all(0),
          showCheckmark: false,
          selected: shift.value,
          onSelected: (v) => shift.value = v,
        ),
        ChoiceChip(
          label: const Text('Alt'),
          padding: const EdgeInsets.all(0),
          showCheckmark: false,
          selected: alt.value,
          onSelected: (v) => alt.value = v,
        ),
        Focus(
          focusNode: focusNode,
          onKeyEvent: (_, e) {
            var s = SingleActivator(e.logicalKey,
                control: control.value,
                shift: shift.value,
                alt: alt.value,
                includeRepeats: shortcut.includeRepeats);
            Navigator.pop<SingleActivator>(context, s);
            return KeyEventResult.handled;
          },
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Text('Press a key'),
          ),
        ),
      ],
    );
  }
}
