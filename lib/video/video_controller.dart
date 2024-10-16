import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

import '../main.dart';
import '../services/nnyy_data.dart';
import '../services/video_service.dart';

enum VideoState { rest, loading, ready, error }

class VideoController {
  VideoController._() {
    FocusManager.instance.addListener(() {
      var focus = FocusManager.instance.primaryFocus;
      if (focus.runtimeType == FocusNode) focusNow = focus;
    });
  }

  static VideoController? _instance;
  static VideoController get i => _instance ??= VideoController._();

  final _detail = ValueNotifier<VideoDetail?>(null);

  final _ep = ValueNotifier('');
  final _site = ValueNotifier('');
  final _ssite = ValueNotifier('');
  final _video = ValueNotifier<VideoPlayerController?>(null);

  final _player = ValueNotifier(false);
  final _ui = ValueNotifier(false);
  final _lock = ValueNotifier(false);
  final _state = ValueNotifier<VideoState>(VideoState.rest);
  final _paused = ValueNotifier(false);
  final _seek = ValueNotifier(0);

  final _error = ValueNotifier('');

  ValueListenable<VideoDetail?> get detail => _detail;
  ValueListenable<String> get ep => _ep;
  ValueListenable<String> get site => _site;
  ValueListenable<VideoPlayerController?> get video => _video;
  ValueListenable<bool> get player => _player;
  ValueListenable<bool> get ui => _ui;
  ValueListenable<bool> get lock => _lock;
  ValueListenable<VideoState> get state => _state;
  ValueListenable<bool> get paused => _paused;
  ValueListenable<int> get seek => _seek;
  ValueListenable<String> get error => _error;

  late final tapAction = RepeatAction(_tapUI);
  late final rewindAction = RepeatAction(_rewind);
  late final forwardAction = RepeatAction(_forward);

  FocusNode? focusNow;
  FocusNode? focusView;
  final focusPlayer = FocusNode();
  final focusWebPlayer = FocusNode();

  var sites = <String, String>{};
  WebViewXController? webview;

  var _url = '';
  int _current = 0;
  int _length = 0;
  int _counter = 0;
  final _stopwatch = Stopwatch();
  var _uiStart = DateTime.now();

  Future<void> loadVideoDetail(VideoInfo info) async {
    _detail.value = null;
    try {
      _detail.value = await VideoService.i.getVideoDetail(info);
    } catch (e) {
      _error.value = e.toString();
      return;
    }
    NnyyData.videos[info.id].title = info.title;
    _ep.value = '';
    _site.value = '';
  }

  void clearError() {
    _error.value = '';
  }

  void _enterFullScreen() {
    if (unsupported) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
    WakelockPlus.enable();
    _player.value = true;
    focusView = focusNow;
    focusPlayer.requestFocus();
  }

  void _exitFullScreen() {
    if (unsupported) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WakelockPlus.disable();
    _player.value = false;
    focusView?.requestFocus();
  }

  void exitVideoUI() {
    _ui.value = false;
  }

  void exitVideoPlayer() {
    _player.value = false;
  }

  Future<void> play(String ep_) async {
    var d = detail.value;
    if (d == null) return;
    if (ep_ == ep.value) {
      _playVideo();
      _enterFullScreen();
    } else {
      _disposeVideo();
      _state.value = VideoState.loading;
      sites = await VideoService.i.getVideoSite(d.info, d.eps[ep_]!);
      sites = NnyyData.data.sortSiteMap(sites);
      _site.value =
          sites.containsKey(_ssite.value) ? _ssite.value : sites.keys.first;
      if (_ssite.value.isEmpty) _ssite.value = site.value;
      _ep.value = ep_;
      _enterFullScreen();
      _loadVideo(sites[site.value]!);
    }
  }

  void next(int offset, {bool auto = false}) {
    var d = detail.value;
    if (d == null) return;
    var eps = offset >= 0 ? d.eps.keys : d.eps.keys.toList().reversed;
    eps = eps.skipWhile((e) => e != ep.value);
    var next = eps.skip(offset.abs()).firstOrNull;
    if (next != null) {
      if (!auto || NnyyData.videos[d.info.id].next) {
        pause();
        play(next);
      }
      NnyyData.videos[d.info.id].ep = next;
    }
  }

  void setSite(String site_) {
    if (!sites.containsKey(site_)) return;
    if (site_ == site.value) {
      _playVideo();
      _enterFullScreen();
    } else {
      _disposeVideo();
      _site.value = site_;
      _ssite.value = site_;
      _enterFullScreen();
      _loadVideo(sites[site_]!);
    }
  }

  void _tapUI(int repeat, bool last) {
    if (repeat == 1 && last) {
      if (ui.value || paused.value) {
        toggle();
        showUI(ui.value);
      } else {
        showUI(true);
      }
    }
    if (repeat == 2 && last) {
      _lock.value = !lock.value;
      showUI(true);
    }
  }

  Future<void> showUI(bool show) async {
    _ui.value = show;
    _uiStart = DateTime.now();
    var start = _uiStart;
    await Future.delayed(Durations.extralong4 * 5);
    if (start != _uiStart) return;
    if (paused.value) return;
    _enterFullScreen();
    if (lock.value) return;
    _ui.value = false;
  }

  void toggle() {
    if (paused.value) {
      _playVideo();
    } else {
      pause();
    }
  }

