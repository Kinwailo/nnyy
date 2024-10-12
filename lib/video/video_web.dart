import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

import 'video_controller.dart';

class VideoWeb extends HookWidget {
  const VideoWeb({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = VideoController.i;
    useEffect(() => () => controller.webviewEvent('stop'), []);
    return LayoutBuilder(builder: (context, constraints) {
      return WebViewX(
        key: const ValueKey('webviewx'),
        initialContent: _html,
        initialSourceType: SourceType.html,
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
      );
    });
  }

  static const String _html = """<!DOCTYPE html>
  <html>
    <head>
      <style  type="text/css" rel="stylesheet">
        body {
          margin: 0px;
          width: 100%;
          height: 100%;
          overflow: hidden;
        }
        .video-content video#video {
          position: absolute;
          top: 0;
          bottom: 0;
          left: 0;
          width: 100%;
          height: 100%;
          border: 0;
        }
      </style>
    </head>
    <body>
      <div class="video-content"><video id="video" controls preload></video></div>
      <script src="https://cdn.jsdelivr.net/npm/hls.js@1"></script>
      <script type="text/javascript">
        const hls = new Hls();
        const video = document.getElementById('video');

        hls.on(Hls.Events.ERROR, function (event, data) {
          // console.log('on hls error', event, data, data.details);
          if (data.fatal) { dartCallback('error'); }
        });

        var time = 0;
        var length = 0;
        video.onplay = (event) => { dartCallback('play'); };
        video.onpause = (event) => { dartCallback('pause'); };
        video.ontimeupdate = (event) => {
          var currentTime = Math.floor(video.currentTime)
          if(time != currentTime) {
            time = currentTime;
            dartCallback('current:' + time.toString());
          }
        };
        video.onloadedmetadata = (event) => { dartCallback('meta:' + Math.floor(video.duration).toString()); };
        video.onended = (event) => { dartCallback('ended'); };

        function loadVideo(src) {
          src = decodeURIComponent(src);
          time = 0;
          length = 0;
          hls.loadSource(src);
          hls.attachMedia(video);
        }

        function seekVideo(seek) {
          video.currentTime = parseFloat(seek);
        }
      </script>
    </body> 
  </html>""";
}
