import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

import '../home/home_controller.dart';
import 'data_store.dart';
import 'google_drive_storage.dart';

class NnyyData extends ChangeNotifier {
  NnyyData._({required this.cloud}) {
    if (cloud) return;
    DataStore.store(name).addListener(notifyListeners);
  }

  static const String name = 'preferences';
  static final _googleDriveStorage = GoogleDriveStorage();

  static NnyyData? _data;
  static NnyyData get data => _data ??= NnyyData._(cloud: false);

  final bool cloud;
  static final _syncRequired = ValueNotifier(false);
  static ValueListenable<bool> get syncRequired => _syncRequired;
  static final _lostConnection = ValueNotifier(false);
  static ValueListenable<bool> get lostConnection => _lostConnection;

  late final _mode =
      StoreValue(name, 'mode', HomeController.modeFilter, cloud: cloud);
  late final _sort =
      StoreValue(name, 'sort', HomeController.sortList.first, cloud: cloud);
  late final _kind =
      StoreValue(name, 'kind', HomeController.kindList.first, cloud: cloud);
  late final _genre =
      StoreValue(name, 'genre', HomeController.genreList.first, cloud: cloud);
  late final _country = StoreValue(
      name, 'country', HomeController.countryList.first,
      cloud: cloud);
  late final _year =
      StoreValue(name, 'year', HomeController.yearList.first, cloud: cloud);
  late final _sites = StoreValueFrom(name, 'sites', <String, int>{},
      cloud: cloud,
      notify: false,
      onGet: (Map v) => Map<String, int>.from(v),
      onSet: (v) => v);
  late final signInData = StoreValueFrom(name, 'sign', <String, String>{},
      cloud: cloud, notify: false, onGet: (String v) {
    return Map<String, String>.from(
        json.decode(utf8.decode(gzip.decode(base64.decode(v)))));
  }, onSet: (v) {
    return base64.encode(gzip.encode(utf8.encode(json.encode(v))));
  });

  String get mode => _mode.value;
  set mode(String v) => _mode.value = v;
  String get sort => _sort.value;
  set sort(String v) => _sort.value = v;
  String get kind => _kind.value;
  set kind(String v) => _kind.value = v;
  String get genre => _genre.value;
  set genre(String v) => _genre.value = v;
  String get country => _country.value;
  set country(String v) => _country.value = v;
  String get year => _year.value;
  set year(String v) => _year.value = v;

  static final videos = NnyyVideoCollection._();

  static void init() {
    _googleDriveStorage.addListener(() {
      if (_googleDriveStorage.isLoggedIn) _sync();
    });
    DataStore.cloud = _googleDriveStorage;
    DataStore.changedSinceSync.addListener(() => _syncRequired.value = DataStore
        .changedSinceSync.value
        .whereNot((e) => e == name)
        .whereNot((e) => e == 'sign')
        .isNotEmpty);

    DataStore.list()
        .where((e) => extension(e) == NnyyVideoData.name)
        .map((e) => basenameWithoutExtension(e))
        .map((e) => int.tryParse(e))
        .whereNotNull()
        .map((e) => videos[e])
        .where((e) => e.isOutdated)
        .forEach((e) => e.delete());
    data.notifyListeners();
  }

  static void saveAll() {
    data.save();
    for (var v in videos.values) {
      v.saveAll();
    }
  }

  static void autoSignInCloud() {
    _googleDriveStorage.signInSilently();
  }

  static Widget cloudAvatar() {
    return _googleDriveStorage.signInAvatar();
  }

  static Future<bool> syncToCloud() async {
    if (!_googleDriveStorage.isLoggedIn) return false;
    if (!_syncRequired.value) return false;
    if (!await _googleDriveStorage.checkAccess()) {
      _lostConnection.value = true;
      return false;
    }
    await _sync();
    return true;
  }

