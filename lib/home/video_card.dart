import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:icon_decoration/icon_decoration.dart';

import '../services/nnyy_data.dart';
import '../services/video_service.dart';
import '../video/video_controller.dart';
import '../video/video_view.dart';

class VideoCard extends HookWidget {
  const VideoCard(this.info, {super.key}) : coverOnly = false;
  const VideoCard.coverOnly(this.info, {super.key}) : coverOnly = true;

  final VideoInfo info;
  final bool coverOnly;

  @override
  Widget build(BuildContext context) {
    final video = NnyyData.videos[info.id];
    final fav = video.fav;
    final focused = useState(false);
    final twoLines = useState(false);
    final action = CallbackAction(onInvoke: (_) {
      VideoController.i.loadVideoDetail(info);
      VideoView.show(context);
      return null;
    });
    useListenable(video);
    return FocusableActionDetector(
      enabled: !coverOnly,
      descendantsAreFocusable: false,
      onShowFocusHighlight: (v) => focused.value = v,
      actions: {
        ActivateIntent: action,
        ButtonActivateIntent: action,
      },
      child: AnimatedScale(
        scale: focused.value ? 1.1 : 0.9,
        duration: Durations.short2,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: focused.value
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment(0.8, 1),
                    colors: <Color>[
                      Color(0xff1f005c),
                      Color(0xff5b0060),
                      Color(0xff870160),
                      Color(0xffac255e),
                      Color(0xffca485c),
                      Color(0xffe16b5c),
                      Color(0xfff39060),
                      Color(0xffffb56b),
                    ],
                    tileMode: TileMode.mirror,
                  )
                : null,
          ),
          child: Padding(
            padding: EdgeInsets.all(focused.value ? 4 : 0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: coverOnly ? 0 : 24),
                  child: CachedNetworkImage(
                    imageUrl: info.cover,
                    httpHeaders: kIsWeb
                        ? null
                        : const {
                            HttpHeaders.userAgentHeader: VideoService.userAgent
                          },
                    imageBuilder: (context, imageProvider) => DecoratedBox(
                      position: DecorationPosition.foreground,
                      decoration: BoxDecoration(
                        gradient: !twoLines.value
                            ? null
                            : const LinearGradient(
                                begin: Alignment.center,
                                end: Alignment.bottomCenter,
                                colors: <Color>[
                                  Color(0x00000000),
                                  Color(0x80000000),
                                ],
                              ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
                if (fav || !coverOnly && info.rate != null)
                  Positioned(
                    top: 0,
                    left: 4,
                    child: Row(
                      children: [
                        DecoratedIcon(
                          icon: Icon(
                            fav ? Icons.favorite : Icons.star_rate,
                            size: 16,
                            color: fav ? Colors.redAccent : Colors.yellowAccent,
                          ),
                          decoration: const IconDecoration(
                            border: IconBorder(width: 2),
                          ),
                        ),
                        _OutlineText(
                          strokeWidth: 2,
                          strokeColor: Colors.black.withOpacity(0.6),
                          child: Text(' ${info.rate ?? ''}'),
                        ),
                      ],
                    ),
                  ),
                if (!coverOnly)
                  Positioned(
                    top: 0,
                    right: 4,
                    child: _OutlineText(
                      strokeWidth: 2,
                      strokeColor: Colors.black.withOpacity(0.6),
                      child: Text(
                        '${info.year ?? ''}\n${info.country}',
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                if (!coverOnly)
                  LayoutBuilder(builder: (context, constraints) {
                    final style = Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold);
                    var tp = TextPainter(
                        text: TextSpan(text: info.title, style: style),
                        textDirection: Directionality.of(context));
                    tp.layout(maxWidth: constraints.maxWidth);
                    Future(() =>
                        twoLines.value = tp.computeLineMetrics().length > 1);
                    return Align(
                      alignment: Alignment.bottomCenter,
                      child: _OutlineText(
                        strokeWidth: 2,
                        strokeColor: Colors.black.withOpacity(0.6),
                        child: Text(
                          info.title,
                          maxLines: 2,
                          style: style,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }),
                if (!coverOnly)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => action.invoke(const ButtonActivateIntent()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlineText extends HookWidget {
  const _OutlineText({
    required this.child,
    this.strokeWidth = 2,
    this.strokeColor,
  });

  final Text child;
  final double strokeWidth;
  final Color? strokeColor;

  @override
  Widget build(BuildContext context) {
    var style = child.style ?? DefaultTextStyle.of(context).style;
    return Stack(
      children: [
        Text(child.data ?? '',
            textScaler: child.textScaler,
            maxLines: child.maxLines,
            overflow: child.overflow,
            textAlign: child.textAlign,
            style: style.copyWith(
                foreground: Paint()
                  ..color = strokeColor ?? Theme.of(context).shadowColor
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = strokeWidth)),
        child
      ],
    );
  }
}
