import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cloud_account.dart';
import '../models/download_task.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../services/gopeed_service.dart';
import '../services/download_service.dart';
import '../services/clipboard_service.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('需要在 main 中 override');
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(sharedPreferencesProvider));
});

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

final gopeedServiceProvider = Provider<GopeedService>((ref) => GopeedService());

final downloadServiceProvider = Provider<DownloadService>((ref) => DownloadService());

final clipboardServiceProvider = Provider<ClipboardService>((ref) => ClipboardService());

final accountsProvider =
    StateNotifierProvider<AccountsNotifier, List<CloudAccount>>((ref) {
  return AccountsNotifier(ref.watch(storageServiceProvider), ref.watch(apiServiceProvider));
});

class AccountsNotifier extends StateNotifier<List<CloudAccount>> {
  final StorageService _storage;
  final ApiService _api;
  AccountsNotifier(this._storage, this._api) : super(_storage.getAccounts());

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> refresh() async {
    final accounts = _storage.getAccounts();
    state = accounts;
    // 异步刷新每个账号的容量
    for (final account in accounts) {
      final storage = await _api.fetchStorage(account.platform, account.credential);
      if (storage != null) {
        final updated = account.copyWith(
          totalSpace: storage.$1,
          usedSpace: storage.$2,
        );
        await _storage.upsertAccount(updated);
      }
    }
    state = _storage.getAccounts();
  }

  Future<void> upsert(CloudAccount account) async {
    await _storage.upsertAccount(account);
    state = _storage.getAccounts();
  }

  Future<void> remove(String platform) async {
    await _storage.removeAccount(platform);
    state = _storage.getAccounts();
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, Map<String, dynamic>>((ref) {
  return SettingsNotifier(ref.watch(storageServiceProvider));
});

class SettingsNotifier extends StateNotifier<Map<String, dynamic>> {
  final StorageService _storage;
  SettingsNotifier(this._storage) : super(_storage.getSettings());

  Future<void> set(String key, dynamic value) async {
    await _storage.saveSetting(key, value);
    state = {...state, key: value};
  }

  dynamic get(String key, [dynamic defaultValue]) => state[key] ?? defaultValue;
}

final tasksProvider =
    StateNotifierProvider<TasksNotifier, List<DownloadTask>>((ref) {
  return TasksNotifier(ref.watch(storageServiceProvider));
});

class TasksNotifier extends StateNotifier<List<DownloadTask>> {
  final StorageService _storage;
  TasksNotifier(this._storage) : super(_storage.getTasks());

  Future<void> refresh() async {
    state = _storage.getTasks();
  }

  Future<void> save(List<DownloadTask> tasks) async {
    await _storage.saveTasks(tasks);
    state = tasks;
  }

  /// 更新单个任务（用于实时进度）
  void updateTask(DownloadTask task) {
    state = state.map((t) => t.id == task.id ? task : t).toList();
  }

  /// 更新并持久化单个任务
  Future<void> updateAndSave(DownloadTask task) async {
    updateTask(task);
    await _storage.saveTasks(state);
  }
}
