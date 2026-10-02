import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/download_task.dart';

/// Gopeed 下载器服务（通过 HTTP API 与 gopeed 通信）
/// Gopeed 提供 RESTful API，默认地址 http://127.0.0.1:48686
class GopeedService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));

  String address = 'http://127.0.0.1:48686';
  String token = '';

  Map<String, String> get _headers => {
        if (token.isNotEmpty) 'X-Api-Token': token,
      };

  /// 检查 gopeed 是否运行
  Future<bool> isRunning() async {
    try {
      final resp = await _dio.get(
        '$address/api/v1/configs',
        options: Options(headers: _headers),
      );
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 创建下载任务
  Future<String?> createTask({
    required String url,
    String? name,
    Map<String, String> headers = const {},
  }) async {
    try {
      final body = {
        'url': url,
        'name': name ?? '',
        'headers': headers.entries.map((e) => '${e.key}: ${e.value}').toList(),
      };
      final resp = await _dio.post(
        '$address/api/v1/tasks',
        data: jsonEncode(body),
        options: Options(headers: {
          ..._headers,
          'Content-Type': 'application/json',
        }),
      );
      if (resp.statusCode == 200 && resp.data is Map) {
        return resp.data['id'];
      }
    } catch (_) {}
    return null;
  }

  /// 获取任务列表
  Future<List<DownloadTask>> getTasks() async {
    try {
      final resp = await _dio.get(
        '$address/api/v1/tasks',
        options: Options(headers: _headers),
      );
      if (resp.statusCode == 200 && resp.data is List) {
        final list = resp.data as List;
        return list.map((e) {
          final statusStr = e['status']?.toString() ?? '';
          DownloadStatus status;
          switch (statusStr) {
            case 'downloading':
              status = DownloadStatus.downloading;
              break;
            case 'pause':
              status = DownloadStatus.paused;
              break;
            case 'done':
              status = DownloadStatus.completed;
              break;
            case 'error':
              status = DownloadStatus.failed;
              break;
            default:
              status = DownloadStatus.pending;
          }
          return DownloadTask(
            id: e['id']?.toString() ?? '',
            url: e['url']?.toString() ?? '',
            fileName: e['name']?.toString() ?? '',
            totalBytes: (e['size'] is num) ? e['size'].toInt() : 0,
            downloadedBytes:
                (e['downloaded'] is num) ? e['downloaded'].toInt() : 0,
            status: status,
            speed: (e['speed'] is num) ? e['speed'].toDouble() : 0,
            savePath: e['path']?.toString() ?? '',
            createTime: DateTime.now(),
          );
        }).toList();
      }
    } catch (_) {}
    return [];
  }

  /// 暂停任务
  Future<bool> pauseTask(String id) async {
    try {
      final resp = await _dio.put(
        '$address/api/v1/tasks/$id/pause',
        options: Options(headers: _headers),
      );
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 继续任务
  Future<bool> resumeTask(String id) async {
    try {
      final resp = await _dio.put(
        '$address/api/v1/tasks/$id/continue',
        options: Options(headers: _headers),
      );
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 删除任务
  Future<bool> deleteTask(String id, {bool force = false}) async {
    try {
      final resp = await _dio.delete(
        '$address/api/v1/tasks/$id?force=$force',
        options: Options(headers: _headers),
      );
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
