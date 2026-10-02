import 'dart:convert';
import 'package:dio/dio.dart';
import '../../models/share_platform.dart';
import 'platform_constants.dart';

/// UC 网盘 API（与夸克结构类似，移植自 YunX UCApi.kt）
class UCApi {
  final Dio _dio;
  UCApi(this._dio);

  Future<String?> fetchNickname(String cookie) async {
    try {
      final resp = await _dio.get(
        UCConstants.accountInfoUrl,
        options: Options(headers: {
          'Cookie': cookie,
          'User-Agent': UCConstants.cloudUa,
        }),
      );
      final data = resp.data;
      if (data is Map && data['success'] == true) {
        return data['data']?['nickname'];
      }
    } catch (_) {}
    return null;
  }

  Future<String?> getShareToken(
      String shareId, String? pwd, String cookie) async {
    try {
      final body = {
        'pwd_id': shareId,
        'passcode': pwd ?? '',
        'support_visit_limit_private_share': true,
      };
      final resp = await _dio.post(
        UCConstants.shareTokenUrl,
        data: jsonEncode(body),
        options: Options(headers: {
          'Cookie': cookie,
          'User-Agent': UCConstants.cloudUa,
          'Content-Type': 'application/json',
          'Referer': UCConstants.downloadReferer,
        }),
      );
      final data = resp.data;
      if (data is Map && data['status'] == 200) {
        return data['data']?['stoken'];
      }
    } catch (_) {}
    return null;
  }

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
        UCConstants.shareDetailUrl,
        queryParameters: params,
        options: Options(headers: {
          'Cookie': cookie,
          'User-Agent': UCConstants.cloudUa,
          'Referer': UCConstants.downloadReferer,
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

  Future<DownloadLink?> getDownloadLink(
      String shareId, String stoken, String fid, String cookie) async {
    try {
      final body = {
        'pwd_id': shareId,
        'stoken': stoken,
        'fids': [fid],
      };
      final resp = await _dio.post(
        UCConstants.downloadUrl,
        data: jsonEncode(body),
        options: Options(headers: {
          'Cookie': cookie,
          'User-Agent': UCConstants.cloudUa,
          'Content-Type': 'application/json',
          'Referer': UCConstants.downloadReferer,
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
                'User-Agent': UCConstants.cloudUa,
                'Referer': UCConstants.downloadReferer,
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
