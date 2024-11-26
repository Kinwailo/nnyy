import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import "package:universal_html/html.dart" as html;

class DataStore extends ChangeNotifier {
  DataStore._(this.name) {
    _load();
  }

  static String ext = '.json';
  static String customPath = kIsWeb
      ? relative(Uri.base.toString(), from: rootPrefix(current))
      : kDebugMode
          ? current
          : dirname(Platform.resolvedExecutable);

  final String name;
  static final Map<String, DataStore> _store = {};

  static final _LocalStorage _local = kIsWeb ? _StorageHtml() : _StorageIO();
  static final List<String> _localListCache = [];
  final Map<String, dynamic> _localData = {};
  bool _changed = false;

  static CloudStorage? _cloud;
  static final Map<String, Map<String, dynamic>> _cloudData = {};
  static final _changedSinceSync = ValueNotifier(<String>{});

  String get path => '${join(customPath, name)}$ext';
  static set cloud(CloudStorage v) => _cloud = v;
  static bool get isCloudReady => _cloud?.isLoggedIn == true;
  static ValueListenable<Set<String>> get changedSinceSync => _changedSinceSync;

  static DataStore store(String name) {
    return _store.putIfAbsent(name, () => DataStore._(name));
  }

  static List<String> list({bool cloud = false}) {
    if (cloud) {
      if (!isCloudReady) return [];
      return _cloudData.keys.toList();
    } else {
      if (_localListCache.isEmpty) {
        _localListCache.addAll(_local.list(customPath, ext));
      }
      return {..._localListCache, ..._store.keys}.toList();
    }
  }

  Map<String, dynamic> _getData({bool cloud = false}) {
    return cloud ? _cloudData.putIfAbsent(name, () => {}) : _localData;
  }

  Iterable<String> keys({bool cloud = false}) {
    return _getData(cloud: cloud).keys;
  }

  void remove(String key, {bool cloud = false}) {
    _getData(cloud: cloud).remove(key);
  }

  T? get<T>(String key, {bool cloud = false}) {
    return _getData(cloud: cloud)[key] as T?;
  }

  void set(String key, dynamic value,
      {bool cloud = false, bool notify = true}) {
    if (value == get(key, cloud: cloud)) return;
    if (!cloud) {
      _changed = true;
      if (isCloudReady) {
        _changedSinceSync.value = {..._changedSinceSync.value, name};
      }
    }
    _getData(cloud: cloud)[key] = value;
    if (!cloud && notify) notifyListeners();
  }

  void _load() {
    final data = _local.read(path);
    _localData.addAll(data);
  }

  void save() {
    if (_changed) {
      _changed = false;
      _local.write(path, _localData);
    }
  }

  void delete({bool cloud = false}) {
    if (cloud) {
      _cloudData.remove(name);
    } else {
      _localData.clear();
      _store.remove(path);
      _local.delete(path);
      notifyListeners();
    }
  }

  static void resetSyncState() {
    _changedSinceSync.value = {};
  }

  static Future<void> loadOnCloud() async {
    if (!isCloudReady) return;
    final data = await _cloud!.read();
    _cloudData.clear();
    _cloudData.addAll(data);
    _changedSinceSync.value = {};
  }

  static Future<void> saveOnCloud() async {
    if (!isCloudReady) return;
    _changedSinceSync.value = {};
    var data = {
      for (var e in _cloudData.entries.where((e) => e.value.isNotEmpty))
        e.key: e.value
    };
    await _cloud!.write(data);
  }

  static Future<void> deleteOnCloud() async {
    if (!isCloudReady) return;
    _cloudData.clear();
    await _cloud!.delete();
  }
}

abstract class _LocalStorage {
  List<String> list(String path, String ext);
  Map<String, dynamic> read(String path);
  void write(String path, Map data);
  void delete(String path);
}

abstract class CloudStorage implements ChangeNotifier {
  bool get isLoggedIn;
  Future<Map<String, Map<String, dynamic>>> read();
  Future<void> write(Map<String, Map<String, dynamic>> data);
  Future<void> delete();
}

class _StorageIO extends _LocalStorage {
  @override
  List<String> list(String path, String ext) {
    return Directory(path)
        .listSync()
        .where((e) => extension(e.path) == ext)
        .map((e) => basenameWithoutExtension(e.path))
        .toList();
  }

  @override
  Map<String, dynamic> read(String path) {
    final data = <String, dynamic>{};
    final file = File(path);
    if (!file.existsSync()) return data;

    final length = file.lengthSync();
    final buffer = Uint8List(length);
    final access = file.openSync(mode: FileMode.read);
    access.readIntoSync(buffer);
    access.closeSync();
    try {
      data.addAll(json.decode(utf8.decode(buffer)));
    } catch (e) {
      debugPrint(e.toString());
    }
    return data;
  }

  @override
  void write(String path, Map data) {
    final file = File(path);
    final buffer = utf8.encode(json.encode(data));
    final access = file.openSync(mode: FileMode.append);
    access.lockSync();
    access.setPositionSync(0);
    access.writeFromSync(buffer);
    access.truncateSync(buffer.length);
    access.unlockSync();
    access.closeSync();
  }

  @override
  void delete(String path) {
    final file = File(path);
    if (file.existsSync()) file.deleteSync();
  }
}

class _StorageHtml extends _LocalStorage {
  @override
  List<String> list(String path, String ext) {
    return html.window.localStorage.keys.map((e) => basename(e)).toList();
  }

  @override
  Map<String, dynamic> read(String path) {
    final data = <String, dynamic>{};
    final text = html.window.localStorage[withoutExtension(path)];
    try {
      if (text != null) data.addAll(json.decode(text));
    } catch (e) {
      debugPrint(e.toString());
    }
    return data;
  }

  @override
  void write(String path, Map data) {
    final text = json.encode(data);
    html.window.localStorage[withoutExtension(path)] = text;
  }

  @override
  void delete(String path) {
    html.window.localStorage.remove(withoutExtension(path));
  }
}

class StoreValue<T> extends ValueNotifier<T> {
  StoreValue(
    this.store,
    this.key,
    this.defaultValue, {
    this.cloud = false,
    this.notify = true,
  }) : super(defaultValue);

  final String store;
  final String key;
  final T defaultValue;
  final bool cloud;
  final bool notify;

  bool get isDefault => value == defaultValue;

  @override
  T get value =>
      DataStore.store(store).get<T>(key, cloud: cloud) ?? defaultValue;

  @override
  set value(T newValue) {
    if (value == newValue) return;
    DataStore.store(store).set(key, newValue, cloud: cloud, notify: notify);
    if (notify) notifyListeners();
  }

  void save() {
    DataStore.store(store).save();
  }
}

class StoreValueFrom<T, R> extends StoreValue<T> {
  StoreValueFrom(
    super.store,
    super.key,
    super.defaultValue, {
    super.notify = true,
    super.cloud = false,
    required this.onSet,
    required this.onGet,
  });

  final R Function(T value) onSet;
  final T Function(R value) onGet;

  @override
  T get value {
    final v = DataStore.store(store).get<R>(key, cloud: cloud);
    return v == null ? defaultValue : onGet(v);
  }

  @override
  set value(T newValue) {
    if (value == newValue) return;
    DataStore.store(store)
        .set(key, cloud: cloud, notify: notify, onSet(newValue));
    if (notify) notifyListeners();
  }
}
