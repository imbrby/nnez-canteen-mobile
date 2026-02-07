import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:mobile_app/models/transaction_record.dart';
import 'package:sqflite/sqflite.dart';

class LocalDatabaseService {
  Database? _db;

  Future<void> init() async {
    if (_db != null) {
      return;
    }
    final baseDir = await getApplicationDocumentsDirectory();
    final dbPath = path.join(baseDir.path, 'canteen_local.db');
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE transactions ('
          'sid TEXT NOT NULL,'
          'txn_id TEXT NOT NULL,'
          'amount REAL NOT NULL,'
          'balance REAL,'
          'occurred_at TEXT NOT NULL,'
          'occurred_day TEXT NOT NULL,'
          'item_name TEXT NOT NULL,'
          'raw_payload TEXT NOT NULL,'
          'updated_at TEXT NOT NULL,'
          'PRIMARY KEY (sid, txn_id)'
          ')',
        );
        await db.execute(
          'CREATE INDEX idx_transactions_sid_day ON transactions (sid, occurred_day)',
        );
        await db.execute(
          'CREATE INDEX idx_transactions_sid_time ON transactions (sid, occurred_at DESC)',
        );
      },
    );
  }

  Database get db {
    final value = _db;
    if (value == null) {
      throw StateError('Database not initialized.');
    }
    return value;
  }

  Future<void> upsertTransactions(
    String sid,
    List<TransactionRecord> rows,
  ) async {
    if (rows.isEmpty) {
      return;
    }
    final batch = db.batch();
    for (final row in rows) {
      batch.insert(
        'transactions',
        row.toDbMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, Object?>>> queryDailyTotals({
    required String sid,
    required String startDate,
    required String endDate,
  }) {
    return db.rawQuery(
      'SELECT occurred_day AS day, ROUND(SUM(amount), 2) AS total_amount, COUNT(*) AS txn_count '
      'FROM transactions '
      'WHERE sid = ? AND occurred_day BETWEEN ? AND ? '
      'GROUP BY occurred_day '
      'ORDER BY occurred_day',
      <Object?>[sid, startDate, endDate],
    );
  }

  Future<List<Map<String, Object?>>> queryMonthlyTotals({
    required String sid,
    required String startDate,
    required String endDate,
  }) {
    return db.rawQuery(
      'SELECT SUBSTR(occurred_day, 1, 7) AS month, ROUND(SUM(amount), 2) AS total_amount, COUNT(*) AS txn_count '
      'FROM transactions '
      'WHERE sid = ? AND occurred_day BETWEEN ? AND ? '
      'GROUP BY SUBSTR(occurred_day, 1, 7) '
      'ORDER BY month',
      <Object?>[sid, startDate, endDate],
    );
  }

  Future<List<TransactionRecord>> queryRecent({
    required String sid,
    int limit = 20,
  }) async {
    final rows = await db.query(
      'transactions',
      where: 'sid = ?',
      whereArgs: <Object?>[sid],
      orderBy: 'occurred_at DESC, txn_id DESC',
      limit: limit,
    );
    return rows.map(TransactionRecord.fromDbMap).toList();
  }

  Future<void> clearAll() {
    return db.delete('transactions');
  }

  Future<void> close() async {
    final value = _db;
    if (value != null) {
      await value.close();
      _db = null;
    }
  }
}
