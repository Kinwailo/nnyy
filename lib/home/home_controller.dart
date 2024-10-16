import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/nnyy_data.dart';
import '../services/video_service.dart';

class HomeController {
  HomeController._() {
    NnyyData.data.addListener(reloadVideoList);
    NnyyData.videos.addListener(reloadVideoList);
  }

  static HomeController? _instance;
  static HomeController get i => _instance ??= HomeController._();

  final filterFocus = FocusNode(skipTraversal: true);
  final canPop = ValueNotifier(true);
  final videoList = ValueNotifier<List<VideoInfo>>([]);
  final error = ValueNotifier('');

  var _kind = VideoService.dianshijuPath;
  var _search = '';
  final _noMore = List.filled(3, false);
  final _page = List.filled(3, 0);
  final _param = List.generate(3, (_) => <String, dynamic>{});
  final _list = List.generate(3, (_) => <VideoInfo>[]);

  int get modeIndex => modeList.indexOf(NnyyData.data.mode);
  bool get noMore => _noMore[modeIndex];
  String get search => _search;

  static final modeList = [
    modeHistory,
    modeFilter,
    modeSearch,
  ];
  static const modeHistory = '記錄';
  static const modeFilter = '篩選';
  static const modeSearch = '搜尋';

  static final sortMap = {
    '時間': '',
    '人氣': 'click',
    '評分': 'rating',
  };
  static List<String> get sortList => sortMap.keys.toList();

  static final genreMap = {
    '全部': '',
    '劇情': 'ju-qing',
    '愛情': 'ai-qing',
    '喜劇': 'xi-ju',
    '懸疑': 'xuan-yi',
    '犯罪': 'fan-zui',
    '古裝': 'gu-zhuang',
    '奇幻': 'qi-huan',
    '驚悚': 'jing-song',
    '科幻': 'ke-huan',
    '家庭': 'jia-ting',
    '動作': 'dong-zuo',
    '歷史': 'li-shi',
    '青春': 'qing-chun',
    '搞笑': 'gao-xiao',
    '推理': 'tui-li',
    '戰爭': 'zhan-zheng',
    '人性': 'ren-xing',
    '女性': 'nv-xing',
    '同性': 'tong-xing',
    '武俠': 'wu-xia',
  };
  static List<String> get genreList => genreMap.keys.toList();

  static final countryMap = {
    '全部': '',
    '大陸': 'cn',
    '美國': 'us',
    '香港': 'hk',
    '台灣': 'tw',
    '日本': 'jp',
    '韓國': 'kr',
    '英國': 'gb',
    '法國': 'fr',
    '德國': 'de',
    '義大利': 'it',
    '西班牙': 'es',
    '印度': 'in',
    '泰國': 'th',
    '俄羅斯': 'ru',
  };
  static List<String> get countryList => countryMap.keys.toList();

  static Map<String, String> get yearMap => {
        '全部': '',
        ...{for (var v in yearList.skip(1).take(15)) v: v},
        yearList.last: 'lt__${yearList.elementAt(14)}',
      };
  static List<String> get yearList => [
        '全部',
        ...List<String>.generate(15, (i) => '${DateTime.now().year - i}'),
        '${DateTime.now().year - 14}之前',
      ];

  void searchVideo(String search) async {
    _kind = VideoService.searchPath;
    _search = search;
    reloadVideoList();
  }

  void clearSearch() async {
    _kind = VideoService.searchPath;
    _search = '';
    reloadVideoList();
  }

  void reloadVideoList() async {
    var param = switch (NnyyData.data.mode) {
      modeSearch => {'kind': _kind, 'q': _search},
      modeFilter => {
          'kind': VideoService.dianshijuPath,
          'ob': sortMap[NnyyData.data.sort],
          'genre': genreMap[NnyyData.data.genre],
          'country': countryMap[NnyyData.data.country],
          'year': yearMap[NnyyData.data.year],
        },
      String() => {'key': UniqueKey()},
    };
    if (!mapEquals(param, _param[modeIndex])) {
      _param[modeIndex] = param;
      _noMore[modeIndex] = NnyyData.data.mode == modeHistory ||
              (NnyyData.data.mode == modeSearch && _search.isEmpty)
          ? true
          : false;
      _page[modeIndex] = 0;
      _list[modeIndex].clear();
    }
    videoList.value = switch (NnyyData.data.mode) {
      modeHistory => loadHistory(),
      modeSearch when _search.isEmpty => [],
      String() => [..._list[modeIndex]],
    };
  }

  void moreVideoList() async {
    if (_noMore[modeIndex]) return;
    _page[modeIndex]++;
    var list = await loadVideoList();
    _noMore[modeIndex] = list.isEmpty;
    _list[modeIndex].addAll(list);
    videoList.value = [..._list[modeIndex]];
  }

  Future<List<VideoInfo>> loadVideoList() async {
    try {
      final param = {
        ..._param[modeIndex],
        if (_page[modeIndex] != 1) 'page': '${_page[modeIndex]}',
      };
      return await VideoService.i.getVideoList(param);
    } catch (e) {
      error.value = e.toString();
      return [];
    }
  }

  List<VideoInfo> loadHistory() {
    return NnyyData.videos.ids
        .map((e) => VideoInfo()
          ..id = e
          ..title = NnyyData.videos[e].title
          ..cover = VideoService.i.getVideoCover(e))
        .toList();
  }
}
