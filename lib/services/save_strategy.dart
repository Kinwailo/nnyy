import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:universal_html/html.dart" as html;

import '../home/home_controller.dart';
import 'nnyy_data.dart';

class NavigatorChangeObserver extends NavigatorObserver with ChangeNotifier {
  @override
  void didPop(Route route, Route? previousRoute) => notifyListeners();
  @override
  void didPush(Route route, Route? previousRoute) => notifyListeners();
  @override
  void didRemove(Route route, Route? previousRoute) => notifyListeners();
  @override
  void didReplace({Route? newRoute, Route? oldRoute}) => notifyListeners();
}

class SaveStrategy implements PopEntry {
  SaveStrategy._();

  static SaveStrategy? _instance;
  static SaveStrategy get i => _instance ??= SaveStrategy._();

  static final navigatorChangeObserver = NavigatorChangeObserver();

  ModalRoute<dynamic>? _route;
  bool? _autoSyncPending;
  final _syncingOnExit = ValueNotifier(false);

  ValueListenable<bool> get syncingOnExit => _syncingOnExit;

  @override
  final ValueNotifier<bool> canPopNotifier = ValueNotifier(false);
  @override
  late final onPopInvoked = _popInvoked;

  static void _save() {
    NnyyData.saveAll();
  }

  static Future<bool> _sync() async {
    _save();
    return await NnyyData.syncToCloud();
  }

  static void init() {
    navigatorChangeObserver.addListener(_save);
    AppLifecycleListener(
      onHide: () {
        final action = kIsWeb
            ? _sync
            : switch (defaultTargetPlatform) {
                TargetPlatform.android ||
                TargetPlatform.iOS ||
                TargetPlatform.fuchsia =>
                  null,
                TargetPlatform.windows ||
                TargetPlatform.macOS ||
                TargetPlatform.linux =>
                  _save,
              };
        action?.call();
      },
      onPause: () {
        final action = kIsWeb
            ? null
            : switch (defaultTargetPlatform) {
                TargetPlatform.android ||
                TargetPlatform.iOS ||
                TargetPlatform.fuchsia =>
                  _sync,
                TargetPlatform.windows ||
                TargetPlatform.macOS ||
                TargetPlatform.linux =>
                  null,
              };
        action?.call();
      },
      onExitRequested: () async {
        final action = kIsWeb
            ? false
            : switch (defaultTargetPlatform) {
                TargetPlatform.android ||
                TargetPlatform.iOS ||
                TargetPlatform.fuchsia =>
                  false,
                TargetPlatform.windows ||
                TargetPlatform.macOS ||
                TargetPlatform.linux =>
                  true,
              };
        if (action) {
          i._syncOnExit(exit: true);
          return AppExitResponse.cancel;
        } else {
          return AppExitResponse.exit;
        }
      },
    );
    if (kIsWeb) {
      html.window.onBeforeUnload.listen((e) {
        if (e is! html.BeforeUnloadEvent) return;
        if (NnyyData.syncRequired.value) {
          e.preventDefault();
          e.returnValue = 'Data is not yet sync to cloud.';
          i._syncOnExit();
        }
      });
    }
    NnyyData.syncRequired.addListener(i._autoSync);
  }

  void registerPopEntry(ModalRoute? route) {
    if (route != _route) {
      _route?.unregisterPopEntry(this);
      _route = route;
      _route?.registerPopEntry(this);
    }
  }

  void _popInvoked(bool didPop) {
    if (HomeController.i.canPop.value) i._syncOnExit(pop: true);
  }

  Future<void> _autoSync() async {
    if (!NnyyData.syncRequired.value) return;
    if (_autoSyncPending != null) {
      _autoSyncPending = true;
      return;
    }
    while (_autoSyncPending != false) {
      _autoSyncPending = false;
      if (await _sync()) await Future.delayed(const Duration(minutes: 5));
    }
    _autoSyncPending = null;
  }

  Future<void> _syncOnExit({bool pop = false, bool exit = false}) async {
    if (i._syncingOnExit.value) return;
    i._syncingOnExit.value = true;
    await _sync();
    if (NnyyData.lostConnection.value) {
      await Future.delayed(Durations.extralong4);
    }
    i._syncingOnExit.value = false;
    canPopNotifier.value = true;
    if (pop) SystemNavigator.pop();
    if (exit) ServicesBinding.instance.exitApplication(AppExitType.required);
  }
}
