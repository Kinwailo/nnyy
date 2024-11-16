import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../home/video_card.dart';
import '../services/nnyy_data.dart';
import '../widgets/get_snack_bar.dart';
import '../widgets/nnyy_button.dart';
import '../widgets/nnyy_checkbox.dart';
import '../widgets/nnyy_duration_box.dart';
import '../widgets/nnyy_select_button.dart';
import '../widgets/nnyy_toggle.dart';
import '../widgets/nnyy_focus.dart';
import '../main.dart';
import 'video_controller.dart';
import 'video_play.dart';
import 'video_web.dart';

class VideoView extends HookWidget {
  const VideoView({super.key});

  static void show(BuildContext context) {
    Navigator.of(context, rootNavigator: true)
        .push(MaterialPageRoute(builder: (_) => const VideoView()));
  }

  @override
  Widget build(BuildContext context) {
    final controller = VideoController.i;
    useAutomaticKeepAlive();
    useOnAppLifecycleStateChange((_, state) async {
      if (state == AppLifecycleState.paused) controller.pause();
    });
    useValueChanged(controller.error.value, (_, void __) {
      if (controller.error.value.isEmpty) return;
      final messager = ScaffoldMessenger.of(context)..clearSnackBars();
      final navigator = Navigator.of(context, rootNavigator: true);
      Future(() async {
        messager.showSnackBar(getSnackBar(Text(controller.error.value)));
        controller.clearError();
        await Future.delayed(Durations.extralong4 * 2);
        navigator.pop();
      });
    });
    useListenable(controller.detail);
    useListenable(controller.fullscreen);
    useListenable(controller.error);
    return PopScope(
      canPop: !controller.fullscreen.value,
      onPopInvoked: (didPop) async {
        if (didPop) {
          controller.dispose();
          NnyyData.saveAll();
          return;
        }
        if (controller.controls.value) {
          controller.hideControls();
        } else {
          controller.stop();
          NnyyData.saveAll();
        }
      },
      child: SafeArea(
        child: Scaffold(
          body: FocusTraversalGroup(
            policy: ReadingOrderTraversalPolicy(
              requestFocusCallback: (node,
                      {alignment, alignmentPolicy, curve, duration}) =>
                  FocusTraversalPolicy.defaultTraversalRequestFocusCallback(
                node,
                alignment: alignment,
                alignmentPolicy: alignmentPolicy,
                curve: curve,
                duration: Durations.short4,
              ),
            ),
            child: IndexedStack(
              index: controller.fullscreen.value && !kIsWeb ? 1 : 0,
              children: [
                controller.detail.value == null
                    ? const Center(child: CircularProgressIndicator())
                    : MediaQuery.of(context).orientation ==
                            Orientation.landscape
                        ? const _VideoDetail()
                        : const _VideoDetailV(),
                unsupported ? const SizedBox.shrink() : const VideoPlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoDetail extends HookWidget {
  const _VideoDetail();

  @override
  Widget build(BuildContext context) {
    final controller = VideoController.i;
    final detail = useValueListenable(controller.detail)!;
    useListenable(controller.sites);
    return NnyyFocusGroup(
      child: VideoWebShortcut(
        child: Focus(
          autofocus: true,
          skipTraversal: true,
          child: SingleChildScrollView(
            child: Center(
              child: SizedBox(
                width: kIsWeb ? 1000 : null,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 200,
                      child: Column(
                        children: [
                          _VideoCover(),
                          _VideoInfo(),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _VideoTitle(),
                          ExcludeFocus(
                              child: SelectionArea(child: Text(detail.intro))),
                          const _VideoMeta(),
                          if (kIsWeb) const _VideoEmbed(),
                          Visibility(
                            visible: controller.sites.value.isNotEmpty,
                            maintainState: true,
                            child: const Column(
                              children: [
                                _VideoState(),
                                _VideoSiteList(),
                              ],
                            ),
                          ),
                          const _VideoEpList(),
                        ]
                            .map((e) => Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                child: e))
                            .toList(),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _VideoDetailV extends HookWidget {
  const _VideoDetailV();

  @override
  Widget build(BuildContext context) {
    final controller = VideoController.i;
    final detail = useValueListenable(controller.detail)!;
    useListenable(controller.sites);
    return VideoWebShortcut(
      child: Focus(
        autofocus: true,
        skipTraversal: true,
        child: ListView(
          children: [
            const _VideoTitle(),
            const Row(
              children: [
                SizedBox(width: 200, child: _VideoCover()),
                Expanded(child: _VideoInfo()),
              ],
            ),
            ExcludeFocus(child: SelectionArea(child: Text(detail.intro))),
            const _VideoMeta(),
            if (kIsWeb) const _VideoEmbed(),
            Visibility(
              visible: controller.sites.value.isNotEmpty,
              maintainState: true,
              child: const Column(
                children: [
                  _VideoState(),
                  _VideoSiteList(),
                ],
              ),
            ),
            const _VideoEpList(),
          ]
              .map((e) => Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: e))
              .toList(),
        ),
      ),
    );
  }
}

class _VideoInfo extends HookWidget {
  const _VideoInfo();

  @override
  Widget build(BuildContext context) {
    final controller = VideoController.i;
    final detail = controller.detail.value!;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ExcludeFocus(
        child: SelectionArea(
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(48),
              1: FlexColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.top,
            children: [
              TableRow(
                children: [
                  const Text('導演：'),
                  Text(detail.director),
                ],
              ),
              TableRow(
                children: [
                  const Text('主演：'),
                  Text(detail.starring),
                ],
              ),
              TableRow(
                children: [
                  const Text('類型：'),
                  Text(detail.genre),
                ],
              ),
              TableRow(
                children: [
                  const Text('地區：'),
                  Text(detail.country),
                ],
              ),
              if (detail.alt.isNotEmpty)
                TableRow(
                  children: [
                    const Text('又名：'),
                    Text(detail.alt),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoCover extends HookWidget {
  const _VideoCover();

  @override
  Widget build(BuildContext context) {
    final detail = VideoController.i.detail.value!;
    return SizedBox(
      width: 200,
      height: 300,
      child: VideoCard.coverOnly(detail.info),
    );
  }
}

class _VideoTitle extends HookWidget {
  const _VideoTitle();

  @override
  Widget build(BuildContext context) {
    final detail = VideoController.i.detail.value!;
    final year = detail.info.year;
    return Row(
      children: [
        const BackButton(),
        const SizedBox(width: 8),
        ExcludeFocus(
          child: SelectionArea(
            child: Text(
              '${detail.info.title}${year == null ? '' : ' ($year)'}',
              style: Theme.of(context)
                  .textTheme
                  .headlineLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
          ),
        ),
      ],
    );
  }
}

class _VideoEmbed extends HookWidget {
  const _VideoEmbed();

  @override
  Widget build(BuildContext context) {
    final controller = VideoController.i;
    final settings = useValueListenable(controller.settings);
    return Focus(
      focusNode: controller.focusWebPlayer,
      canRequestFocus: false,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const VideoWeb(),
        const VideoWebControl(),
        if (settings) const VideoWebSettings(),
      ]),
    );
  }
}

class _VideoMeta extends HookWidget {
  const _VideoMeta();

  @override
  Widget build(BuildContext context) {
    final controller = VideoController.i;
    final info = controller.detail.value!.info;
    final videoData = controller.videoData.value!;
    useListenable(videoData);
    return NnyyFocusGroup(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: [
          FocusTraversalOrder(
            order: const NumericFocusOrder(0),
            child: NnyyToggle(
              value: videoData.fav,
              onChanged: (v) {
                videoData.title = info.title;
                videoData.fav = v;
                videoData.datetime = DateTime.now();
                if (!v) videoData.removeFav();
              },
              activeColor: Colors.redAccent,
              icon: Icons.favorite_border,
              activeIcon: Icons.favorite,
            ),
          ),
          if (videoData.ep.isNotEmpty) ...[
            const SizedBox(width: 8),
            FocusTraversalOrder(
              order: const NumericFocusOrder(1),
              child: NnyyButton(
                onPressed: () => controller.play(videoData.ep),
                child: Text('繼續播放${videoData.ep}'),
              ),
            ),
            const SizedBox(width: 8),
          ],
          FocusTraversalOrder(
            order: const NumericFocusOrder(2),
            child: NnyyCheckbox(
              label: '自動播放下一集',
              value: videoData.next,
              onChanged: (v) {
                videoData.title = info.title;
                videoData.next = v;
                videoData.datetime = DateTime.now();
              },
            ),
          ),
          FocusTraversalOrder(
            order: const NumericFocusOrder(3),
            child: NnyyDurationBox(
                label: '跳過片頭',
                value: Duration(seconds: videoData.skip),
                onChanged: (v) {
                  videoData.title = info.title;
                  videoData.skip = v.inSeconds;
                  videoData.datetime = DateTime.now();
                }),
          ),
          const SizedBox(width: 8),
          FocusTraversalOrder(
            order: const NumericFocusOrder(4),
            child: NnyyButton(
              onPressed: () {
                videoData.ep = '';
                videoData.delete();
                if (videoData.fav == false) {
                  Navigator.of(context, rootNavigator: true).pop();
                }
              },
              child: const Text('刪除記錄'),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoState extends HookWidget {
  const _VideoState();

  @override
  Widget build(BuildContext context) {
    final controller = VideoController.i;
    final ep = controller.ep.value;
    final state = switch (controller.state.value) {
      VideoState.rest => '',
      VideoState.loading => '正在載入$ep，可選擇其他播放線路：',
      VideoState.ready => '$ep播放中，可選擇其他播放線路：',
      VideoState.error => '載入$ep出錯，可選擇其他播放線路：',
    };
    useListenable(controller.ep);
    useListenable(controller.state);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        switch (controller.state.value) {
          VideoState.rest => const SizedBox.shrink(),
          VideoState.loading => const SizedBox.square(
              dimension: 12, child: CircularProgressIndicator(strokeWidth: 1)),
          VideoState.ready =>
            const Icon(Icons.play_arrow, size: 16, color: Colors.greenAccent),
          VideoState.error =>
            const Icon(Icons.error, size: 16, color: Colors.redAccent),
        },
        const SizedBox(width: 4),
        Text(state, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _VideoSiteList extends HookWidget {
  const _VideoSiteList();

  @override
  Widget build(BuildContext context) {
    final controller = VideoController.i;
    final sites = controller.sites.value.keys;
    var selected = controller.site.value;
    if (!sites.contains(selected)) selected = sites.firstOrNull ?? '';
    useListenable(controller.site);
    useListenable(controller.sites);
    return NnyyFocusGroup(
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: NnyySelectButton(
            segments: (sites.isEmpty ? [''] : [...sites]),
            selected: selected,
            onChanged: (v) => controller.setSite(v),
          ),
        ),
      ),
    );
  }
}

class _VideoEpList extends HookWidget {
  const _VideoEpList();

  Iterable<T> reverseList<T>(List<T> list, bool reverse) {
    if (reverse) return list.reversed;
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final controller = VideoController.i;
    final detail = controller.detail.value!;
    const itemsPrePage = 100;
    final length = detail.eps.length;
    final pages = (length / itemsPrePage).ceil();
    final videoData = controller.videoData.value!;
    final findPage = useCallback(() {
      final ep = detail.eps.keys.toList().indexOf(videoData.ep);
      return ep == -1
          ? 0
          : videoData.reverse
              ? ((length - ep - 1) / itemsPrePage).floor()
              : (ep / itemsPrePage).floor();
    });
    final page = useState(findPage());
    useValueChanged(videoData.reverse, (_, void __) => page.value = findPage());
    useListenable(videoData);
    return NnyyFocusGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Visibility(
            visible: pages > 1,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(-2),
                    child: NnyyToggle(
                        value: videoData.reverse,
                        onChanged: (v) => videoData.reverse = v,
                        icon: Icons.sync_alt,
                        activeColor: colorScheme.onTertiaryContainer),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: FocusTraversalOrder(
                        order: const NumericFocusOrder(-1),
                        child: NnyySelectButton(
                            segments: List.generate(pages, (p) => p),
                            selected: page.value,
                            onChanged: (v) => page.value = v,
                            getText: (v) => videoData.reverse
                                ? '${length - v * itemsPrePage} - ${max(1, length - (v + 1) * itemsPrePage + 1)}'
                                : '${v * itemsPrePage + 1} - ${min(length, (v + 1) * itemsPrePage)}'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: GridView.extent(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              maxCrossAxisExtent: 112,
              childAspectRatio: 112 / 36,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: reverseList(detail.eps.keys.toList(), videoData.reverse)
                  .skip(page.value * itemsPrePage)
                  .mapIndexed((i, e) => FocusTraversalOrder(
                      order: NumericFocusOrder(i.toDouble()),
                      child: _EpButton(key: Key(e), e)))
                  .take(itemsPrePage)
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _EpButton extends HookWidget {
  const _EpButton(this.ep, {super.key});

  final String ep;

  @override
  Widget build(BuildContext context) {
    final controller = VideoController.i;
    final progress = controller.videoData.value!.progress[ep];
    final playVideo = useCallback(() {
      if (kIsWeb) {
        Scrollable.ensureVisible(
          controller.focusWebPlayer.context!,
          alignment: 0.9,
          alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
          duration: Durations.short4,
          curve: Curves.ease,
        );
      }
      return controller.play(ep);
    });
    useListenable(progress);
    final selected =
        useListenableSelector(controller.ep, () => controller.ep.value == ep);
    return NnyyButton.selectable(
      selected: selected,
      onPressed: playVideo,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(ep, maxLines: 1, overflow: TextOverflow.ellipsis),
          LinearProgressIndicator(value: progress.data.value, minHeight: 2),
        ],
      ),
    );
  }
}
