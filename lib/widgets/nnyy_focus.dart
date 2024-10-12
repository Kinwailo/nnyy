import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class NnyyFocusGroupAction extends Action<DirectionalFocusIntent> {
  @override
  bool invoke(DirectionalFocusIntent intent) {
    return switch (intent.direction) {
      TraversalDirection.up ||
      TraversalDirection.down =>
        primaryFocus!.focusInDirection(intent.direction),
      TraversalDirection.left => primaryFocus!.previousFocus(),
      TraversalDirection.right => primaryFocus!.nextFocus(),
    };
  }
}

class NnyyFocusGroup extends HookWidget {
  const NnyyFocusGroup({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Actions(
      actions: {DirectionalFocusIntent: NnyyFocusGroupAction()},
      child: FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(
          requestFocusCallback: (node,
              {alignment, alignmentPolicy, curve, duration}) {
            node.requestFocus();
            Scrollable.ensureVisible(
              node.context!,
              alignment: 0.9,
              alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
              duration: Durations.short4,
              curve: Curves.ease,
            );
          },
        ),
        child: child,
      ),
    );
  }
}

typedef FocusWidgetBuilder = Widget Function(
    BuildContext context, FocusNode focus);
typedef FocusKeyCallback = bool Function(LogicalKeyboardKey key);

class NnyyFocusKeyBuilder extends HookWidget {
  const NnyyFocusKeyBuilder({
    super.key,
    this.onKey,
    this.keyMap,
    required this.builder,
  });

  final FocusWidgetBuilder builder;
  final FocusKeyCallback? onKey;
  final Map<LogicalKeyboardKey, ValueGetter<bool>>? keyMap;

  @override
  Widget build(BuildContext context) {
    final focus = useFocusNode(
      onKeyEvent: (_, e) {
        if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }
        if (keyMap != null && keyMap!.containsKey(e.logicalKey)) {
          return keyMap![e.logicalKey]!()
              ? KeyEventResult.handled
              : KeyEventResult.ignored;
        }
        return onKey != null && onKey!(e.logicalKey)
            ? KeyEventResult.handled
            : KeyEventResult.ignored;
      },
    );
    return builder(context, focus);
  }
}
