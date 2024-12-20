import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

import '../services/nnyy_data.dart';
import '../widgets/nnyy_shortcut.dart';
import '../video/video_play.dart';
import 'video_controller.dart';
import 'video_web_html.dart';

class VideoWeb extends HookWidget {
  const VideoWeb({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = VideoController.i;
    useEffect(() => () => controller.webviewEvent('stop'), []);
    return ExcludeFocus(
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                WebViewX(
                  key: const ValueKey('webviewx'),
                  initialContent: html,
                  initialSourceType: SourceType.html,
                  ignoreAllGestures: true,
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  onWebViewCreated: (c) => controller.webview = c,
                  javascriptMode: JavascriptMode.unrestricted,
                  jsContent: const {},
                  dartCallBacks: {
                    DartCallback(
                      name: 'dartCallback',
                      callBack: (msg) => controller.webviewEvent(msg),
                    ),
                  },
                  webSpecificParams: const WebSpecificParams(),
                  mobileSpecificParams: const MobileSpecificParams(
                    androidEnableHybridComposition: true,
                  ),
                ),
                const VideoWebOverlay(),
              ],
            );
          },
        ),
      ),
    );
  }
}

class VideoWebOverlay extends HookWidget {
  const VideoWebOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = VideoController.i;
    return ExcludeFocus(
      child: SizedBox.expand(
        child: GestureDetector(
          onTap: () => controller.webview?.callJsMethod('playVideo', []),
          onDoubleTap: () =>
              controller.webview?.callJsMethod('toggleFullscreen', []),
        ),
      ),
    );
  }
}

class VideoWebControl extends HookWidget {
  const VideoWebControl({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = VideoController.i;
    final videoData = controller.videoData.value;
    final actions = controller.webActions;
    final volumeHint = useState(1.0);
    final progressHint = useState(1.0);
    final current = controller.current.value / controller.length.value;
    final buffered = controller.buffered.value / controller.length.value;
    useListenable(videoData);
    useListenable(controller.paused);
    useListenable(controller.current);
    useListenable(controller.buffered);
    final ready = useListenableSelector(
        controller.state, () => controller.state.value == VideoState.ready);
    return BottomAppBar(
      height: 52,
      padding: const EdgeInsets.all(2),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            child: Tooltip(
              message: !ready
                  ? ''
                  : Duration(
                          seconds:
                              progressHint.value * controller.length.value ~/ 1)
                      .shortString,
              child: VideoWebProgress(
                height: 8,
                value: current,
                value2: buffered,
                onHover: !ready ? null : (x) => progressHint.value = x,
                onTap: actions.seek,
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              VideoWebButton(
                  controller.paused.value ? Icons.play_arrow : Icons.pause,
                  onPressed: actions.play),
              const SizedBox(width: 8),
              VideoWebButton(Icons.skip_previous, onPressed: actions.previous),
              VideoWebButton(Icons.fast_rewind, onPressed: actions.rewind),
              VideoWebButton(Icons.fast_forward, onPressed: actions.forward),
              VideoWebButton(Icons.skip_next, onPressed: actions.next),
              const SizedBox(width: 16),
              if (ready) const VideoWebPosition(),
              const Spacer(),
              VideoWebButton(Icons.remove, onPressed: actions.speedDown),
              TextButton(
                  onPressed: actions.speedReset,
                  child: Text('${videoData!.speed.toStringAsFixed(2)}x')),
              VideoWebButton(Icons.add, onPressed: actions.speedUp),
              const SizedBox(width: 16),
              SizedBox(
                width: 60,
                child: Tooltip(
                    message:
                        !ready ? '' : '${volumeHint.value * 10000 ~/ 100}%',
                    child: VideoWebProgress(
                      height: 20,
                      value: videoData.volume.toDouble(),
                      onHover: !ready ? null : (x) => volumeHint.value = x,
                      onTap: actions.changeVolume,
                    )),
              ),
              const SizedBox(width: 4),
              Tooltip(
                message: !ready
                    ? ''
                    : videoData.mute
                        ? '靜音'
                        : '${videoData.volume * 10000 ~/ 100}%',
                child: VideoWebButton(
                    videoData.mute ? Icons.volume_mute : Icons.volume_up,
                    onPressed: actions.mute),
              ),
              VideoWebButton(Icons.camera_alt, onPressed: actions.saveImage),
              VideoWebButton(Icons.settings,
                  onPressed: controller.toggleSettings),
              VideoWebButton(Icons.fullscreen, onPressed: actions.fullscreen),
            ],
          ),
        ],
      ),
    );
  }
}

