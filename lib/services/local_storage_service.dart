import 'dart:convert';
import 'dart:io';

import 'package:mobile_app/models/campus_profile.dart';
import 'package:mobile_app/models/transaction_record.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class LocalStorageService {
  LocalStorageService._(this._file, this._cache);

  final File _file;
  final Map<String, dynamic> _cache;

  static const _sidKey = 'campus_sid';
  static const _passwordKey = 'campus_password';
  static const _profileKey = 'campus_profile';
  static const _balanceKey = 'current_balance';
  static const _balanceUpdatedAtKey = 'balance_updated_at';
  static const _lastSyncAtKey = 'last_sync_at';
  static const _lastSyncDayKey = 'last_sync_day';
  static const _selectedMonthKey = 'selected_month';
  static const _transactionsBySidKey = 'transactions_by_sid';

  static Future<LocalStorageService> create() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final file = File(path.join(baseDir.path, 'app_state.json'));
    Map<String, dynamic> cache = <String, dynamic>{};
    if (await file.exists()) {
      try {
        final raw = await file.readAsString();
        final parsed = jsonDecode(raw);
        if (parsed is Map<String, dynamic>) {
          cache = parsed;
        }
      } catch (_) {
        cache = <String, dynamic>{};
      }
    }
    return LocalStorageService._(file, cache);
  }

  bool get hasCredential {
    return campusSid.isNotEmpty && campusPassword.isNotEmpty;
  }

  String get campusSid {
    return (_cache[_sidKey] ?? '').toString();
  }

  String get campusPassword {
    return (_cache[_passwordKey] ?? '').toString();
  }

  String get selectedMonth {
    return (_cache[_selectedMonthKey] ?? '').toString();
  }

  Future<void> saveSelectedMonth(String month) {
    _cache[_selectedMonthKey] = month;
    return _persist();
  }

  Future<void> saveCredentials({
    required String sid,
    required String password,
  }) async {
    _cache[_sidKey] = sid.trim();
    _cache[_passwordKey] = password;
    await _persist();
  }

  Future<void> saveProfile(CampusProfile profile) async {
    _cache[_profileKey] = profile.toJson();
    await _persist();
  }

  CampusProfile? get profile {
    final value = _cache[_profileKey];
    if (value == null) {
      return null;
    }
    try {
      if (value is Map<String, dynamic>) {
        return CampusProfile.fromJson(value);
      }
      if (value is String && value.isNotEmpty) {
        final parsed = jsonDecode(value);
        if (parsed is Map<String, dynamic>) {
          return CampusProfile.fromJson(parsed);
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  double? _readDouble(String key) {
    final value = _cache[key];
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    final parsed = double.tryParse(value.toString());
    return parsed;
  }

  String? _readNonEmptyString(String key) {
    final value = _cache[key];
    if (value == null) {
      return null;
    }
    final text = value.toString();
    if (text.isEmpty) {
      return null;
    }
    return text;
  }

  Future<void> _persist() async {
    await _file.writeAsString(jsonEncode(_cache), flush: true);
  }

  double? get currentBalance {
    return _readDouble(_balanceKey);
  }

  String? get balanceUpdatedAt {
    return _readNonEmptyString(_balanceUpdatedAtKey);
  }

  String? get lastSyncAt {
    return _readNonEmptyString(_lastSyncAtKey);
  }

  String? get lastSyncDay {
    return _readNonEmptyString(_lastSyncDayKey);
  }

  Future<void> saveSyncMeta({
    required double balance,
    required String balanceUpdatedAt,
    required String lastSyncAt,
    required String lastSyncDay,
  }) async {
    _cache[_balanceKey] = balance;
    _cache[_balanceUpdatedAtKey] = balanceUpdatedAt;
    _cache[_lastSyncAtKey] = lastSyncAt;
    _cache[_lastSyncDayKey] = lastSyncDay;
    await _persist();
  }

  Future<void> saveTransactions(
    String sid,
    List<TransactionRecord> rows,
  ) async {
    final key = sid.trim();
    if (key.isEmpty) {
      return;
    }
    final map = _readTransactionsBySid();
    map[key] = rows.map((item) => item.toJson()).toList();
    _cache[_transactionsBySidKey] = map;
    await _persist();
  }

  List<TransactionRecord> loadTransactions(String sid) {
    final key = sid.trim();
    if (key.isEmpty) {
      return <TransactionRecord>[];
    }
    final map = _readTransactionsBySid();
    final raw = map[key];
    if (raw is! List) {
      return <TransactionRecord>[];
    }
    final out = <TransactionRecord>[];
    for (final item in raw) {
      if (item is! Map) {
        continue;
      }
      try {
        out.add(TransactionRecord.fromJsonMap(Map<String, dynamic>.from(item)));
      } catch (_) {
        // skip malformed row
      }
    }
    return out;
  }

  Map<String, dynamic> _readTransactionsBySid() {
    final raw = _cache[_transactionsBySidKey];
    if (raw is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    if (raw is String && raw.isNotEmpty) {
      try {
        final parsed = jsonDecode(raw);
        if (parsed is Map<String, dynamic>) {
          return Map<String, dynamic>.from(parsed);
        }
        if (parsed is Map) {
          return Map<String, dynamic>.from(parsed);
        }
      } catch (_) {
        return <String, dynamic>{};
      }
    }
    return <String, dynamic>{};
  }

  Future<void> clearAll() async {
    _cache
      ..remove(_sidKey)
      ..remove(_passwordKey)
      ..remove(_profileKey)
      ..remove(_balanceKey)
      ..remove(_balanceUpdatedAtKey)
      ..remove(_lastSyncAtKey)
      ..remove(_lastSyncDayKey)
      ..remove(_selectedMonthKey)
      ..remove(_transactionsBySidKey);
    await _persist();
  }
}
