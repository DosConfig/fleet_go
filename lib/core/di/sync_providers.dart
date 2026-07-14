import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fleet_go/core/local/app_database.dart';
import 'package:fleet_go/core/sync/sync_engine.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_providers.g.dart';

@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase.prod();
  ref.onDispose(() => db.close());
  return db;
}

@Riverpod(keepAlive: true)
SyncEngine syncEngine(Ref ref) {
  final dao = ref.watch(appDatabaseProvider).syncQueueDao;
  final engine = SyncEngine(dao: dao, onProcess: (type, payload) async {});
  engine.start();
  ref.onDispose(() => engine.dispose());
  return engine;
}

@riverpod
Stream<SyncStatus> syncStatus(Ref ref) {
  return ref.watch(syncEngineProvider).statusStream;
}

@riverpod
Stream<int> pendingQueueCount(Ref ref) {
  final dao = ref.watch(appDatabaseProvider).syncQueueDao;
  return dao.watchPendingCount();
}

@riverpod
class ConnectivityNotifier extends _$ConnectivityNotifier {
  @override
  bool build() {
    Connectivity().onConnectivityChanged.listen((results) {
      final wasOnline = state;
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      state = isOnline;

      if (!wasOnline && isOnline) {
        ref.read(syncEngineProvider).onConnectivityRestored();
      }
    });

    return true;
  }
}
