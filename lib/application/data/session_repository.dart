import 'local_session_repository.dart';
import 'session_record.dart';

/// Where finished sessions are stored. The game only talks to this interface,
/// so an online implementation can be added later without touching game code.
abstract class SessionRepository {
  /// Version 1 keeps everything encrypted on the device.
  static final SessionRepository instance = LocalSessionRepository();

  Future<void> save(SessionRecord record);

  /// All readable sessions, oldest first.
  Future<List<SessionRecord>> loadAll();

  /// Number of sessions stored (does not decrypt anything).
  Future<int> count();

  /// Permanently removes every session and the encryption key.
  Future<void> deleteAll();
}
