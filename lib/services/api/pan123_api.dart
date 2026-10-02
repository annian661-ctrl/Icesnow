import 'dart:convert';
import 'package:dio/dio.dart';
import '../../models/share_platform.dart';
import 'platform_constants.dart';

/// 123 云盘 API（移植自 YunX Pan123Api.kt）
class Pan123Api {
  final Dio _dio;
  Pan123Api(this._dio);

  /// 获取用户信息（验证 token）
  Future<String?> fetchNickname(String token) async {
    try {
      final ts = (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
      final resp = await _dio.get(
        Pan123Constants.userInfoUrl,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'User-Agent': Pan123Constants.webUa,
          'platform': 'web',
          'app-version': '3',
          'timestamp': ts,
        }),
      );
      final data = resp.data;
      if (data is Map && data['code'] == 200) {
        return data['data']?['nickname'] ?? data['data']?['name'];
      }
    } catch (_) {}
    return null;
  }

  /// 获取分享文件列表（匿名）
  Future<List<ShareFile>> getShareFiles(
      String shareKey, String? pwd) async {
    try {
      final params = {
        'shareKey': shareKey,
        if (pwd != null) 'sharePwd': pwd,
        'pageNo': 1,
        'pageSize': 200,
      };
      final resp = await _dio.get(
        Pan123Constants.shareGetUrl,
        queryParameters: params,
        options: Options(headers: {
          'User-Agent': Pan123Constants.webUa,
          'platform': 'web',
          'app-version': '3',
        }),
      );
      final data = resp.data;
      if (data is Map && data['code'] == 200) {
        final list = data['data']?['fileList'] as List? ?? [];
        return list
            .map((e) => ShareFile(
                  fid: e['fileId']?.toString() ?? '',
                  name: e['fileName']?.toString() ?? '',
                  size: (e['size'] is num) ? e['size'].toInt() : 0,
                  isDir: e['type'] == 1,
                ))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// 获取下载直链
  Future<DownloadLink?> getDownloadLink(
      String shareKey, String fileId, String? pwd, String token) async {
    try {
      final ts = (DateTime.now().millisecondsSinceEpoch / 1000).round().toString();
      final body = {
        'shareKey': shareKey,
        'fileId': fileId,
        if (pwd != null) 'sharePwd': pwd,
      };
      final resp = await _dio.post(
        Pan123Constants.shareDownloadInfoUrl,
        data: jsonEncode(body),
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'User-Agent': Pan123Constants.webUa,
          'platform': 'android',
          'app-version': '39',
          'timestamp': ts,
          'Content-Type': 'application/json',
          'Referer': Pan123Constants.downloadReferer,
        }),
      );
      final data = resp.data;
      if (data is Map && data['code'] == 200) {
        final url = data['data']?['downloadUrl'] ?? data['data']?['url'];
        if (url != null) {
          return DownloadLink(
            url: url,
            fileName: data['data']?['fileName']?.toString() ?? '',
            fileSize:
                (data['data']?['size'] is num) ? data['data']['size'].toInt() : 0,
            headers: {
              'User-Agent': Pan123Constants.webUa,
              'Referer': Pan123Constants.downloadReferer,
            },
          );
        }
      }
    } catch (_) {}
    return null;
  }
}
