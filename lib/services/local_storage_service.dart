import 'dart:async';
import 'dart:convert';

import 'package:mobile_app/models/campus_profile.dart';
import 'package:mobile_app/models/transaction_record.dart';
import 'package:mobile_app/services/app_log_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  LocalStorageService._(this._prefs);

  final SharedPreferences _prefs;
  final Map<String, List<TransactionRecord>> _transactionsCache =
      <String, List<TransactionRecord>>{};
  Future<void> _writeQueue = Future<void>.value();

  static const _sidKey = 'campus_sid';
  static const _passwordKey = 'campus_password';
  static const _profileKey = 'campus_profile';
  static const _balanceKey = 'current_balance';
  static const _balanceUpdatedAtKey = 'balance_updated_at';
  static const _lastSyncAtKey = 'last_sync_at';
  static const _lastSyncDayKey = 'last_sync_day';
  static const _selectedMonthKey = 'selected_month';
  static const _txPrefix = 'transactions_sid_';

  static Future<LocalStorageService> create() async {
    final watch = Stopwatch()..start();
    final prefs = await SharedPreferences.getInstance();
    final service = LocalStorageService._(prefs);
    service._logInfo('create done in ${watch.elapsedMilliseconds}ms');
    return service;
  }

  bool get hasCredential {
    return campusSid.isNotEmpty && campusPassword.isNotEmpty;
  }

  String get campusSid {
    return (_prefs.getString(_sidKey) ?? '').trim();
  }

  String get campusPassword {
    return _prefs.getString(_passwordKey) ?? '';
  }

  String get selectedMonth {
    return _prefs.getString(_selectedMonthKey) ?? '';
  }

  Future<void> saveSelectedMonth(String month) async {
    await _enqueueWrite('saveSelectedMonth', () async {
      await _prefs.setString(_selectedMonthKey, month);
    });
  }

  Future<void> saveCredentials({
    required String sid,
    required String password,
  }) async {
    await _enqueueWrite('saveCredentials', () async {
      await _prefs.setString(_sidKey, sid.trim());
      await _prefs.setString(_passwordKey, password);
    });
  }

  Future<void> saveProfile(CampusProfile profile) async {
    await _enqueueWrite('saveProfile', () async {
      await _prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    });
  }

  CampusProfile? get profile {
    final raw = _prefs.getString(_profileKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return CampusProfile.fromJson(decoded);
      }
      if (decoded is Map) {
        return CampusProfile.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (error) {
      _logInfo('profile parse failed: $error');
      return null;
    }
    return null;
  }

  double? get currentBalance {
    return _prefs.getDouble(_balanceKey);
  }

  String? get balanceUpdatedAt {
    final value = _prefs.getString(_balanceUpdatedAtKey);
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String? get lastSyncAt {
    final value = _prefs.getString(_lastSyncAtKey);
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  String? get lastSyncDay {
    final value = _prefs.getString(_lastSyncDayKey);
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  Future<void> saveSyncMeta({
    required double balance,
    required String balanceUpdatedAt,
    required String lastSyncAt,
    required String lastSyncDay,
  }) async {
    await _enqueueWrite('saveSyncMeta', () async {
      await _prefs.setDouble(_balanceKey, balance);
      await _prefs.setString(_balanceUpdatedAtKey, balanceUpdatedAt);
      await _prefs.setString(_lastSyncAtKey, lastSyncAt);
      await _prefs.setString(_lastSyncDayKey, lastSyncDay);
    });
  }

  Future<void> saveTransactions(
    String sid,
    List<TransactionRecord> rows,
  ) async {
    final key = sid.trim();
    if (key.isEmpty) {
      return;
    }
    await _enqueueWrite(
      'saveTransactions sid=$key rows=${rows.length}',
      () async {
        _transactionsCache[key] = List<TransactionRecord>.from(rows);
        final encoded = jsonEncode(rows.map((item) => item.toJson()).toList());
        await _prefs.setString(_txKey(key), encoded);
      },
    );
  }

  List<TransactionRecord> loadTransactions(String sid) {
    final key = sid.trim();
    if (key.isEmpty) {
      return <TransactionRecord>[];
    }
    final cached = _transactionsCache[key];
    if (cached != null) {
      return List<TransactionRecord>.from(cached);
    }
    final raw = _prefs.getString(_txKey(key));
    if (raw == null || raw.trim().isEmpty) {
      return <TransactionRecord>[];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <TransactionRecord>[];
      }
      final out = <TransactionRecord>[];
      for (final item in decoded) {
        if (item is! Map) {
          continue;
        }
        out.add(TransactionRecord.fromJsonMap(Map<String, dynamic>.from(item)));
      }
      _transactionsCache[key] = List<TransactionRecord>.from(out);
      return out;
    } catch (error) {
      _logInfo('loadTransactions parse failed sid=$key: $error');
      return <TransactionRecord>[];
    }
  }

  Future<void> clearAll() async {
    await _enqueueWrite('clearAll', () async {
      _transactionsCache.clear();
      await _prefs.remove(_sidKey);
      await _prefs.remove(_passwordKey);
      await _prefs.remove(_profileKey);
      await _prefs.remove(_balanceKey);
      await _prefs.remove(_balanceUpdatedAtKey);
      await _prefs.remove(_lastSyncAtKey);
      await _prefs.remove(_lastSyncDayKey);
      await _prefs.remove(_selectedMonthKey);
      final keys = _prefs.getKeys();
      for (final key in keys) {
        if (!key.startsWith(_txPrefix)) {
          continue;
        }
        await _prefs.remove(key);
      }
    });
  }

  String _txKey(String sid) => '$_txPrefix$sid';

  Future<void> _enqueueWrite(String step, Future<void> Function() action) {
    final watch = Stopwatch()..start();
    final run = _writeQueue.catchError((_) {}).then((_) async {
      _logInfo('$step start');
      await action();
      _logInfo('$step done ${watch.elapsedMilliseconds}ms');
    });
    _writeQueue = run.catchError((error, stackTrace) {
      _logError('$step failed', error, stackTrace);
    });
    return run;
  }

  void _logInfo(String message) {
    unawaited(AppLogService.instance.info(message, tag: 'STORE'));
  }

  void _logError(String context, Object error, StackTrace stackTrace) {
    unawaited(
      AppLogService.instance.error(
        context,
        tag: 'STORE',
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}
