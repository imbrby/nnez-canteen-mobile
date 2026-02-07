import 'dart:convert';

import 'package:mobile_app/models/campus_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  LocalStorageService._(this._prefs);

  final SharedPreferences _prefs;

  static const _sidKey = 'campus_sid';
  static const _passwordKey = 'campus_password';
  static const _profileKey = 'campus_profile';
  static const _balanceKey = 'current_balance';
  static const _balanceUpdatedAtKey = 'balance_updated_at';
  static const _lastSyncAtKey = 'last_sync_at';
  static const _lastSyncDayKey = 'last_sync_day';
  static const _selectedMonthKey = 'selected_month';

  static Future<LocalStorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorageService._(prefs);
  }

  bool get hasCredential {
    return campusSid.isNotEmpty && campusPassword.isNotEmpty;
  }

  String get campusSid {
    return _prefs.getString(_sidKey) ?? '';
  }

  String get campusPassword {
    return _prefs.getString(_passwordKey) ?? '';
  }

  String get selectedMonth {
    return _prefs.getString(_selectedMonthKey) ?? '';
  }

  Future<void> saveSelectedMonth(String month) {
    return _prefs.setString(_selectedMonthKey, month);
  }

  Future<void> saveCredentials({
    required String sid,
    required String password,
  }) async {
    await _prefs.setString(_sidKey, sid.trim());
    await _prefs.setString(_passwordKey, password);
  }

  Future<void> saveProfile(CampusProfile profile) {
    final jsonString = jsonEncode(profile.toJson());
    return _prefs.setString(_profileKey, jsonString);
  }

  CampusProfile? get profile {
    final jsonString = _prefs.getString(_profileKey);
    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return CampusProfile.fromJson(map);
    } catch (_) {
      return null;
    }
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
    await _prefs.setDouble(_balanceKey, balance);
    await _prefs.setString(_balanceUpdatedAtKey, balanceUpdatedAt);
    await _prefs.setString(_lastSyncAtKey, lastSyncAt);
    await _prefs.setString(_lastSyncDayKey, lastSyncDay);
  }

  Future<void> clearAll() async {
    await _prefs.remove(_sidKey);
    await _prefs.remove(_passwordKey);
    await _prefs.remove(_profileKey);
    await _prefs.remove(_balanceKey);
    await _prefs.remove(_balanceUpdatedAtKey);
    await _prefs.remove(_lastSyncAtKey);
    await _prefs.remove(_lastSyncDayKey);
    await _prefs.remove(_selectedMonthKey);
  }
}