  static Future<void> _sync() async {
    await DataStore.loadOnCloud();
    for (var n in {...DataStore.list(), ...DataStore.list(cloud: true)}) {
      if (n == name) await data.sync();
      if (extension(n) == NnyyVideoData.name) {
        final id = int.tryParse(basenameWithoutExtension(n));
        if (id != null) await videos[id].sync();
      }
    }
    await DataStore.saveOnCloud();
  }

  void addSiteDuration(String site, int sec) {
    final value = _sites.value;
    value.update(site, (v) => v += sec, ifAbsent: () => sec);
    _sites.value = {...value};
  }

  Map<String, String> sortSiteMap(Map<String, String> map) {
    var k = map.keys.sorted(
        (a, b) => (_sites.value[b] ?? 0).compareTo((_sites.value[a] ?? 0)));
    return {for (var e in k) e: map[e]!};
  }

  void save() {
    DataStore.store(name).save();
  }

  Future<void> sync() async {}
}

class NnyyVideoCollection extends ChangeNotifier {
  NnyyVideoCollection._();

  final _videos = <int, NnyyVideoData>{};

  NnyyVideoData operator [](int id) => _videos.putIfAbsent(id,
      () => NnyyVideoData._(id, cloud: false)..addListener(notifyListeners));
  Map<int, NnyyVideoData> get _saved =>
      {for (var v in _videos.values.where(_isSaved)) v.id: v};
  bool _isSaved(NnyyVideoData data) => data.fav || data.progress.isNotEmpty;

  Iterable<NnyyVideoData> get values => _saved.values;
  Iterable<int> get ids => values
      .sorted((a, b) => a.fav == b.fav
          ? b.datetime.compareTo(a.datetime)
          : a.fav
              ? -1
              : 1)
      .map((e) => e.id);
}

class NnyyVideoData extends ChangeNotifier {
  NnyyVideoData._(this.id, {required this.cloud}) {
    DataStore.store('$id$name').addListener(notifyListeners);
  }

  static const String name = '.data';

  final int id;
  final bool cloud;

  late final _title = StoreValue('$id$name', 'title', '', cloud: cloud);
  late final _ep = StoreValue('$id$name', 'ep', '', cloud: cloud);
  late final _fav = StoreValue('$id$name', 'fav', false, cloud: cloud);
  late final _next = StoreValue('$id$name', 'next', true, cloud: cloud);
  late final _skip = StoreValue('$id$name', 'skip', 0, cloud: cloud);
  late final _reverse = StoreValue('$id$name', 'reverse', false, cloud: cloud);

  late final _speed = StoreValue('$id$name', 'speed', 1.0, cloud: cloud);
  late final _volume = StoreValue('$id$name', 'volume', 1.0, cloud: cloud);
  late final _mute = StoreValue('$id$name', 'mute', false, cloud: cloud);

  late final _datetime = StoreValueFrom('$id$name', 'datetime', DateTime(2000),
      cloud: cloud,
      onSet: (v) => v.toString(),
      onGet: (String v) => DateTime.tryParse(v) ?? DateTime(2000));

  String get title => _title.value;
  set title(String v) => _title.value = v;
  String get ep => _ep.value;
  set ep(String v) => _ep.value = v;
  bool get fav => _fav.value;
  set fav(bool v) => _fav.value = v;
  bool get next => _next.value;
  set next(bool v) => _next.value = v;
  int get skip => _skip.value;
  set skip(int v) => _skip.value = v;
  bool get reverse => _reverse.value;
  set reverse(bool v) => _reverse.value = v;

  double get speed => _speed.value;
  set speed(double v) => _speed.value = v;
  double get volume => _volume.value;
  set volume(double v) => _volume.value = v;
  bool get mute => _mute.value;
  set mute(bool v) => _mute.value = v;

  DateTime get datetime => _datetime.value;
  set datetime(DateTime v) => _datetime.value = v;

  late final progress = NnyyProgressCollection._(id, cloud: cloud);

