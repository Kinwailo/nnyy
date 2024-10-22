import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../services/nnyy_data.dart';
import '../services/save_strategy.dart';
import '../widgets/get_snack_bar.dart';
import '../widgets/nnyy_search_box.dart';
import '../widgets/nnyy_focus.dart';
import '../widgets/nnyy_select_button.dart';
import 'home_controller.dart';
import 'video_card.dart';
import 'more_card.dart';

class HomeView extends HookWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final home = HomeController.i;
    final colorScheme = Theme.of(context).colorScheme;
    final route = ModalRoute.of(context);
    useAutomaticKeepAlive();
    useEffect(() {
      SaveStrategy.i.registerPopEntry(route);
      NnyyData.autoSignInCloud();
      return null;
    }, []);
    useValueChanged(home.error.value, (_, void __) {
      if (home.error.value.isEmpty) return;
      final messager = ScaffoldMessenger.of(context)..clearSnackBars();
      Future(() {
        messager.showSnackBar(getSnackBar(Text(home.error.value)));
        home.clearError();
      });
    });
    useValueChanged(SaveStrategy.i.syncingOnExit.value, (_, void __) {
      final messager = ScaffoldMessenger.of(context)..clearSnackBars();
      if (!SaveStrategy.i.syncingOnExit.value) return;
      final widget = HookBuilder(builder: (context) {
        useListenable(NnyyData.loginExpired);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox.square(
                dimension: 24, child: CircularProgressIndicator()),
            const SizedBox(width: 12),
            if (NnyyData.loginExpired.value)
              const Text('Connection to cloud is expired, please re-login.')
            else
              const Text('Syncing to cloud storage...'),
          ],
        );
      });
      Future(() {
        messager.showSnackBar(getSnackBar(widget));
        home.clearError();
      });
    });
    useListenable(home.canPop);
    useListenable(home.error);
    useListenable(SaveStrategy.i.syncingOnExit);
    return IgnorePointer(
      ignoring: SaveStrategy.i.syncingOnExit.value,
      child: PopScope(
        canPop: home.canPop.value,
        onPopInvoked: (didPop) async {
          if (didPop) {
            NnyyData.saveAll();
            return;
          }
          home.canPop.value = true;
          var focus = home.filterFocus;
          focus.requestFocus(focus.children.firstOrNull);
        },
        child: SafeArea(
          child: Scaffold(
            appBar: AppBar(
              title: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Opacity(
                    opacity: kIsWeb || home.canPop.value ? 1.0 : 0.3,
                    child: const _Filter()),
              ),
              backgroundColor: colorScheme.onPrimaryFixed
                  .withOpacity(kIsWeb || home.canPop.value ? 1.0 : 0.3),
              actions: [
                Opacity(
                  opacity: kIsWeb || home.canPop.value ? 1.0 : 0.3,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: SizedBox.square(
                      dimension: 40,
                      child: NnyyData.cloudAvatar(),
                    ),
                  ),
                ),
              ],
            ),
            body: const _Grid(),
          ),
        ),
      ),
    );
  }
}

class _Filter extends HookWidget {
  const _Filter();

  @override
  Widget build(BuildContext context) {
    final home = HomeController.i;
    useListenable(NnyyData.data);
    return DefaultTextStyle.merge(
      style: Theme.of(context).textTheme.titleMedium,
      child: NnyyFocusGroup(
        child: Focus(
          focusNode: home.filterFocus,
          onFocusChange: (v) {
            if (v) home.canPop.value = true;
          },
          child: Row(
            children: [
              const SizedBox(width: 8),
              FocusTraversalOrder(
                order: const NumericFocusOrder(0),
                child: NnyySelectButton(
                  segments: HomeController.modeList,
                  selected: NnyyData.data.mode,
                  onChanged: (v) => NnyyData.data.mode = v,
                ),
              ),
              const SizedBox(width: 8),
              if (NnyyData.data.mode == HomeController.modeFilter) ...[
                FocusTraversalOrder(
                  order: const NumericFocusOrder(0.5),
                  child: DropdownButton(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    isDense: true,
                    value: NnyyData.data.kind,
                    items: [
                      ...HomeController.kindList.map(
                          (e) => DropdownMenuItem(value: e, child: Text(e)))
                    ],
                    onChanged: (v) {
                      if (v != null) NnyyData.data.kind = v;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(1),
                  child: NnyySelectButton(
                    segments: HomeController.sortList,
                    selected: NnyyData.data.sort,
                    onChanged: (v) => NnyyData.data.sort = v,
                  ),
                ),
                const SizedBox(width: 16),
                const Text('分類'),
                const SizedBox(width: 8),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(2),
                  child: DropdownButton(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    isDense: true,
                    value: NnyyData.data.genre,
                    items: [
                      ...HomeController.genreList.map(
                          (e) => DropdownMenuItem(value: e, child: Text(e)))
                    ],
                    onChanged: (v) {
                      if (v != null) NnyyData.data.genre = v;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text('地區'),
                const SizedBox(width: 8),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(3),
                  child: DropdownButton(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    isDense: true,
                    value: NnyyData.data.country,
                    items: [
                      ...HomeController.countryList.map(
                          (e) => DropdownMenuItem(value: e, child: Text(e)))
                    ],
                    onChanged: (v) {
                      if (v != null) NnyyData.data.country = v;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text('年代'),
                const SizedBox(width: 8),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(4),
                  child: DropdownButton(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    isDense: true,
                    value: NnyyData.data.year,
                    items: [
                      ...HomeController.yearList.map(
                          (e) => DropdownMenuItem(value: e, child: Text(e)))
                    ],
                    onChanged: (v) {
                      if (v != null) NnyyData.data.year = v;
                    },
                  ),
                ),
              ],
              if (NnyyData.data.mode == HomeController.modeSearch) ...[
                const SizedBox(width: 8),
                FocusTraversalOrder(
                  order: const NumericFocusOrder(5),
                  child: NnyySearchBox(
                    text: HomeController.i.search,
                    width: 200,
                    height: 32,
                    onSearch: home.searchVideo,
                    onClear: home.clearSearch,
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class _Grid extends HookWidget {
  const _Grid();

  @override
  Widget build(BuildContext context) {
    final home = HomeController.i;
    useListenable(home.videoList);
    return NnyyFocusGroup(
      child: Focus(
        skipTraversal: true,
        onFocusChange: (v) {
          if (v) home.canPop.value = false;
        },
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 15),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 125,
                  childAspectRatio: 15 / 26,
                  crossAxisSpacing: 5,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return FocusTraversalOrder(
                      order: NumericFocusOrder(index.toDouble()),
                      child: index < home.videoList.value.length
                          ? VideoCard(home.videoList.value[index])
                          : MoreCard(key: UniqueKey()),
                    );
                  },
                  childCount:
                      home.videoList.value.length + (home.noMore ? 0 : 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
