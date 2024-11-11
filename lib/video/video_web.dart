import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:nnyy/video/video_play.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

import '../services/nnyy_data.dart';
import 'video_controller.dart';
import 'video_web_html.dart';

class VideoWeb extends HookWidget {
  const VideoWeb({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = VideoController.i;
    useEffect(() => () => controller.webviewEvent('stop'), []);
    return AspectRatio(
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
    );
  }
}

class VideoWebOverlay extends HookWidget {
  const VideoWebOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = VideoController.i;
    return WebViewAware(
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
    final info = controller.detail.value!.info;
    final video = NnyyData.videos[info.id];
    final volumeHint = useState(1.0);
    final progressHint = useState(1.0);
    final current = controller.current.value / controller.length.value;
    final buffered = controller.buffered.value / controller.length.value;
    changeSpeed(double speed) => controller.webview?.callJsMethod(
        'changeSpeed', [video.speed = clampDouble(speed, 0.25, 3.0)]);
    useListenable(video);
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
                onTap: !ready
                    ? null
                    : (x) => controller.webview?.callJsMethod(
                        'seekVideo', [x * controller.length.value]),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              VideoWebButton(
                  controller.paused.value ? Icons.play_arrow : Icons.pause,
                  onPressed: !ready
                      ? null
                      : () =>
                          controller.webview?.callJsMethod('playVideo', [])),
              const SizedBox(width: 8),
              VideoWebButton(Icons.skip_previous,
                  onPressed: !ready ? null : () => controller.next(-1)),
              VideoWebButton(Icons.fast_rewind,
                  onPressed: !ready
                      ? null
                      : () => controller.webview
                          ?.callJsMethod('offsetVideo', [-2])),
              VideoWebButton(Icons.fast_forward,
                  onPressed: !ready
                      ? null
                      : () =>
                          controller.webview?.callJsMethod('offsetVideo', [2])),
              VideoWebButton(Icons.skip_next,
                  onPressed: !ready ? null : () => controller.next(1)),
              const SizedBox(width: 16),
              if (ready) const VideoWebPosition(),
              const Spacer(),
              VideoWebButton(Icons.remove,
                  onPressed:
                      !ready ? null : () => changeSpeed(video.speed - 0.25)),
              TextButton(
                  onPressed: !ready ? null : () => changeSpeed(1.0),
                  child: Text('${video.speed.toStringAsFixed(2)}x')),
              VideoWebButton(Icons.add,
                  onPressed:
                      !ready ? null : () => changeSpeed(video.speed + 0.25)),
              const SizedBox(width: 16),
              SizedBox(
                width: 60,
                child: Tooltip(
                    message:
                        !ready ? '' : '${volumeHint.value * 10000 ~/ 100}%',
                    child: VideoWebProgress(
                      height: 20,
                      value: video.volume,
                      onHover: !ready ? null : (x) => volumeHint.value = x,
                      onTap: !ready
                          ? null
                          : (x) => controller.webview?.callJsMethod(
                              'changeVolume',
                              [video.volume = (x * 100 ~/ 1) / 100]),
                    )),
              ),
              const SizedBox(width: 4),
              Tooltip(
                message: !ready
                    ? ''
                    : video.mute
                        ? '靜音'
                        : '${video.volume * 10000 ~/ 100}%',
                child: VideoWebButton(
                    video.mute ? Icons.volume_mute : Icons.volume_up,
                    onPressed: !ready
                        ? null
                        : () => controller.webview?.callJsMethod(
                            'muteVideo', [video.mute = !video.mute])),
              ),
              VideoWebButton(Icons.fullscreen,
                  onPressed: !ready
                      ? null
                      : () => controller.webview
                          ?.callJsMethod('toggleFullscreen', [])),
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
