import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

import 'session_record.dart';
import 'session_repository.dart';

/// Stores each session as its own AES-256-GCM encrypted file in the app's
/// private storage. The key is generated on first use and kept in the
/// platform secure storage (Android Keystore). Nothing leaves the device.
class LocalSessionRepository implements SessionRepository {
  static const _keyName = 'fidgy_sessions_key_v1';
  static const _extension = '.fsx';

  final _storage = const FlutterSecureStorage();
  final _cipher = AesGcm.with256bits();

  Future<SecretKey>? _keyFuture;
  Directory? _dir;

  Future<SecretKey> _key() {
    return _keyFuture ??= _loadOrCreateKey().catchError((Object e) {
      _keyFuture = null; // allow a retry next time
      throw e;
    });
  }

  Future<SecretKey> _loadOrCreateKey() async {
    final stored = await _storage.read(key: _keyName);
    if (stored != null) return SecretKey(base64Decode(stored));

    final fresh = await _cipher.newSecretKey();
    final bytes = await fresh.extractBytes();
    await _storage.write(key: _keyName, value: base64Encode(bytes));
    return SecretKey(bytes);
  }

  Future<Directory> _sessionsDir() async {
    final cached = _dir;
    if (cached != null) return cached;
    final base = await getApplicationSupportDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}sessions');
    if (!await dir.exists()) await dir.create(recursive: true);
    return _dir = dir;
  }

  @override
  Future<void> save(SessionRecord record) async {
    if (kIsWeb) return;
    try {
      final key = await _key();
      final clear = utf8.encode(jsonEncode(record.toJson()));
      final box = await _cipher.encrypt(clear, secretKey: key);

      final dir = await _sessionsDir();
      final target = File(
        '${dir.path}${Platform.pathSeparator}${record.id}$_extension',
      );
      final temp = File('${target.path}.tmp');
      await temp.writeAsBytes(box.concatenation(), flush: true);
      await temp.rename(target.path);
    } catch (e) {
      // Saving must never interrupt a game.
      debugPrint('Session save failed: $e');
    }
  }

  @override
  Future<List<SessionRecord>> loadAll() async {
    if (kIsWeb) return [];
    final result = <SessionRecord>[];
    try {
      final key = await _key();
      final dir = await _sessionsDir();
      await for (final entity in dir.list()) {
        if (entity is! File || !entity.path.endsWith(_extension)) continue;
        try {
          final bytes = await entity.readAsBytes();
          final box = SecretBox.fromConcatenation(
            bytes,
            nonceLength: AesGcm.defaultNonceLength,
            macLength: 16,
          );
          final clear = await _cipher.decrypt(box, secretKey: key);
          final json = jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
          result.add(SessionRecord.fromJson(json));
        } catch (_) {
          // Unreadable or corrupted file: skip it rather than fail everything.
        }
      }
    } catch (e) {
      debugPrint('Session load failed: $e');
    }
    result.sort((a, b) => a.startedAt.compareTo(b.startedAt));
    return result;
  }

  @override
  Future<int> count() async {
    if (kIsWeb) return 0;
    try {
      final dir = await _sessionsDir();
      var n = 0;
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith(_extension)) n++;
      }
      return n;
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> deleteAll() async {
    if (kIsWeb) return;
    try {
      final dir = await _sessionsDir();
      if (await dir.exists()) await dir.delete(recursive: true);
      _dir = null;
      await _storage.delete(key: _keyName);
      _keyFuture = null;
    } catch (e) {
      debugPrint('Session delete failed: $e');
    }
  }
}
