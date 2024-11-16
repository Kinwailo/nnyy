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
  final _videoData = ValueNotifier<NnyyVideoData?>(null);

  final _ep = ValueNotifier('');
  final _site = ValueNotifier('');
  final _ssite = ValueNotifier('');
  final _video = ValueNotifier<VideoPlayerController?>(null);

  final _fullscreen = ValueNotifier(false);
  final _controls = ValueNotifier(false);
  final _lock = ValueNotifier(false);
  final _state = ValueNotifier<VideoState>(VideoState.rest);
  final _paused = ValueNotifier(true);
  final _seek = ValueNotifier(0);
  final _current = ValueNotifier(0);
  final _length = ValueNotifier(1);
  final _buffered = ValueNotifier(0);

  final _error = ValueNotifier('');
  final _settings = ValueNotifier(false);

  ValueListenable<VideoDetail?> get detail => _detail;
  ValueListenable<NnyyVideoData?> get videoData => _videoData;

  ValueListenable<String> get ep => _ep;
  ValueListenable<String> get site => _site;
  ValueListenable<VideoPlayerController?> get video => _video;
  ValueListenable<bool> get fullscreen => _fullscreen;
  ValueListenable<bool> get controls => _controls;
  ValueListenable<bool> get lock => _lock;
  ValueListenable<VideoState> get state => _state;
  ValueListenable<bool> get paused => _paused;
  ValueListenable<int> get seek => _seek;
  ValueListenable<int> get current => _current;
  ValueListenable<int> get length => _length;
  ValueListenable<int> get buffered => _buffered;
  ValueListenable<String> get error => _error;
  ValueListenable<bool> get settings => _settings;

  late final tapAction = RepeatAction(_tapAction);
  late final rewindAction = RepeatAction(_rewindAction);
  late final forwardAction = RepeatAction(_forwardAction);

  FocusNode? focusNow;
  FocusNode? focusView;
  final focusPlayer = FocusNode();
  final focusWebPlayer = FocusNode();

  var sites = <String, String>{};
  WebViewXController? webview;

  var _url = '';
  int _counter = 0;
  final _stopwatch = Stopwatch();
  var _controlsTick = DateTime.now();

  Future<void> loadVideoDetail(VideoInfo info) async {
    _detail.value = null;
    _videoData.value = null;
    _ep.value = '';
    _site.value = '';
    _state.value = VideoState.rest;
    _current.value = 0;
    _length.value = 1;
    _buffered.value = 0;
    try {
      _detail.value = await VideoService.i.getVideoDetail(info);
    } catch (e) {
      _error.value = e.toString();
      return;
    }
    _videoData.value = NnyyData.videos[info.id];
    videoData.value!.title = info.title;
  }

  void clearError() {
    _error.value = '';
  }

  void toggleSettings() {
    _settings.value = !_settings.value;
  }

  void _enterFullScreen() {
    if (unsupported) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
    WakelockPlus.enable();
    _fullscreen.value = true;
    focusView = focusNow;
    focusPlayer.requestFocus();
  }

  void _exitFullScreen() {
    if (unsupported) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WakelockPlus.disable();
    _fullscreen.value = false;
    focusView?.requestFocus();
  }

  void toggleFullScreen() {
    _fullscreen.value = !_fullscreen.value;
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
      if (!auto || videoData.value!.next) {
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

  void _tapAction(int repeat, bool last) {
    if (repeat == 1 && last) {
      if (controls.value || paused.value) {
        toggle();
        showControls(controls.value);
      } else {
        showControls(true);
      }
    }
    if (repeat == 2 && last) {
      _lock.value = !lock.value;
      showControls(true);
    }
  }

  Future<void> showControls(bool show) async {
    _controls.value = show;
    _controlsTick = DateTime.now();
    var tick = _controlsTick;
    await Future.delayed(Durations.extralong4 * 5);
    if (tick != _controlsTick) return;
    if (paused.value) return;
    _enterFullScreen();
    if (lock.value) return;
    _controls.value = false;
  }

  void hideControls() {
    _controls.value = false;
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
        _paused.value = false;
        _stopwatch.start();
        break;
      case 'pause':
        _paused.value = true;
        _stopwatch.stop();
        _updateHistory();
        break;
      case 'stop':
        break;
      case 'current':
        _current.value = int.tryParse(event[1]) ?? 0;
        break;
      case 'meta':
        _length.value = int.tryParse(event[1]) ?? 1;
        _startWebVideo();
        _updateWebControl();
        _updateHistory();
        break;
      case 'ended':
        _paused.value = true;
        next(1, auto: true);
        break;
      case 'next':
        next(int.tryParse(event[1]) ?? 0);
        break;
      case 'buffered':
        _buffered.value = int.tryParse(event[1]) ?? 0;
        break;
      case 'speed':
        var speed = double.tryParse(event[1]) ?? 1.0;
        videoData.value?.speed = speed;
        break;
      case 'volume':
        var volume = double.tryParse(event[1]) ?? 1.0;
        videoData.value?.volume = volume;
        break;
      case 'mute':
        var mute = bool.tryParse(event[1]) ?? false;
        videoData.value?.mute = mute;
        break;
      default:
    }
  }

  void _updateWebControl() {
    webview?.callJsMethod('changeSpeed', [videoData.value?.speed ?? 1.00]);
    webview?.callJsMethod('changeVolume', [videoData.value?.volume ?? 1.00]);
    webview?.callJsMethod('muteVideo', [videoData.value?.mute ?? false]);
  }

  void _rewindAction(int repeat, bool last) {
    _seekTo(-1, repeat, last);
  }

  void _forwardAction(int repeat, bool last) {
    _seekTo(1, repeat, last);
  }

  void _seekTo(int offset, int repeat, bool last) {
    if (video.value == null) return;
    if (!last) {
      var s = {6: 1, 11: 2, 16: 5, 27: 10};
      var k = s.keys.skipWhile((e) => repeat >= e).firstOrNull ?? 0;
      var v = s[k] ?? 30;
      _seek.value += offset * v;
      showControls(true);
    } else {
      var cur = video.value!.value.position.inSeconds;
      var len = video.value!.value.duration.inSeconds;
      cur += seek.value;
      cur = cur.clamp(0, len);
      _seek.value = 0;
      _seekVideo(cur);
      showControls(true);
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
      var progress = videoData.value!.progress[ep.value].data;
      var pos = progress.current;
      var len = video.value?.value.duration.inSeconds ?? 0;
      var skip = videoData.value!.skip;
      pos = max(pos, skip);
      if (pos < len) await _seekVideo(pos);
    }
    _state.value = VideoState.ready;
    if (!paused.value) {
      _playVideo();
      showControls(true);
    }
  }

  void _startWebVideo() {
    var d = detail.value;
    if (d != null) {
      var progress = videoData.value!.progress[ep.value].data;
      var pos = progress.current;
      var skip = videoData.value!.skip;
      pos = max(pos, skip);
      if (pos < _length.value) {
        _current.value = pos;
        webview?.callJsMethod('seekVideo', ['$pos']);
      }
      webview?.callJsMethod('setFilename', ['${d.info.title}-${ep.value}']);
    }
    _state.value = VideoState.ready;
  }

  void _playVideo() async {
    if (state.value != VideoState.ready) return;
    _paused.value = false;
    _stopwatch.start();
    video.value?.play();
    showControls(controls.value);
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
    var cur = kIsWeb ? _current.value : video.value!.value.position.inSeconds;
    var len = kIsWeb ? _length.value : video.value!.value.duration.inSeconds;
    videoData.value?.progress[ep.value].data = VideoProgress(cur, cur, len);
    videoData.value?.title = detail.value?.info.title ?? '';
    videoData.value?.ep = ep.value;
    videoData.value?.datetime = DateTime.now();
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
