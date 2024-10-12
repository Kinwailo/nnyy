import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../services/nnyy_data.dart';
import '../services/save_strategy.dart';
import '../widgets/get_snack_bar.dart';
import '../widgets/nnyy_button.dart';
import '../widgets/nnyy_search_box.dart';
import '../widgets/nnyy_focus.dart';
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
      NnyyData.googleDriveStorage.signInSilently();
      return null;
    }, []);
    useValueChanged(home.error.value, (_, void __) {
      if (home.error.value.isEmpty) return;
      final messager = ScaffoldMessenger.of(context)..clearSnackBars();
      Future(() {
        messager.showSnackBar(getSnackBar(Text(home.error.value)));
        home.error.value = '';
      });
    });
    useValueChanged(SaveStrategy.i.syncingOnExit.value, (_, void __) {
      if (!SaveStrategy.i.syncingOnExit.value) return;
      final messager = ScaffoldMessenger.of(context)..clearSnackBars();
      const widget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(dimension: 24, child: CircularProgressIndicator()),
          SizedBox(width: 12),
          Text('Syncing to cloud storage...'),
        ],
      );
      Future(() {
        messager.showSnackBar(getSnackBar(widget));
        home.error.value = '';
      });
    });
    useListenable(home.canPop);
    useListenable(home.error);
    useListenable(NnyyData.googleDriveStorage);
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
              title: const SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _Filter(),
              ),
              backgroundColor: colorScheme.onPrimaryFixed,
              actions: [
                Padding(
                  padding: const EdgeInsets.all(4),
                  child: SizedBox.square(
                    dimension: 40,
                    child: NnyyData.googleDriveStorage.signInAvatar(),
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
      child: Focus(
        focusNode: home.filterFocus,
        onFocusChange: (v) {
          if (v) home.canPop.value = true;
        },
        child: Row(
          children: [
            const SizedBox(width: 8),
            NnyyButton.toggle(
              selected: NnyyData.data.history,
              onChanged: (v) => NnyyData.data.history = v,
              child: const Text('觀看記錄'),
            ),
            if (!NnyyData.data.history) ...[
              const SizedBox(width: 16),
              const Text('排序'),
              const SizedBox(width: 16),
              SegmentedButton(
                style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)))),
                segments: HomeController.sortList
                    .map((e) => ButtonSegment(value: e, label: Text(e)))
                    .toList(),
                showSelectedIcon: false,
                selected: {NnyyData.data.sort},
                onSelectionChanged: (v) => NnyyData.data.sort = v.first,
              ),
              const SizedBox(width: 16),
              const Text('分類'),
              const SizedBox(width: 8),
              DropdownButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                isDense: true,
                value: NnyyData.data.genre,
                items: [
                  ...HomeController.genreList
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                ],
                onChanged: (v) {
                  if (v != null) NnyyData.data.genre = v;
                },
              ),
              const SizedBox(width: 8),
              const Text('地區'),
              const SizedBox(width: 8),
              DropdownButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                isDense: true,
                value: NnyyData.data.country,
                items: [
                  ...HomeController.countryList
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                ],
                onChanged: (v) {
                  if (v != null) NnyyData.data.country = v;
                },
              ),
              const SizedBox(width: 8),
              const Text('年代'),
              const SizedBox(width: 8),
              DropdownButton(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                isDense: true,
                value: NnyyData.data.year,
                items: [
                  ...HomeController.yearList
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                ],
                onChanged: (v) {
                  if (v != null) NnyyData.data.year = v;
                },
              ),
              const SizedBox(width: 8),
              NnyySearchBox(
                width: 200,
                height: 32,
                onSearch: home.searchVideo,
                onClear: home.reloadVideoList,
              ),
            ],
          ],
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
                    return index < home.videoList.value.length
                        ? VideoCard(home.videoList.value[index])
                        : MoreCard(key: UniqueKey());
                  },
                  childCount: home.videoList.value.length +
                      (home.noMore || NnyyData.data.history ? 0 : 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
