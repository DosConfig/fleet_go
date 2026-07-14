import 'dart:async';

import 'package:fleet_go/core/local/app_database.dart';
import 'package:fleet_go/core/local/dao/sync_queue_dao.dart';

enum SyncStatus { idle, syncing, error }

class SyncEngine {
  SyncEngine({required SyncQueueDao dao, required this.onProcess}) : _dao = dao;

  final SyncQueueDao _dao;
  final Future<void> Function(String type, String payload) onProcess;

  static const int maxRetry = 5;
  static const Duration syncInterval = Duration(seconds: 5);

  Timer? _timer;
  bool _isSyncing = false;
  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  void start() {
    _dao.recoverStuckSyncing();
    _timer = Timer.periodic(syncInterval, (_) => syncOnce());
    syncOnce();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void onConnectivityRestored() => syncOnce();

  Future<void> syncOnce() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pending = await _dao.fetchPending(limit: 10);
      if (pending.isEmpty) {
        _statusController.add(SyncStatus.idle);
        return;
      }

      _statusController.add(SyncStatus.syncing);

      for (final entry in pending) {
        await _processEntry(entry);
      }

      await _dao.deleteDone();
      _statusController.add(SyncStatus.idle);
    } catch (_) {
      _statusController.add(SyncStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processEntry(SyncQueueData entry) async {
    try {
      await _dao.markSyncing(entry.id);
      await onProcess(entry.type, entry.payload);
      await _dao.updateStatus(entry.id, 'done');
    } catch (_) {
      if (entry.retryCount >= maxRetry) {
        await _dao.markFailed(entry.id);
      } else {
        await _dao.markRetry(entry.id, entry.retryCount);
      }
    }
  }

  void dispose() {
    stop();
    _statusController.close();
  }
}
