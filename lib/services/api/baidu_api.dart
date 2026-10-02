import 'dart:convert';
import 'package:dio/dio.dart';
import '../../models/share_platform.dart';
import 'platform_constants.dart';

/// 百度网盘 API（移植自 YunX BaiduApi.kt）
class BaiduApi {
  final Dio _dio;
  BaiduApi(this._dio);

  /// 验证登录态，获取昵称
  Future<String?> fetchNickname(String cookie) async {
    try {
      final resp = await _dio.get(
        'https://pan.baidu.com/rest/2.0/xpan/nas?method=uinfo',
        options: Options(headers: {
          'Cookie': cookie,
          'User-Agent': BaiduConstants.uaWeb,
        }),
      );
      final data = resp.data;
      if (data is Map && data['errno'] == 0) {
        return data['baidu_name'] ?? data['netdisk_name'];
      }
    } catch (_) {}
    return null;
  }

  /// 分享验证（获取 randsk/sk）
  Future<String?> verifyShare(
      String surl, String? pwd, String cookie) async {
    try {
      final resp = await _dio.post(
        'https://pan.baidu.com/share/verify?surl=$surl&channel=chunlei&web=1&app_id=${BaiduConstants.appId}',
        data: 'pwd=${pwd ?? ''}&vcode=&vcode_str=',
        options: Options(headers: {
          'Cookie': cookie,
          'User-Agent': BaiduConstants.uaWeb,
          'Content-Type': 'application/x-www-form-urlencoded',
          'Referer': 'https://pan.baidu.com/',
        }),
      );
      final data = resp.data;
      if (data is Map && data['errno'] == 0) {
        return data['randsk'];
      }
    } catch (_) {}
    return null;
  }

  /// 获取分享文件列表
  Future<List<ShareFile>> getShareFiles(
      String surl, String randsk, String cookie,
      {String dir = '/'}) async {
    try {
      final params = {
        'shareid': '',
        'from': '',
        'bdstoken': '',
        'channel': 'chunlei',
        'web': '1',
        'app_id': BaiduConstants.appId,
        'logid': '',
        'clienttype': '0',
      };
      final resp = await _dio.get(
        'https://pan.baidu.com/s/1$surl',
        queryParameters: params,
        options: Options(headers: {
          'Cookie': '$cookie; BDCLND=$randsk',
          'User-Agent': BaiduConstants.uaWeb,
          'Referer': 'https://pan.baidu.com/',
        }),
      );
      // 百度分享页需要解析 HTML 中的 yunData
      final body = resp.data.toString();
      final match = RegExp(r'yunData\.setData\((\{.*?\})\);').firstMatch(body);
      if (match != null) {
        final jsonStr = match.group(1)!;
        final yunData = jsonDecode(jsonStr) as Map;
        final fileList = yunData['file_list'] as List? ?? [];
        return fileList
            .map((e) => ShareFile(
                  fid: e['fs_id']?.toString() ?? '',
                  name: e['server_filename']?.toString() ?? '',
                  size: (e['size'] is num) ? e['size'].toInt() : 0,
                  isDir: e['isdir'] == 1,
                ))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// 获取下载直链
  Future<DownloadLink?> getDownloadLink(
      String fsId, String cookie, String randsk) async {
    try {
      final resp = await _dio.post(
        'https://pan.baidu.com/api/sharedownload?channel=chunlei&web=1&app_id=${BaiduConstants.appId}&sign=&timestamp=',
        data: 'fid_list=[$fsId]&type=dlink',
        options: Options(headers: {
          'Cookie': '$cookie; BDCLND=$randsk',
          'User-Agent': BaiduConstants.uaWeb,
          'Content-Type': 'application/x-www-form-urlencoded',
          'Referer': 'https://pan.baidu.com/',
        }),
      );
      final data = resp.data;
      if (data is Map && data['errno'] == 0) {
        final list = data['list'] as List? ?? [];
        if (list.isNotEmpty) {
          final dlink = list[0]['dlink'];
          final fileName = list[0]['server_filename'] ?? '';
          if (dlink != null) {
            return DownloadLink(
              url: dlink,
              fileName: fileName,
              fileSize: (list[0]['size'] is num) ? list[0]['size'].toInt() : 0,
              headers: {
                'User-Agent': BaiduConstants.uaNetdisk,
                'Referer': 'https://pan.baidu.com/',
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
