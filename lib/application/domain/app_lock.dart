import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../../common/presentation/presentation.dart';
import '../data/csv_exporter.dart';
import '../data/session_repository.dart';
import 'game_data.dart';

/// How the app is unlocked.
enum LockMethod {
  /// The phone's own unlock: fingerprint, face, or the screen lock.
  device,

  /// A Fidgy PIN, for phones without a screen lock.
  pin,
}

/// Outcome of checking a PIN.
class PinResult {
  const PinResult.ok()
      : ok = true,
        lockedForSeconds = 0,
        attemptsLeft = 0;
  const PinResult.wrong(this.attemptsLeft)
      : ok = false,
        lockedForSeconds = 0;
  const PinResult.locked(this.lockedForSeconds)
      : ok = false,
        attemptsLeft = 0;

  final bool ok;
  final int lockedForSeconds;
  final int attemptsLeft;

  String get message {
    if (ok) return '';
    if (lockedForSeconds > 0) {
      return 'Please wait ${lockedForSeconds}s, then try again.';
    }
    if (attemptsLeft > 0) {
      return 'Not quite. $attemptsLeft '
          '${attemptsLeft == 1 ? 'try' : 'tries'} left before a short pause.';
    }
    return 'Not quite. Try again.';
  }
}

/// Optional app lock.
///
/// The main method is the phone's own unlock (fingerprint, face or screen
/// lock), which needs no precision from the patient. A PIN is available as a
/// fallback; it is stored only as a salted hash in the platform secure
/// storage, and is forgiving: a Confirm button, 10 tries per block, and short
/// pauses. This keeps casual snoopers out; session data is encrypted
/// separately.
class AppLock extends AppViewModel with WidgetsBindingObserver {
  AppLock._();
  static final i = AppLock._();

  static const _methodKey = 'fidgy_lock_method_v1';
  static const _pinKey = 'fidgy_pin_v1';
  static const _attemptsKey = 'fidgy_pin_attempts_v1';
  static const _relockAfter = Duration(seconds: 30);
  static const _triesPerBlock = 10;

  final _storage = const FlutterSecureStorage();
  final _auth = LocalAuthentication();
  final _kdf = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 10000,
    bits: 256,
  );

  LockMethod? _method;
  bool _locked = false;
  bool _observing = false;
  DateTime? _pausedAt;

  LockMethod? get method => _method;
  bool get enabled => _method != null;
  bool get locked => _locked;

  Future<void> initialise() async {
    try {
      final stored = await _storage.read(key: _methodKey);
      final hasPin = (await _storage.read(key: _pinKey)) != null;
      _method = switch (stored) {
        'device' => LockMethod.device,
        'pin' => LockMethod.pin,
        _ => hasPin ? LockMethod.pin : null,
      };
    } catch (_) {
      _method = null;
    }
    _locked = enabled;
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    setState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!enabled) return;
    if (state == AppLifecycleState.paused) {
      _pausedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final paused = _pausedAt;
      _pausedAt = null;
      if (paused != null &&
          DateTime.now().difference(paused) >= _relockAfter) {
        _locked = true;
        setState();
      }
    }
  }

  // ------------------------------------------------------- phone unlock

  /// Whether the phone has a fingerprint, face or screen lock set up.
  Future<bool> deviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> _authenticate(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason);
    } catch (e) {
      debugPrint('Phone unlock failed: $e');
      return false;
    }
  }

  /// Confirms the patient can unlock, then turns the lock on.
  Future<bool> enableDevice() async {
    if (!await deviceSupported()) return false;
    final ok = await _authenticate('Confirm it is you to turn on the app lock');
    if (!ok) return false;
    await _storage.write(key: _methodKey, value: 'device');
    await _storage.delete(key: _pinKey);
    await _storage.delete(key: _attemptsKey);
    _method = LockMethod.device;
    _locked = false;
    setState();
    return true;
  }

  /// Asks for the phone unlock without changing the lock state.
  Future<bool> verifyDevice() => _authenticate('Confirm it is you');

  Future<bool> unlockWithDevice() async {
    final ok = await _authenticate('Unlock Fidgy');
    if (ok) {
      _locked = false;
      setState();
    }
    return ok;
  }

  // ---------------------------------------------------------------- PIN

  Future<List<int>> _derive(String pin, List<int> salt) async {
    final key = await _kdf.deriveKeyFromPassword(password: pin, nonce: salt);
    return key.extractBytes();
  }

  bool _same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  /// Turns the lock on with a PIN (or replaces the PIN).
  Future<void> enablePin(String pin) async {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final hash = await _derive(pin, salt);
    await _storage.write(
      key: _pinKey,
      value: '${base64Encode(salt)}:${base64Encode(hash)}',
    );
    await _storage.write(key: _methodKey, value: 'pin');
    await _storage.delete(key: _attemptsKey);
    _method = LockMethod.pin;
    _locked = false;
    setState();
  }

  /// Checks a PIN, counting wrong guesses. After every 10 wrong tries there is
  /// a short pause (15 seconds, doubling, up to 5 minutes).
  Future<PinResult> verify(String pin) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      var count = 0;
      var until = 0;
      final raw = await _storage.read(key: _attemptsKey);
      if (raw != null) {
        final parts = raw.split(':');
        count = int.tryParse(parts[0]) ?? 0;
        until = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
      }
      if (until > now) return PinResult.locked(((until - now) / 1000).ceil());

      final stored = await _storage.read(key: _pinKey);
      if (stored == null) return const PinResult.ok();
      final parts = stored.split(':');
      final salt = base64Decode(parts[0]);
      final expected = base64Decode(parts[1]);
      final actual = await _derive(pin, salt);

      if (_same(actual, expected)) {
        await _storage.delete(key: _attemptsKey);
        return const PinResult.ok();
      }

      count++;
      var lockUntil = 0;
      if (count % _triesPerBlock == 0) {
        final block = count ~/ _triesPerBlock;
        final seconds = min<int>(300, 15 * pow(2, block - 1).toInt());
        lockUntil = now + seconds * 1000;
      }
      await _storage.write(key: _attemptsKey, value: '$count:$lockUntil');
      if (lockUntil > 0) {
        return PinResult.locked(((lockUntil - now) / 1000).ceil());
      }
      return PinResult.wrong(_triesPerBlock - count % _triesPerBlock);
    } catch (e) {
      debugPrint('PIN check failed: $e');
      return const PinResult.wrong(0);
    }
  }

  /// Checks a PIN and, if correct, opens the app.
  Future<PinResult> unlockWithPin(String pin) async {
    final result = await verify(pin);
    if (result.ok) {
      _locked = false;
      setState();
    }
    return result;
  }

  // ------------------------------------------------------------- shared

  Future<void> disable() async {
    try {
      await _storage.delete(key: _methodKey);
      await _storage.delete(key: _pinKey);
      await _storage.delete(key: _attemptsKey);
    } catch (_) {}
    _method = null;
    _locked = false;
    setState();
  }

  /// For when the patient cannot unlock: wipes all patient data, then removes
  /// the lock.
  Future<void> resetEverything() async {
    await SessionRepository.instance.deleteAll();
    await GameData.i.clearAll();
    await CsvExporter.purge();
    await disable();
  }
}
