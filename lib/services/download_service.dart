import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/download_task.dart';

/// 内置下载服务（不依赖 gopeed）
class DownloadService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(minutes: 30),
  ));

  /// 正在进行的下载任务取消令牌
  final Map<String, CancelToken> _cancelTokens = {};

  /// 获取下载保存目录（公共 Downloads 目录）
  Future<String> getDownloadDir() async {
    // 优先保存到公共 Downloads 目录，用户可在文件管理器中找到
    const publicDownloadPath = '/storage/emulated/0/Download/冰雪助手';
    try {
      final dir = Directory(publicDownloadPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      // 测试是否可写
      final testFile = File('${dir.path}/.write_test');
      await testFile.writeAsString('test');
      await testFile.delete();
      return dir.path;
    } catch (_) {
      // 回退到应用私有目录
      Directory? dir;
      try {
        dir = await getExternalStorageDirectory();
      } catch (_) {
        dir = await getApplicationDocumentsDirectory();
      }
      final downloadDir = Directory('${dir!.path}/Download');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      return downloadDir.path;
    }
  }

  /// 下载文件，实时回调进度
  /// [onProgress] 回调 (downloaded, total, speed)
  Future<void> download({
    required DownloadTask task,
    required void Function(int downloaded, int total, double speed) onProgress,
    required void Function() onComplete,
    required void Function(String error) onError,
  }) async {
    final cancelToken = CancelToken();
    _cancelTokens[task.id] = cancelToken;

    try {
      final dir = await getDownloadDir();
      final savePath = '$dir/${task.fileName}';

      // 如果文件已存在且大小一致，直接完成
      final existing = File(savePath);
      if (await existing.exists() &&
          task.totalBytes > 0 &&
          await existing.length() == task.totalBytes) {
        onComplete();
        return;
      }

      int lastTime = DateTime.now().millisecondsSinceEpoch;
      int lastBytes = 0;

      await _dio.download(
        task.url,
        savePath,
        options: Options(
          headers: task.headers,
          responseType: ResponseType.stream,
        ),
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          final now = DateTime.now().millisecondsSinceEpoch;
          final dt = now - lastTime;
          double speed = 0;
          if (dt > 0) {
            speed = (received - lastBytes) / (dt / 1000);
          }
          lastTime = now;
          lastBytes = received;
          onProgress(received, total, speed);
        },
      );

      onComplete();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        onError('已取消');
      } else {
        onError(e.message ?? '下载失败');
      }
    } catch (e) {
      onError(e.toString());
    } finally {
      _cancelTokens.remove(task.id);
    }
  }

  /// 取消下载
  void cancel(String taskId) {
    _cancelTokens[taskId]?.cancel();
    _cancelTokens.remove(taskId);
  }

  /// 暂停（实际是取消，可恢复）
  void pause(String taskId) {
    cancel(taskId);
  }
}
