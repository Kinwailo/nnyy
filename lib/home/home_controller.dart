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
  final _noMore = List.filled(modeList.length, false);
  final _page = List.filled(modeList.length, 0);
  final _param = List.generate(modeList.length, (_) => <String, dynamic>{});
  final _list = List.generate(modeList.length, (_) => <VideoInfo>[]);

  bool get noMore => _noMore[modeIndex];
  String get search => _search;

  static final modeList = [
    modeHistory,
    ...kindMap.keys,
    modeSearch,
  ];
  static const modeHistory = '記錄';
  static const modeSearch = '搜尋';
  static int get modeIndex => modeList.indexOf(NnyyData.data.mode);

  static final kindMap = {
    '劇集': VideoService.dianshijuPath,
    '電影': VideoService.dianyingPath,
    '綜藝': VideoService.zongyiPath,
    '動畫': VideoService.dongmanPath,
  };
  static List<String> get kindList => kindMap.keys.toList();

  static final sortMap = {
    '時間': '',
    '人氣': 'click',
    '評分': 'rating',
  };
  static List<String> get sortList => sortMap.keys.toList();

  static final genreMap = {
    '全部': '',
//
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
//
    '恐怖': 'kong-bu',
    '傳記': 'chuan-ji',
    '冒險': 'mao-xian',
    '文藝': 'wen-yi',
    '溫情': 'wen-qing',
//
    '真人秀': 'zhen-ren-xiu',
    '脫口秀': 'tuo-kou-xiu',
    '音樂': 'yin-le',
    '美食': 'mei-shi',
    '文化': 'wen-hua',
    '歌舞': 'ge-wu',
    '選秀': 'xuan-xiu',
//
    '兒童': 'er-tong',
    '短片': 'duan-pian',
    '熱血': 're-xue',
    '成長': 'cheng-zhang',
    '童年': 'tong-nian',
    '治癒': 'zhi-yu',
    '經典': 'jing-dian',
  };
  static final _genreList = {
    '劇集': '全部 劇情 愛情 喜劇 懸疑 犯罪 古裝 奇幻 驚悚 科幻 家庭 動作 歷史 青春 搞笑 推理 戰爭 人性 女性 同性 武俠',
    '電影': '全部 劇情 喜劇 愛情 動作 驚悚 犯罪 懸疑 恐怖 科幻 奇幻 傳記 戰爭 家庭 冒險 人性 青春 歷史 文藝 溫情 搞笑',
    '綜藝': '全部 真人秀 脫口秀 音樂 搞笑 喜劇 美食 溫情 文化 歌舞 青春 愛情 家庭 選秀',
    '動畫': '全部 喜劇 奇幻 冒險 劇情 科幻 動作 搞笑 愛情 家庭 兒童 短片 溫情 懸疑 青春 熱血 成長',
  };
  static List<String> get genreList =>
      _genreList[NnyyData.data.mode]?.split(' ') ?? ['全部'];

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
  static final _countryList = {
    '劇集': '全部 大陸 美國 香港 台灣 日本 韓國 英國 法國 德國 義大利 西班牙 印度 泰國 俄羅斯',
    '電影': '全部 大陸 美國 香港 台灣 日本 韓國 英國 法國 德國 義大利 西班牙 印度 泰國 俄羅斯',
    '綜藝': '全部 大陸 美國 香港 台灣 日本 韓國 英國',
    '動畫': '全部 大陸 美國 香港 台灣 日本 韓國 英國 法國',
  };
  static List<String> get countryList =>
      _countryList[NnyyData.data.mode]?.split(' ') ?? ['全部'];

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
    if (kindMap.containsKey(NnyyData.data.mode)) {
      if (!genreList.contains(NnyyData.data.genre)) {
        NnyyData.data.genre = genreMap.keys.first;
      }
      if (!countryList.contains(NnyyData.data.country)) {
        NnyyData.data.country = countryMap.keys.first;
      }
    }
    var param = switch (NnyyData.data.mode) {
      modeHistory => {'key': UniqueKey()},
      modeSearch => {'kind': _kind, 'q': _search},
      String() => {
          'kind': kindMap[NnyyData.data.mode],
          'ob': sortMap[NnyyData.data.sort],
          'genre': genreMap[NnyyData.data.genre],
          'country': countryMap[NnyyData.data.country],
          'year': yearMap[NnyyData.data.year],
        },
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
