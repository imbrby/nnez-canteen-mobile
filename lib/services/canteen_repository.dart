import 'package:mobile_app/core/time_utils.dart';
import 'package:mobile_app/models/campus_profile.dart';
import 'package:mobile_app/models/home_summary.dart';
import 'package:mobile_app/services/campus_api_client.dart';
import 'package:mobile_app/services/local_database_service.dart';
import 'package:mobile_app/services/local_storage_service.dart';

class CanteenRepository {
  CanteenRepository._(this._storage, this._database, this._apiClient);

  static const int _syncLookbackDays = 120;

  final LocalStorageService _storage;
  final LocalDatabaseService _database;
  final CampusApiClient _apiClient;

  static Future<CanteenRepository> create() async {
    final storage = await LocalStorageService.create();
    final database = LocalDatabaseService();
    await database.init();
    final apiClient = CampusApiClient();
    return CanteenRepository._(storage, database, apiClient);
  }

  bool get hasCredential => _storage.hasCredential;

  CampusProfile? get profile => _storage.profile;

  String? get lastSyncAt => _storage.lastSyncAt;

  Future<void> initializeAccount({
    required String sid,
    required String password,
    void Function(String message)? onProgress,
  }) async {
    final normalizedSid = sid.trim();
    if (normalizedSid.isEmpty || password.isEmpty) {
      throw Exception('请输入食堂账号和密码。');
    }

    final range = _buildSyncRange();
    final payload = await _apiClient.fetchAll(
      sid: normalizedSid,
      plainPassword: password,
      startDate: range.startDate,
      endDate: range.endDate,
      includeTransactions: false,
      onProgress: onProgress,
    );

    onProgress?.call('正在保存账号信息...');
    await _storage.saveCredentials(sid: normalizedSid, password: password);
    await _storage.saveProfile(payload.profile);
    await _storage.saveSyncMeta(
      balance: payload.balance,
      balanceUpdatedAt: payload.balanceUpdatedAt.toIso8601String(),
      lastSyncAt: '',
      lastSyncDay: '',
    );
  }

  Future<void> syncNow({void Function(String message)? onProgress}) async {
    if (!hasCredential) {
      throw Exception('请先在设置中初始化账号。');
    }
    final sid = _storage.campusSid;
    final password = _storage.campusPassword;
    final range = _buildSyncRange();

    final payload = await _apiClient.fetchAll(
      sid: sid,
      plainPassword: password,
      startDate: range.startDate,
      endDate: range.endDate,
      includeTransactions: true,
      onProgress: onProgress,
    );

    onProgress?.call('正在写入本地数据...');
    await _storage.saveProfile(payload.profile);
    await _database.upsertTransactions(
      sid,
      payload.transactions,
      onProgress: onProgress,
    );
    await _storage.saveSyncMeta(
      balance: payload.balance,
      balanceUpdatedAt: payload.balanceUpdatedAt.toIso8601String(),
      lastSyncAt: DateTime.now().toIso8601String(),
      lastSyncDay: formatShanghaiDay(shanghaiNow()),
    );
  }

  bool shouldAutoSyncToday() {
    if (!hasCredential) {
      return false;
    }
    final today = formatShanghaiDay(shanghaiNow());
    return _storage.lastSyncDay != today;
  }

  Future<HomeSummary?> loadSummary({String? requestedMonth}) async {
    if (!hasCredential) {
      return null;
    }

    final sid = _storage.campusSid;
    final currentMonth = monthOf(shanghaiNow());
    final earliestMonth = addMonths(currentMonth, -11);
    final selectedMonth = _resolveMonth(
      requestedMonth: requestedMonth,
      fallbackMonth: _storage.selectedMonth,
      minMonth: earliestMonth,
      maxMonth: currentMonth,
    );

    final selectedStart = monthStart(selectedMonth);
    final selectedEnd = monthEnd(selectedMonth);
    final historyStart = monthStart(earliestMonth);
    final historyEnd = monthEnd(currentMonth);

    await _storage.saveSelectedMonth(selectedMonth);

    final dailyRows = await _database.queryDailyTotals(
      sid: sid,
      startDate: selectedStart,
      endDate: selectedEnd,
    );

    final dayMap = <String, DailySpending>{};
    for (final row in dailyRows) {
      final day = (row['day'] ?? '').toString();
      if (day.isEmpty) {
        continue;
      }
      dayMap[day] = DailySpending(
        day: day,
        totalAmount: ((row['total_amount'] ?? 0) as num).toDouble().abs(),
        txnCount: ((row['txn_count'] ?? 0) as num).toInt(),
      );
    }

    final fullDays = daysBetween(selectedStart, selectedEnd);
    final daily = fullDays
        .map(
          (day) =>
              dayMap[day] ??
              DailySpending(day: day, totalAmount: 0, txnCount: 0),
        )
        .toList();

    final recent = await _database.queryRecent(sid: sid, limit: 20);

    final monthRows = await _database.queryMonthlyTotals(
      sid: sid,
      startDate: historyStart,
      endDate: historyEnd,
    );
    final monthMap = <String, MonthOverview>{};
    for (final row in monthRows) {
      final month = (row['month'] ?? '').toString();
      if (month.isEmpty) {
        continue;
      }
      final txnCount = ((row['txn_count'] ?? 0) as num).toInt();
      monthMap[month] = MonthOverview(
        month: month,
        totalAmount: ((row['total_amount'] ?? 0) as num).toDouble().abs(),
        txnCount: txnCount,
        hasData: txnCount > 0,
      );
    }

    final availableMonths = monthsBetween(earliestMonth, currentMonth)
        .map(
          (month) =>
              monthMap[month] ??
              MonthOverview(
                month: month,
                totalAmount: 0,
                txnCount: 0,
                hasData: false,
              ),
        )
        .toList();

    final totalAmount = daily.fold<double>(
      0,
      (sum, item) => sum + item.totalAmount,
    );
    final transactionCount = daily.fold<int>(
      0,
      (sum, item) => sum + item.txnCount,
    );

    return HomeSummary(
      selectedMonth: selectedMonth,
      startDate: selectedStart,
      endDate: selectedEnd,
      days: monthDays(selectedMonth),
      availableMonths: availableMonths,
      daily: daily,
      recent: recent,
      totalAmount: totalAmount,
      transactionCount: transactionCount,
      currentBalance: _storage.currentBalance,
      balanceUpdatedAt: _storage.balanceUpdatedAt,
      lastSyncAt: _storage.lastSyncAt,
    );
  }

  Future<void> logout() async {
    await _storage.clearAll();
    await _database.clearAll();
  }

  Future<void> close() {
    return _database.close();
  }

  ({String startDate, String endDate}) _buildSyncRange() {
    final now = shanghaiNow();
    return (
      startDate: formatShanghaiDay(
        now.subtract(Duration(days: _syncLookbackDays - 1)),
      ),
      endDate: formatShanghaiDay(now),
    );
  }

  String _resolveMonth({
    required String? requestedMonth,
    required String fallbackMonth,
    required String minMonth,
    required String maxMonth,
  }) {
    final candidate = (requestedMonth ?? fallbackMonth).trim();
    final match = RegExp(r'^(\d{4})-(0[1-9]|1[0-2])$').hasMatch(candidate);
    if (!match) {
      return maxMonth;
    }
    if (candidate.compareTo(minMonth) < 0 ||
        candidate.compareTo(maxMonth) > 0) {
      return maxMonth;
    }
    return candidate;
  }
}
