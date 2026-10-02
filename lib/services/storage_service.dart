import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cloud_account.dart';
import '../models/download_task.dart';

/// 本地存储服务
class StorageService {
  static const String _accountsKey = 'cloud_accounts';
  static const String _settingsKey = 'app_settings';
  static const String _tasksKey = 'download_tasks';
  static const String _historyKey = 'parse_history';

  final SharedPreferences _prefs;
  StorageService(this._prefs);

  // ---------- 账号 ----------

  List<CloudAccount> getAccounts() {
    final raw = _prefs.getStringList(_accountsKey) ?? [];
    return raw
        .map((e) => CloudAccount.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAccounts(List<CloudAccount> accounts) async {
    final raw = accounts.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(_accountsKey, raw);
  }

  Future<void> upsertAccount(CloudAccount account) async {
    final accounts = getAccounts();
    final idx = accounts.indexWhere((a) => a.platform == account.platform);
    if (idx >= 0) {
      accounts[idx] = account;
    } else {
      accounts.add(account);
    }
    await saveAccounts(accounts);
  }

  Future<void> removeAccount(String platform) async {
    final accounts = getAccounts()
        .where((a) => a.platform.name != platform)
        .toList();
    await saveAccounts(accounts);
  }

  CloudAccount? getAccount(String platform) {
    try {
      return getAccounts().firstWhere((a) => a.platform.name == platform);
    } catch (_) {
      return null;
    }
  }

  // ---------- 下载任务 ----------

  List<DownloadTask> getTasks() {
    final raw = _prefs.getStringList(_tasksKey) ?? [];
    return raw
        .map((e) => DownloadTask.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveTasks(List<DownloadTask> tasks) async {
    final raw = tasks.map((e) => jsonEncode(e.toJson())).toList();
    await _prefs.setStringList(_tasksKey, raw);
  }

  // ---------- 设置 ----------

  Map<String, dynamic> getSettings() {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null) return _defaultSettings();
    try {
      final parsed = jsonDecode(raw) as Map<String, dynamic>;
      return {..._defaultSettings(), ...parsed};
    } catch (_) {
      return _defaultSettings();
    }
  }

  Future<void> saveSetting(String key, dynamic value) async {
    final settings = getSettings();
    settings[key] = value;
    await _prefs.setString(_settingsKey, jsonEncode(settings));
  }

  Map<String, dynamic> _defaultSettings() => {
        'wifiOnly': false,
        'threadCount': 64,
        'concurrentTasks': 8,
        'speedLimit': 0,
        'autoRetry': 3,
        'verifyIntegrity': true,
        'keepScreenOn': true,
        'showNotification': true,
        'clipboardListen': true,
        'appLock': false,
        'gopeedEnabled': true,
        'gopeedAddress': 'http://127.0.0.1:48686',
        'gopeedToken': '',
        'saveDirectory': '',
        'onlineParse': true,
        'themeMode': 'system',
        'seedColor': '冰雪蓝',
        'folderBatch': false,
      };

  // ---------- 历史 ----------

  List<String> getHistory() {
    return _prefs.getStringList(_historyKey) ?? [];
  }

  Future<void> addHistory(String text) async {
    final history = getHistory();
    history.remove(text);
    history.insert(0, text);
    if (history.length > 50) history.removeLast();
    await _prefs.setStringList(_historyKey, history);
  }

  Future<void> clearHistory() async {
    await _prefs.remove(_historyKey);
  }
}
