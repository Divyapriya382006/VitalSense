import 'package:sqflite/sqflite.dart';

class MockDatabase implements Database {
  @override String get path => 'mock.db';
  @override bool get isOpen => true;
  @override Database get database => this;
  @override Future<void> close() async {}
  
  @override Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async => 0;
  @override Future<List<Map<String, Object?>>> query(String table, {bool? distinct, List<String>? columns, String? where, List<Object?>? whereArgs, String? groupBy, String? having, String? orderBy, int? limit, int? offset}) async => [];
  @override Future<int> insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async => 0;
  @override Future<int> update(String table, Map<String, Object?> values, {String? where, List<Object?>? whereArgs, ConflictAlgorithm? conflictAlgorithm}) async => 0;
  @override Future<void> execute(String sql, [List<Object?>? arguments]) async {}
  @override Future<int> rawDelete(String sql, [List<Object?>? arguments]) async => 0;
  @override Future<int> rawInsert(String sql, [List<Object?>? arguments]) async => 0;
  @override Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async => [];
  @override Future<int> rawUpdate(String sql, [List<Object?>? arguments]) async => 0;
  @override Future<T> transaction<T>(Future<T> Function(Transaction txn) action, {bool? exclusive}) async => throw UnimplementedError();
  @override Future<T> readTransaction<T>(Future<T> Function(Transaction txn) action) async => throw UnimplementedError();
  @override Batch batch() => throw UnimplementedError();
  @override Future<List<T>> devRawQuery<T>(String sql, [List<Object?>? arguments]) async => [];
  @override Future<void> devRawExecute(String sql, [List<Object?>? arguments]) async {}
  @override Future<int> getVersion() async => 1;
  @override Future<void> setVersion(int version) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
