import 'dart:convert';
import 'package:dio/dio.dart';
import '../../models/share_platform.dart';
import 'platform_constants.dart';

/// 夸克网盘 API（移植自 YunX QuarkApi.kt）
class QuarkApi {
  final Dio _dio;
  QuarkApi(this._dio);

  /// 获取昵称
  Future<String?> fetchNickname(String cookie) async {
    try {
      final resp = await _dio.get(
        QuarkConstants.accountInfoUrl,
        options: Options(headers: {
          'Cookie': cookie,
          'User-Agent': QuarkConstants.apiUserAgent,
        }),
      );
      final data = resp.data;
      if (data is Map && data['success'] == true) {
        return data['data']?['nickname'];
      }
    } catch (_) {}
    return null;
  }

  /// 获取分享 token
  Future<String?> getShareToken(
      String shareId, String? pwd, String cookie) async {
    try {
      final body = {
        'pwd_id': shareId,
        'passcode': pwd ?? '',
        'support_visit_limit_private_share': true,
      };
      final resp = await _dio.post(
        QuarkConstants.shareTokenUrl,
        data: jsonEncode(body),
        options: Options(headers: {
          'Cookie': cookie,
          'User-Agent': QuarkConstants.apiUserAgent,
          'Content-Type': 'application/json',
          'Referer': QuarkConstants.downloadReferer,
        }),
      );
      final data = resp.data;
      if (data is Map && data['status'] == 200) {
        return data['data']?['stoken'];
      }
    } catch (_) {}
    return null;
  }

  /// 获取分享文件列表
  Future<List<ShareFile>> getShareFiles(
      String shareId, String stoken, String cookie,
      {String pwdId = '0'}) async {
    try {
      final params = {
        'pwd_id': shareId,
        'stoken': stoken,
        'pdir_fid': pwdId,
        'page': 1,
        'size': 200,
      };
      final resp = await _dio.get(
        QuarkConstants.shareDetailUrl,
        queryParameters: params,
        options: Options(headers: {
          'Cookie': cookie,
          'User-Agent': QuarkConstants.apiUserAgent,
          'Referer': QuarkConstants.downloadReferer,
        }),
      );
      final data = resp.data;
      if (data is Map && data['status'] == 200) {
        final list = data['data']?['list'] as List? ?? [];
        return list
            .map((e) => ShareFile(
                  fid: e['fid']?.toString() ?? '',
                  name: e['file_name']?.toString() ?? e['name']?.toString() ?? '',
                  size: (e['size'] is num) ? e['size'].toInt() : 0,
                  isDir: e['dir'] == true || e['is_dir'] == true,
                ))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// 获取下载直链
  Future<DownloadLink?> getDownloadLink(
      String shareId, String stoken, String fid, String cookie) async {
    try {
      final body = {
        'pwd_id': shareId,
        'stoken': stoken,
        'fids': [fid],
      };
      final resp = await _dio.post(
        QuarkConstants.downloadUrl,
        data: jsonEncode(body),
        options: Options(headers: {
          'Cookie': cookie,
          'User-Agent': QuarkConstants.apiUserAgent,
          'Content-Type': 'application/json',
          'Referer': QuarkConstants.downloadReferer,
        }),
      );
      final data = resp.data;
      if (data is Map && data['status'] == 200) {
        final item = data['data']?[0];
        if (item != null) {
          final url = item['download_url'] ?? item['url'];
          final fileName = item['file_name'] ?? item['name'] ?? '';
          final size = (item['size'] is num) ? item['size'].toInt() : 0;
          if (url != null) {
            return DownloadLink(
              url: url,
              fileName: fileName,
              fileSize: size,
              headers: {
                'User-Agent': QuarkConstants.apiUserAgent,
                'Referer': QuarkConstants.downloadReferer,
                'Cookie': cookie,
              },
            );
          }
        }
      }
    } catch (_) {}
    return null;
  }
}
