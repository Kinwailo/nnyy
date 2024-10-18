import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_dartio/google_sign_in_dartio.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis/drive/v3.dart';

import 'google_client_id.dart';
import 'data_store.dart';
import 'nnyy_data.dart';
import '../widgets/google_button_web.dart'
    if (dart.library.io) '../widgets/google_button_stub.dart';

class _GoogleSignInStore extends Store {
  final data = NnyyData.data.signInData;
  @override
  String? get(String key) => data.value[key];
  @override
  void set(String key, String value) =>
      data.value = {...data.value, key: value};
  @override
  void remove(String key) => data.value = {...data.value..remove(key)};
  @override
  void clearAll() => data.value = {};
}

class GoogleDriveStorage extends CloudStorage with ChangeNotifier {
  static const List<String> _scopes = [DriveApi.driveAppdataScope];
  static const String _filename = 'data.json';

  static String? get _clientId {
    return kIsWeb
        ? clientIdWeb
        : switch (defaultTargetPlatform) {
            TargetPlatform.android || TargetPlatform.fuchsia => null,
            TargetPlatform.iOS || TargetPlatform.macOS => clientIdiOS,
            TargetPlatform.windows || TargetPlatform.linux => clientIdDesktop,
          };
  }

  final GoogleSignIn _googleSignIn =
      GoogleSignIn(clientId: _clientId, scopes: _scopes);
  GoogleSignInAccount? _user;
  DriveApi? _driveApi;
  String? _error;
  final _syncing = ValueNotifier(false);

  GoogleSignInAccount? get user => _user;
  String? get error => _error;
  ValueListenable<bool> get syncing => _syncing;

  GoogleDriveStorage() {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      GoogleSignInDart.register(
        clientId: _clientId!,
        exchangeEndpoint: 'https://auth.kinwailo.workers.dev/',
        store: _GoogleSignInStore(),
      );
    }
    _googleSignIn.onCurrentUserChanged.listen((account) async {
      _driveApi = null;
      _user = account;
      if (account == null) {
        notifyListeners();
        return;
      }
      bool auth = true;
      if (kIsWeb) auth = await _checkAccess();
      if (auth) {
        try {
          final client = await _googleSignIn.authenticatedClient();
          _driveApi = DriveApi(client!);
        } catch (e) {
          _error = e.toString();
          auth = false;
        }
      }
      if (!auth) await signOut();
      if (auth) notifyListeners();
    });
  }

  Future<bool> _checkAccess() async {
    var auth = await _googleSignIn.canAccessScopes(_scopes);
    if (!auth) auth = await _googleSignIn.requestScopes(_scopes);
    return auth;
  }

  Widget circleAvatar() {
    return ListenableBuilder(
      listenable: _syncing,
      builder: (_, __) => user == null
          ? const Icon(Icons.account_box, size: 32)
          : Stack(
              children: [
                GoogleUserCircleAvatar(identity: user!),
                if (_syncing.value)
                  const Positioned(
                    right: 0,
                    bottom: 0,
                    child: SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget signInAvatar() {
    return ListenableBuilder(
      listenable: this,
      builder: (_, __) => user == null
          ? kIsWeb
              ? googleSignInCircle()
              : InkWell(
                  onTap: signIn,
                  borderRadius: BorderRadius.circular(32),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: circleAvatar(),
                  ),
                )
          : InkWell(
              onTap: signOut,
              borderRadius: BorderRadius.circular(32),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: circleAvatar(),
              ),
            ),
    );
  }

  Widget signInButton() {
    return ListenableBuilder(
      listenable: this,
      builder: (_, __) => user == null
          ? kIsWeb
              ? googleSignInButton()
              : ElevatedButton(
                  onPressed: signIn, child: const Text('Sign in with Google'))
          : ElevatedButton(onPressed: signOut, child: const Text('Sign out')),
    );
  }

  Future<void> signInSilently() async {
    _googleSignIn.signInSilently();
  }

  Future<void> signIn() async {
    try {
      _error = null;
      await _googleSignIn.signIn();
    } catch (e) {
      _error = e.toString();
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.disconnect();
  }

  @override
  bool get isLoggedIn => user != null;

  Future<String?> _getFileId() async {
    if (_driveApi == null) return null;
    var fileList = await _driveApi!.files.list(
      q: 'name="$_filename"',
      supportsAllDrives: false,
      spaces: 'appDataFolder',
      $fields: 'files(id)',
    );
    var id = fileList.files?.firstOrNull?.id;
    id ??= (await _driveApi!.files
            .create(File(name: _filename, parents: ['appDataFolder'])))
        .id;
    return id;
  }

  @override
  Future<Map<String, Map<String, dynamic>>> read() async {
    if (!await _checkAccess()) return {};

    _syncing.value = true;
    try {
      final id = await _getFileId();
      if (_driveApi == null || id == null) return {};

      final data = <String, Map<String, dynamic>>{};
      try {
        final file = await _driveApi!.files
            .get(id, downloadOptions: DownloadOptions.fullMedia) as Media;
        final stream =
            const JsonDecoder().bind(const Utf8Decoder().bind(file.stream));
        final input = await stream.first as Map<String, dynamic>;
        for (var k in input.keys) {
          data[k] = input[k] as Map<String, dynamic>;
        }
      } catch (_) {
        data.clear();
      }
      return data;
    } finally {
      _syncing.value = false;
    }
  }

  @override
  Future<void> write(Map<String, Map<String, dynamic>> data) async {
    if (!await _checkAccess()) return;

    final id = await _getFileId();
    if (_driveApi == null || id == null) return;
    _syncing.value = true;

    final buffer = utf8.encode(json.encode(data));
    final media = Media(Stream.value(buffer), buffer.length,
        contentType: 'application/json');
    await _driveApi!.files.update(File(), id, uploadMedia: media);
    _syncing.value = false;
  }

  @override
  Future<void> delete() async {
    if (!await _checkAccess()) return;

    _syncing.value = false;
    try {
      final id = await _getFileId();
      if (_driveApi == null || id == null) return;
      await _driveApi!.files.delete(id);
    } finally {
      _syncing.value = false;
    }
  }
}