  void pause() {
    _paused.value = true;
    _stopwatch.stop();
    video.value?.pause();
    _updateHistory();
  }

  void stop() {
    pause();
    _exitFullScreen();
  }

  void webviewEvent(String msg) {
    var event = msg.split(':');
    switch (event[0]) {
      case 'play':
        _stopwatch.start();
        break;
      case 'pause':
        _stopwatch.stop();
        _updateHistory();
        break;
      case 'stop':
        break;
      case 'current':
        _current = int.tryParse(event[1]) ?? 0;
        // _updateHistory();
        break;
      case 'meta':
        _length = int.tryParse(event[1]) ?? 0;
        _startWebVideo();
        break;
      case 'ended':
        next(1, auto: true);
        break;
      default:
    }
  }

  void _rewind(int repeat, bool last) {
    _seekTo(-1, repeat, last);
  }

  void _forward(int repeat, bool last) {
    _seekTo(1, repeat, last);
  }

  void _seekTo(int offset, int repeat, bool last) {
    if (video.value == null) return;
    if (!last) {
      var s = {6: 1, 11: 2, 16: 5, 27: 10};
      var k = s.keys.skipWhile((e) => repeat >= e).firstOrNull ?? 0;
      var v = s[k] ?? 30;
      _seek.value += offset * v;
      showUI(true);
    } else {
      var cur = video.value!.value.position.inSeconds;
      var len = video.value!.value.duration.inSeconds;
      cur += seek.value;
      cur = cur.clamp(0, len);
      _seek.value = 0;
      _seekVideo(cur);
      showUI(true);
    }
  }

  void dispose() {
    if (!paused.value) _updateHistory();
    _disposeVideo();
    sites = {};
    _ep.value = '';
    _exitFullScreen();
  }

  void _loadVideo(String url) {
    if (kIsWeb) {
      webview?.callJsMethod('loadVideo', [url]);
      return;
    }
    if (unsupported) return;
    _state.value = VideoState.loading;
    _paused.value = false;
    _stopwatch.stop();
    _stopwatch.reset();
    _url = url;
    var v = VideoPlayerController.networkUrl(Uri.parse(url),
        httpHeaders: {HttpHeaders.userAgentHeader: VideoService.userAgent});
    v.initialize().then((_) {
      v.addListener(() {
        if (v != video.value) return;
        if (video.value!.value.isCompleted) next(1, auto: true);
      });
      if (_url != url) return;
      _video.value = v;
      _startVideo();
    }).catchError((_) {
      if (v == video.value) {
        _state.value = VideoState.error;
        _video.value = null;
      }
      v.dispose();
    });
  }

  Future<void> _startVideo() async {
    var d = detail.value;
    if (d != null) {
      var progress = NnyyData.videos[d.info.id].progress[ep.value].data;
      var pos = progress.current;
      var len = video.value?.value.duration.inSeconds ?? 0;
      var skip = NnyyData.videos[d.info.id].skip;
      pos = max(pos, skip);
      if (pos < len) await _seekVideo(pos);
    }
    _state.value = VideoState.ready;
    if (!paused.value) {
      _playVideo();
      showUI(true);
    }
  }

  void _startWebVideo() {
    var d = detail.value;
    if (d != null) {
      var progress = NnyyData.videos[d.info.id].progress[ep.value].data;
      var pos = progress.current;
      var skip = NnyyData.videos[d.info.id].skip;
      pos = max(pos, skip);
      if (pos < _length) {
        _current = pos;
        webview?.callJsMethod('seekVideo', ['$pos']);
      }
    }
    _state.value = VideoState.ready;
  }

  void _playVideo() async {
    if (state.value != VideoState.ready) return;
    _paused.value = false;
    _stopwatch.start();
    video.value?.play();
    showUI(ui.value);
  }

  Future<void> _seekVideo(int pos) async {
    if (video.value == null) return;
    await video.value?.seekTo(Duration(seconds: pos));
    await Future.doWhile(() async {
      await Future.delayed(Durations.short1);
      return video.value?.value.isBuffering ?? true;
    });
  }

  Future<void> _disposeVideo() async {
    _paused.value = true;
    _stopwatch.stop();
    var v = video.value;
    _video.value = null;
    await v?.pause();
    v?.dispose();
  }

  void _updateHistory() {
    if (state.value != VideoState.ready) return;
    _counter += _stopwatch.elapsed.inMilliseconds;
    NnyyData.data.addSiteDuration(site.value, _counter ~/ 1000);
    _counter %= 1000;
    _stopwatch.reset();
    var d = detail.value;
    if (d != null) {
      var cur = kIsWeb ? _current : video.value!.value.position.inSeconds;
      var len = kIsWeb ? _length : video.value!.value.duration.inSeconds;
      {
        var video = NnyyData.videos[d.info.id];
        video.progress[ep.value].data = VideoProgress(cur, cur, len);
        video.title = d.info.title;
        video.ep = ep.value;
        video.datetime = DateTime.now();
      }
    }
  }
}

class RepeatAction {
  RepeatAction(this._action);

  final void Function(int value, bool last)? _action;
  int _repeat = 0;

  Future<void> invoke() async {
    _repeat++;
    _action?.call(_repeat, false);

    var repeat = _repeat;
    await Future.delayed(Durations.short2 * 5);
    if (repeat == _repeat) {
      _repeat = 0;
      _action?.call(repeat, true);
    }
  }
}
