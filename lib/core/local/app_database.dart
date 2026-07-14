import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:fleet_go/core/local/dao/sync_queue_dao.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

// ()를 왜 한번 더 붙이는건지.
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  TextColumn get payload => text()();
  IntColumn get createdAt => integer()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
}

@DriftDatabase(tables: [SyncQueue], daos: [SyncQueueDao])
class AppDatabase extends _$AppDatabase {
  // e는 무엇인지
  AppDatabase(super.e);

  // factory는 무엇인지
  // prod()는 뭐야?
  factory AppDatabase.prod() => AppDatabase(_openConnection());
  // native database는 뭐야? 그리고 memory()는 뭐야?
  factory AppDatabase.memory() => AppDatabase(NativeDatabase.memory());

  // schema version이란 무엇인지
  @override
  int get schemaVersion => 1;

  // 이건 뭘 하는것인지?
  @override
  MigrationStrategy get migration => MigrationStrategy(onCreate: (m) => m.createAll());
}

// 이건 뭐하는건지
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'fleet_go.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
