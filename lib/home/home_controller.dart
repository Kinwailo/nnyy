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

  var _noMore = false;
  var _page = 0;
  var _kind = VideoService.dianshijuPath;
  var _search = '';
  var _param = <String, dynamic>{};
  final _list = <VideoInfo>[];

  bool get noMore => _noMore;

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

  void reloadVideoList() async {
    var param = _search.isNotEmpty
        ? {'kind': _kind, 'q': _search}
        : {
            'kind': VideoService.dianshijuPath,
            'ob': sortMap[NnyyData.data.sort],
            'genre': genreMap[NnyyData.data.genre],
            'country': countryMap[NnyyData.data.country],
            'year': yearMap[NnyyData.data.year],
          };
    if (!mapEquals(param, _param)) {
      _param = param;
      _noMore = false;
      _page = 0;
      _search = '';
      _list.clear();
    }
    videoList.value = NnyyData.data.history ? loadHistory() : [..._list];
  }

  void moreVideoList() async {
    if (_noMore) return;
    _page++;
    var list = await loadVideoList();
    if (NnyyData.data.history) return;
    _noMore = list.isEmpty;
    _list.addAll(list);
    videoList.value = [..._list];
  }

  Future<List<VideoInfo>> loadVideoList() async {
    try {
      final param = {
        ..._param,
        if (_page != 1) 'page': '$_page',
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