  bool get isOutdated => DateTime.now().difference(datetime).inDays > 30;

  void removeFav() {
    if (progress.isEmpty) delete();
  }

  void save() {
    DataStore.store('$id$name').save();
  }

  void saveAll() {
    DataStore.store('$id$name').save();
    DataStore.store('$id${NnyyProgressData.name}').save();
  }

  Future<void> sync() async {
    final cloudData = NnyyVideoData._(id, cloud: true);
    if (cloudData.isOutdated && !cloudData.fav) {
      DataStore.store('$id$name').delete(cloud: true);
      DataStore.store('$id${NnyyProgressData.name}').delete(cloud: true);
      return;
    }

    final toCloud = datetime.isAfter(cloudData.datetime);
    final from = toCloud ? this : cloudData;
    final to = toCloud ? cloudData : this;
    to.title = from.title;
    to.ep = from.ep;
    to.fav = from.fav;
    to.next = from.next;
    to.skip = from.skip;
    to.reverse = from.reverse;
    to.speed = from.speed;
    to.volume = from.volume;
    to.mute = from.mute;
    to.datetime = from.datetime;

    final cloudProgress = cloudData.progress;
    final eps = {...progress.eps, ...cloudProgress.eps};
    for (var ep in eps) {
      final from = toCloud ? progress[ep] : cloudProgress[ep];
      final to = toCloud ? cloudProgress[ep] : progress[ep];
      to.data = to.data.update(from.data);
    }

    if ((toCloud ? cloudProgress : progress).isEmpty) {
      if (!to.fav) DataStore.store('$id$name').delete(cloud: toCloud);
      DataStore.store('$id${NnyyProgressData.name}').delete(cloud: toCloud);
    }
  }

  void delete() {
    if (!fav) DataStore.store('$id$name').delete();
    progress.clear();
    DataStore.store('$id${NnyyProgressData.name}').delete();
    notifyListeners();
  }
}

class NnyyProgressCollection extends ChangeNotifier {
  NnyyProgressCollection._(this.id, {required this.cloud});

  final int id;
  final bool cloud;
  final _progress = <String, NnyyProgressData>{};

  NnyyProgressData operator [](String ep) => _progress.putIfAbsent(
      ep,
      () => NnyyProgressData._(id, ep, cloud: cloud)
        ..addListener(notifyListeners));
  Iterable<String> get eps =>
      DataStore.store('$id${NnyyProgressData.name}').keys(cloud: cloud);

  bool get isEmpty => _progress.values.every((e) => e.data.isZero);
  bool get isNotEmpty => !isEmpty;

  void clear() {
    _progress.clear();
    notifyListeners();
  }
}

class VideoProgress {
  VideoProgress(this.current, this.latest, this.length);

  static final VideoProgress zero = VideoProgress(0, 0, 1);

  final int current;
  final int latest;
  final int length;

  double get value => latest / length;
  bool get isZero =>
      current == zero.current && latest == zero.latest && length == zero.length;

  VideoProgress update(VideoProgress other) {
    var latest = this.latest < other.latest ? other.latest : this.latest;
    var length = this.length < other.length ? other.length : this.length;
    length = max(1, length);
    return VideoProgress(other.current, latest, length);
  }
}

class NnyyProgressData extends ChangeNotifier {
  NnyyProgressData._(this.id, this.ep, {required this.cloud}) {
    DataStore.store('$id$name').addListener(notifyListeners);
  }

  static const String name = '.progress';

  final int id;
  final String ep;
  final bool cloud;

  late final _data = StoreValueFrom('$id$name', ep, VideoProgress.zero,
      cloud: cloud,
      onSet: (v) => [v.current, v.latest, v.length],
      onGet: (List v) => VideoProgress(v[0], v[1], v[2]));

  VideoProgress get data => _data.value;
  set data(VideoProgress v) => _data.value = _data.value.update(v);
}
