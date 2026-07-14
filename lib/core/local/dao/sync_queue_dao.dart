import 'package:drift/drift.dart';
import 'package:fleet_go/core/local/app_database.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueue])
class SyncQueueDao extends DatabaseAccessor<AppDatabase> with _$SyncQueueDaoMixin {
  SyncQueueDao(super.db);

  // syncQueue가 뭐야, 그리고 SyncQueueCompanion은 뭐고, 각각이 뭘 의미하는지 정리 필요.
  // enqueue는 뭐야?
  Future<int> enqueue({required String type, required String payload}) {
    return into(
      syncQueue,
    ).insert(SyncQueueCompanion.insert(type: type, payload: payload, createdAt: DateTime.now().millisecondsSinceEpoch));
  }

  // .get의 역할은? 그리고 뭐 문법적으로 알아야할 것 없는 지 확인 필요.
  Future<List<SyncQueueData>> fetchPending({int limit = 10}) {
    return (select(syncQueue)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.id)])
          ..limit(limit))
        .get();
  }

  // 어디에 쓰는 메소드야?
  Future<void> updateStatus(int id, String newStatus) {
    return (update(syncQueue)..where((t) => t.id.equals(id))).write(SyncQueueCompanion(status: Value(newStatus)));
  }

  // 어디에 쓰는 메소드야?
  Future<void> markSyncing(int id) {
    return (update(syncQueue)..where((t) => t.id.equals(id))).write(const SyncQueueCompanion(status: Value('syncing')));
  }

  // 어디에 쓰는 메소드야?
  Future<void> markRetry(int id, int currentRetryCount) {
    return (update(syncQueue)..where((t) => t.id.equals(id))).write(
      SyncQueueCompanion(status: const Value('pending'), retryCount: Value(currentRetryCount + 1)),
    );
  }

  // 어디에 쓰는 메소드야?
  Future<void> markFailed(int id) {
    return (update(syncQueue)..where((t) => t.id.equals(id))).write(const SyncQueueCompanion(status: Value('failed')));
  }

  Future<int> deleteDone() {
    return (delete(syncQueue)..where((t) => t.status.equals('done'))).go();
  }

  // addColumns랑 row 관련된 자세한 설명. countExpr은 뭔 변수야? 이게 무슨 약어야?
  Stream<int> watchPendingCount() {
    final countExpr = syncQueue.id.count();
    final query = selectOnly(syncQueue)
      ..where(syncQueue.status.equals('pending'))
      ..addColumns([countExpr]);

    return query.watchSingle().map((row) => row.read(countExpr) ?? 0);
  }

  // 이것은 무슨 메소드이지 ?
  Future<void> recoverStuckSyncing() {
    return (update(
      syncQueue,
    )..where((t) => t.status.equals('syncing'))).write(const SyncQueueCompanion(status: Value('pending')));
  }
}
