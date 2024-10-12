import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as parser;
import 'package:path/path.dart';

import '../conv/conv.dart';

class VideoInfo {
  int id = 0;
  String title = '';
  String cover = '';
  String country = '';
  int? year;
  double? rate;
}

class VideoDetail {
  VideoInfo info = VideoInfo();
  String director = '';
  String starring = '';
  String genre = '';
  String country = '';
  String alt = '';
  String intro = '';
  Map<String, String> eps = {};
}

extension UrlProxy on String {
  String get proxy {
    return !kIsWeb ? this : Uri.encodeFull('${VideoService.proxyUrl}$this');
  }
}

class VideoService {
  VideoService._();

  static const userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36';
  static const baseUrl = 'https://nnyy.in';
  static const dianshijuPath = '/dianshiju/';
  static const dianyingPath = '/dianying/';
  static const zongyiPath = '/zongyi/';
  static const dongmanPath = '/dongman/';
  static const searchPath = '/so';
  static const thumbPath = '/nnimg2/';
  static const imagePath = '/nnimg/';
  static const serverPath = '/_gp/';
  static const proxyUrl = 'https://cors.kinwailo.workers.dev/?';

  static VideoService? _instance;
  static VideoService get i => _instance ??= VideoService._();

  static final connectfail = Exception('連接網站失敗');
  static final respfail = Exception('網站回應異常');
  static final docfail = Exception('網站文件異常');

  final dio = Dio(BaseOptions(
      headers: kIsWeb ? null : {HttpHeaders.userAgentHeader: userAgent}));

  String getVideoCover(int id) {
    return '$baseUrl$thumbPath$id.jpg';
  }

  Future<List<VideoInfo>> getVideoList(Map<String, dynamic> param) async {
    final p = {...param};
    p.remove('kind');
    p.removeWhere((k, v) => v is String && v.isEmpty);
    final uri = Uri.parse('$baseUrl${param['kind']}');
    final url =
        Uri.https(uri.authority, uri.path, p.isEmpty ? null : p).toString();
    return _getVideoList(url);
  }

  Future<Response> _getResponse(String url) async {
    late Response resp;
    try {
      resp = await dio.get(url);
    } catch (e) {
      return Future.error(connectfail);
    }
    if (resp.statusCode != 200) return Future.error(connectfail);
    return resp;
  }

  Future<List<VideoInfo>> _getVideoList(String url) async {
    final resp = await _getResponse(url.proxy);
    final contentType = resp.headers.value(Headers.contentTypeHeader);
    if (contentType == null) return Future.error(respfail);
    if (!contentType.startsWith('text/html')) return Future.error(respfail);

    final doc = parser.HtmlParser(resp.data.toString()).parse();

    try {
      final elem = doc
          .getElementsByClassName('lists-content')
          .firstWhere((e) => e.classes.length == 1)
          .children
          .single;
      final list = elem.children.map((e) {
        final e0 = e.children[0];
        final id = int.parse(basenameWithoutExtension(e0.attributes['href']!));
        final e1 = e0.getElementsByClassName('countrie').single;
        final year = int.parse(e1.children[0].text);
        final country = e1.children[1].text;
        final title = e.children[1].children[0].text;
        final rate = double.tryParse(e.children[2].children[1].text);
        return VideoInfo()
          ..id = id
          ..title = title.conv
          ..cover = '$baseUrl$thumbPath$id.jpg'
          ..country = country.conv
          ..year = year
          ..rate = rate;
      }).toList();
      return list;
    } catch (_) {
      return Future.error(docfail);
    }
  }

  Future<VideoDetail> getVideoDetail(VideoInfo info) async {
    final resp =
        await _getResponse('$baseUrl$dianshijuPath${info.id}.html'.proxy);
    if (resp.statusCode != 200) return Future.error(connectfail);

    final contentType = resp.headers.value(Headers.contentTypeHeader);
    if (contentType == null) return Future.error(respfail);
    if (!contentType.startsWith('text/html')) return Future.error(respfail);

    final doc = parser.HtmlParser(resp.data.toString()).parse();
    final detail = VideoDetail()..info = info;

    try {
      var elem = doc.getElementsByClassName('product-excerpt');
      detail.director =
          elem[0].children[0].children.map((e) => e.text).join(', ').conv;
      detail.starring =
          elem[1].children[0].children.map((e) => e.text).join(', ').conv;
      detail.genre =
          elem[2].children[0].children.map((e) => e.text).join(', ').conv;
      detail.country =
          elem[3].children[0].children.map((e) => e.text).join(', ').conv;
      detail.alt = elem[4].children[0].text.conv;
      detail.intro = elem[5].children[0].text.conv;

      elem = doc.getElementById('eps-ul')?.children ?? [];
      detail.eps = {
        for (var e in elem.reversed)
          e.children[0].text.conv: e.attributes['ep_slug'] ?? ''
      };
      return detail;
    } catch (_) {
      return Future.error(docfail);
    }
  }

  Future<Map<String, String>> getVideoSite(VideoInfo info, String ep) async {
    final resp = await _getResponse('$baseUrl$serverPath${info.id}/$ep'.proxy);
    if (resp.statusCode != 200) return Future.error(connectfail);

    final contentType = resp.headers.value(Headers.contentTypeHeader);
    if (contentType == null) return Future.error(respfail);
    if (!contentType.startsWith('text/html')) return Future.error(respfail);

    final names = <String, int>{};
    String getName(String site) {
      site = site.substring(0, 2).toUpperCase();
      final i = names.update(site, (i) => ++i, ifAbsent: () => 1);
      return '$site${i == 1 ? '' : i}';
    }

    try {
      final list = const JsonCodec().decode(resp.data)['video_plays'] as List;
      final sites = {
        for (var e in list.cast<Map>())
          getName(e['src_site']!): '${e['play_data']!}'
      };
      return sites;
    } catch (e) {
      return Future.error(docfail);
    }
  }
}
