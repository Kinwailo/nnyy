import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:video_player/video_player.dart';

import 'video_controller.dart';

extension DurationText on Duration {
  String get shortString {
    final min = inSeconds ~/ 60;
    final minText = min < 10 ? "0$min" : "$min";
    final sec = inSeconds % 60;
    final secText = sec < 10 ? "0$sec" : "$sec";
    return '$minText:$secText';
  }
}

class VideoPlay extends HookWidget {
  const VideoPlay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = VideoController.i;
    useListenable(controller.player);
    useListenable(controller.state);
    final action =
        CallbackAction(onInvoke: (_) => controller.tapAction.invoke());
    final dir = CallbackAction(onInvoke: (DirectionalFocusIntent intent) {
      return switch (intent.direction) {
        TraversalDirection.up => controller.next(-1),
        TraversalDirection.down => controller.next(1),
        TraversalDirection.left => controller.rewindAction.invoke(),
        TraversalDirection.right => controller.forwardAction.invoke(),
      };
    });
    return FocusableActionDetector(
      focusNode: controller.focusPlayer,
      enabled: controller.player.value,
      actions: {
        ActivateIntent: action,
        ButtonActivateIntent: action,
        DirectionalFocusIntent: dir,
      },
      child: Center(
        child: controller.state.value != VideoState.ready
            ? const CircularProgressIndicator()
            : const _VideoPlayUI(),
      ),
    );
  }
}

class _VideoPlayUI extends HookWidget {
  const _VideoPlayUI();

  @override
  Widget build(BuildContext context) {
    final controller = VideoController.i;
    final video = controller.video.value;
    useListenable(controller.ui);
    return GestureDetector(
      onTap: controller.tapAction.invoke,
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null) {
          controller.next(details.primaryVelocity! < 0 ? -1 : 1);
        }
      },
      onHorizontalDragUpdate: (details) {
        if (details.primaryDelta != null && details.primaryDelta!.abs() > 3) {
          details.primaryDelta! < 0
              ? controller.rewindAction.invoke()
              : controller.forwardAction.invoke();
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: (video == null)
            ? []
            : [
                AspectRatio(
                  aspectRatio: video.value.aspectRatio,
                  child: VideoPlayer(video),
                ),
                const _VideoBuffering(),
                if (controller.ui.value) ...[
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child:
                          VideoProgressIndicator(video, allowScrubbing: true),
                    ),
                  ),
                  const _VideoTitle(),
                  const _VideoPosition(),
                  const _VideoLock(),
                  const _VideoSeeking(),
                  const _VideoSeekCursor(),
                ]
              ],
      ),
    );
  }
}

class _VideoTitle extends HookWidget {
  const _VideoTitle();

  @override
  Widget build(BuildContext context) {
    final controller = VideoController.i;
    final detail = controller.detail.value;
    final ep = controller.ep.value;
    final video = controller.video.value!;
    useListenableSelector(video, () => video.value.isBuffering);
    return Positioned(
      left: 8,
      top: 4,
      child: Row(
        children: [
          ExcludeFocus(
            child: BackButton(onPressed: () => controller.player.value = false),
          ),
          Text(
            '${detail!.info.title} $ep',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}

class _VideoBuffering extends HookWidget {
  const _VideoBuffering();

  @override
  Widget build(BuildContext context) {
    final controller = VideoController.i;
    final video = controller.video.value!;
    useListenableSelector(video, () => video.value.isBuffering);
    return Visibility(
      visible: video.value.isBuffering,
      child: const CircularProgressIndicator(),
    );
  }
}

class _VideoSeeking extends HookWidget {
  const _VideoSeeking();

  @override
  Widget build(BuildContext context) {
    final controller = VideoController.i;
    final dur = Duration(seconds: controller.seek.value.abs());
    useListenable(controller.seek);
    return Visibility(
      visible: controller.seek.value != 0,
      child: Text(dur.shortString,
          style: Theme.of(context).textTheme.displayMedium),
    );
  }
}

class _VideoSeekCursor extends HookWidget {
  const _VideoSeekCursor();

  @override
  Widget build(BuildContext context) {
    final controller = VideoController.i;
    final video = controller.video.value!;
    final pos = video.value.position.inSeconds + controller.seek.value;
    final len = video.value.duration.inSeconds;
    final progress = clampDouble(pos / len, 0, 1);
    useListenable(controller.seek);
    return Visibility(
      visible: controller.seek.value != 0,
      child: Align(
        alignment: FractionalOffset(progress, 1.0),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: SizedBox(
            width: 1, height: 4,
            child: ColoredBox(color: Colors.white),
            // child: OverflowBox(child: Icon(Icons.arrow_downward)),
          ),
        ),
      ),
    );
  }
}

class _VideoLock extends HookWidget {
  const _VideoLock();

  @override
  Widget build(BuildContext context) {
    final controller = VideoController.i;
    useListenable(controller.lock);
    return Visibility(
      visible: controller.lock.value,
      child: const Positioned(
        left: 4,
        bottom: 8,
        child: Icon(Icons.lock, size: 16),
      ),
    );
  }
}

class _VideoPosition extends HookWidget {
  const _VideoPosition();

  @override
  Widget build(BuildContext context) {
    final controller = VideoController.i;
    final video = controller.video.value!;
    final pos = video.value.position.toString().split('.')[0];
    final len = video.value.duration.toString().split('.')[0];
    useListenableSelector(video, () => video.value.position);
    return Positioned(
      right: 4,
      bottom: 8,
      child: Text('$pos / $len', style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