class VideoWebButton extends HookWidget {
  const VideoWebButton(this.icon, {super.key, required this.onPressed});

  final IconData icon;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 16,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon),
      onPressed: onPressed,
    );
  }
}

class VideoWebShortcut extends HookWidget {
  const VideoWebShortcut({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final controller = VideoController.i;
    useListenable(NnyyData.data);
    final ready = useListenableSelector(
        controller.state, () => controller.state.value == VideoState.ready);
    return CallbackShortcuts(
      bindings: !kIsWeb || !ready ? {} : controller.webShortcutActions,
      child: child,
    );
  }
}

class VideoWebSettings extends HookWidget {
  const VideoWebSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    useListenable(NnyyData.data);
    return Material(
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            ShortcutChip('播放', NnyyData.data.shortcutPlay,
                onChanged: (v) => NnyyData.data.shortcutPlay = v),
            ShortcutChip('上一集', NnyyData.data.shortcutPrevious,
                onChanged: (v) => NnyyData.data.shortcutPrevious = v),
            ShortcutChip('下一集', NnyyData.data.shortcutNext,
                onChanged: (v) => NnyyData.data.shortcutNext = v),
            ShortcutChip('倒退', NnyyData.data.shortcutRewind,
                onChanged: (v) => NnyyData.data.shortcutRewind = v),
            ShortcutChip('快進', NnyyData.data.shortcutForward,
                onChanged: (v) => NnyyData.data.shortcutForward = v),
            ShortcutChip('降低速度', NnyyData.data.shortcutSpeedDown,
                onChanged: (v) => NnyyData.data.shortcutSpeedDown = v),
            ShortcutChip('增加速度', NnyyData.data.shortcutSpeedUp,
                onChanged: (v) => NnyyData.data.shortcutSpeedUp = v),
            ShortcutChip('重置速度', NnyyData.data.shortcutSpeedReset,
                onChanged: (v) => NnyyData.data.shortcutSpeedReset = v),
            ShortcutChip('降低音量', NnyyData.data.shortcutVolumeDown,
                onChanged: (v) => NnyyData.data.shortcutVolumeDown = v),
            ShortcutChip('增加音量', NnyyData.data.shortcutVolumeUp,
                onChanged: (v) => NnyyData.data.shortcutVolumeUp = v),
            ShortcutChip('靜音', NnyyData.data.shortcutMute,
                onChanged: (v) => NnyyData.data.shortcutMute = v),
            ShortcutChip('儲存圖片', NnyyData.data.shortcutSaveImage,
                onChanged: (v) => NnyyData.data.shortcutSaveImage = v),
            ShortcutChip('全螢幕', NnyyData.data.shortcutFullscreen,
                onChanged: (v) => NnyyData.data.shortcutFullscreen = v),
          ],
        ),
      ),
    );
  }
}

class VideoWebPosition extends HookWidget {
  const VideoWebPosition({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = VideoController.i;
    final pos = Duration(seconds: controller.current.value).shortString;
    final len = Duration(seconds: controller.length.value).shortString;
    useListenable(controller.current);
    useListenable(controller.length);
    return Text('$pos / $len', style: Theme.of(context).textTheme.titleSmall);
  }
}

class VideoWebProgress extends HookWidget {
  const VideoWebProgress({
    super.key,
    required this.value,
    this.value2,
    this.height,
    this.onHover,
    this.onTap,
  });

  final double value;
  final double? value2;
  final double? height;
  final void Function(double x)? onHover;
  final void Function(double x)? onTap;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(2));
    return LayoutBuilder(
      builder: (context, constraints) {
        tap(double x, void Function(double x)? callback) => callback
            ?.call(clampDouble((x - 1) / (constraints.maxWidth - 2), 0.0, 1.0));
        return MouseRegion(
          cursor: onHover == null && onTap == null
              ? MouseCursor.defer
              : WidgetStateMouseCursor.clickable,
          onHover: (e) => tap(e.localPosition.dx, onHover),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (e) => tap(e.localPosition.dx, onTap),
            onHorizontalDragUpdate: (e) => tap(e.localPosition.dx, onTap),
            child: Opacity(
              opacity: onHover == null && onTap == null ? 0.3 : 1.0,
              child: SizedBox(
                height: height,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const LinearProgressIndicator(
                      value: 0,
                      borderRadius: radius,
                    ),
                    Opacity(
                      opacity: 0.2,
                      child: LinearProgressIndicator(
                        value: value2 ?? 0,
                        borderRadius: radius,
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                    LinearProgressIndicator(
                        value: value,
                        borderRadius: radius,
                        backgroundColor: Colors.transparent),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
