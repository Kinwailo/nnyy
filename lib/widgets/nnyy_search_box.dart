import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import 'nnyy_focus.dart';

class NnyySearchBox extends HookWidget {
  const NnyySearchBox({
    super.key,
    this.text = '',
    this.width,
    this.height,
    this.onSearch,
    this.onClear,
  });

  final String text;
  final double? width;
  final double? height;
  final void Function(String value)? onSearch;
  final void Function()? onClear;

  @override
  Widget build(BuildContext context) {
    final style = IconButton.styleFrom(visualDensity: VisualDensity.compact);
    final search = useSearchController();
    useEffect(() {
      search.text = text;
      return null;
    }, []);
    final empty = useListenableSelector(search, () => search.text.isEmpty);
    final cursorAt = useCallback((int i) =>
        search.selection.baseOffset == i && search.selection.extentOffset == i);
    return NnyyFocusGroup(
      child: SizedBox(
        width: width,
        height: height,
        child: NnyyFocusKeyBuilder(
            keyMap: {
              LogicalKeyboardKey.arrowLeft: () {
                if (!cursorAt(0)) return false;
                Actions.invoke(context, const PreviousFocusIntent());
                return true;
              },
              LogicalKeyboardKey.arrowRight: () {
                if (!cursorAt(search.text.length)) return false;
                Actions.invoke(context, const NextFocusIntent());
                return true;
              },
            },
            builder: (_, focus) {
              return SearchBar(
                focusNode: focus,
                controller: search,
                onSubmitted: (v) {
                  if (!empty) onSearch?.call(v);
                },
                leading: IconButton(
                    onPressed: () {
                      if (!empty) onSearch?.call(search.text);
                    },
                    iconSize: 16,
                    splashRadius: 12,
                    style: style,
                    icon: const Icon(Icons.search)),
                trailing: [
                  IconButton(
                    onPressed: () {
                      search.clear();
                      if (!empty) onClear?.call();
                    },
                    iconSize: 16,
                    splashRadius: 12,
                    style: style,
                    icon: const Icon(Icons.clear),
                  )
                ],
              );
            }),
      ),
    );
  }
}
