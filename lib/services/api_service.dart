import 'package:dio/dio.dart';
import '../models/share_platform.dart';
import 'api/quark_api.dart';
import 'api/uc_api.dart';
import 'api/baidu_api.dart';
import 'api/xunlei_api.dart';
import 'api/c139_api.dart';
import 'api/pan123_api.dart';
import 'api/platform_constants.dart';

/// 统一网盘 API 服务
class ApiService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 60),
    sendTimeout: const Duration(seconds: 30),
  ));

  late final QuarkApi _quark = QuarkApi(_dio);
  late final UCApi _uc = UCApi(_dio);
  late final BaiduApi _baidu = BaiduApi(_dio);
  late final XunleiApi _xunlei = XunleiApi(_dio);
  late final C139Api _c139 = C139Api(_dio);
  late final Pan123Api _pan123 = Pan123Api(_dio);

  /// 获取昵称
  Future<String?> fetchNickname(SharePlatform platform, String credential) async {
    switch (platform) {
      case SharePlatform.quark:
        return _quark.fetchNickname(credential);
      case SharePlatform.uc:
        return _uc.fetchNickname(credential);
      case SharePlatform.baidu:
        return _baidu.fetchNickname(credential);
      case SharePlatform.xunlei:
        try {
          final resp = await _dio.get(
            'https://api-pan.xunlei.com/drive/v1/user/me',
            options: Options(headers: {'Authorization': 'Bearer $credential'}),
          );
          final data = resp.data;
          if (data is Map) return data['nickname'] ?? data['name'];
        } catch (_) {}
        return null;
      case SharePlatform.c139:
        return _c139.fetchAccount(credential);
      case SharePlatform.pan123:
        return _pan123.fetchNickname(credential);
      case SharePlatform.tianyi:
        if (credential.contains('COOKIE_LOGIN_USER=')) {
          return '天翼云盘用户';
        }
        return null;
      case SharePlatform.lanzou:
        if (credential.contains('ylogin=')) return '蓝奏云用户';
        return null;
      case SharePlatform.alipan:
        try {
          final resp = await _dio.post(
            AlipanConstants.userInfoUrl,
            options: Options(headers: {
              'Authorization': 'Bearer $credential',
              'Content-Type': 'application/json',
            }),
          );
          final data = resp.data;
          if (data is Map) return data['nick_name'] ?? data['name'] ?? '阿里云盘用户';
        } catch (_) {}
        return null;
    }
  }

  /// 获取网盘容量信息 (total, used)
  Future<(int total, int used)?> fetchStorage(
      SharePlatform platform, String credential) async {
    try {
      switch (platform) {
        case SharePlatform.quark:
          final resp = await _dio.get(
            QuarkConstants.accountInfoUrl,
            options: Options(headers: {
              'Cookie': credential,
              'User-Agent': QuarkConstants.apiUserAgent,
            }),
          );
          final data = resp.data;
          if (data is Map && data['success'] == true) {
            final d = data['data'];
            if (d is Map) {
              final total = (d['total_space'] ?? d['totalSpace'] ?? 0);
              final used = (d['used_space'] ?? d['usedSpace'] ?? 0);
              return (
                (total is num) ? total.toInt() : 0,
                (used is num) ? used.toInt() : 0,
              );
            }
          }
          break;
        case SharePlatform.uc:
          final resp = await _dio.get(
            UCConstants.accountInfoUrl,
            options: Options(headers: {
              'Cookie': credential,
              'User-Agent': UCConstants.cloudUa,
            }),
          );
          final data = resp.data;
          if (data is Map && data['success'] == true) {
            final d = data['data'];
            if (d is Map) {
              final total = (d['total_space'] ?? 0);
              final used = (d['used_space'] ?? 0);
              return (
                (total is num) ? total.toInt() : 0,
                (used is num) ? used.toInt() : 0,
              );
            }
          }
          break;
        case SharePlatform.baidu:
          final resp = await _dio.get(
            'https://pan.baidu.com/api/quota',
            queryParameters: {'checkfree': 1, 'checkexpire': 1},
            options: Options(headers: {
              'Cookie': credential,
              'User-Agent': BaiduConstants.uaWeb,
            }),
          );
          final data = resp.data;
          if (data is Map) {
            final total = (data['total'] ?? 0);
            final used = (data['used'] ?? 0);
            return (
              (total is num) ? total.toInt() : 0,
              (used is num) ? used.toInt() : 0,
            );
          }
          break;
        case SharePlatform.pan123:
          final resp = await _dio.get(
            Pan123Constants.userInfoUrl,
            options: Options(headers: {
              'Authorization': credential,
              'User-Agent': Pan123Constants.webUa,
            }),
          );
          final data = resp.data;
          if (data is Map && data['code'] == 200) {
            final d = data['data'];
            if (d is Map) {
              final total = (d['totalSpace'] ?? d['total_space'] ?? 0);
              final used = (d['usedSpace'] ?? d['used_space'] ?? 0);
              return (
                (total is num) ? total.toInt() : 0,
                (used is num) ? used.toInt() : 0,
              );
            }
          }
          break;
        case SharePlatform.xunlei:
          final resp = await _dio.get(
            'https://api-pan.xunlei.com/drive/v1/user/me',
            options: Options(headers: {'Authorization': 'Bearer $credential'}),
          );
          final data = resp.data;
          if (data is Map) {
            final total = (data['total_capacity'] ?? data['spaceInfo']?['total'] ?? 0);
            final used = (data['used_capacity'] ?? data['spaceInfo']?['used'] ?? 0);
            return (
              (total is num) ? total.toInt() : 0,
              (used is num) ? used.toInt() : 0,
            );
          }
          break;
        case SharePlatform.alipan:
          final resp = await _dio.post(
            AlipanConstants.userInfoUrl,
            options: Options(headers: {
              'Authorization': 'Bearer $credential',
              'Content-Type': 'application/json',
            }),
          );
          final data = resp.data;
          if (data is Map) {
            final d = data['data'] ?? data;
            if (d is Map) {
              final total = (d['total_size'] ?? d['totalSpace'] ?? 0);
              final used = (d['used_size'] ?? d['usedSpace'] ?? 0);
              return (
                (total is num) ? total.toInt() : 0,
                (used is num) ? used.toInt() : 0,
              );
            }
          }
          break;
        default:
          break;
      }
    } catch (_) {}
    return null;
  }

  /// 获取网盘文件列表（个人网盘，非分享）
  Future<List<ShareFile>> getCloudFiles(
    SharePlatform platform,
    String credential, {
    String parentId = '0',
  }) async {
    try {
      switch (platform) {
        case SharePlatform.quark:
          final resp = await _dio.get(
            '${QuarkConstants.apiBase}/1/clouddrive/file/sort',
            queryParameters: {
              'pdir_fid': parentId,
              '_size': 200,
              '_fetch_total': 1,
              'fr': 'pc',
              'pr': 'ucpro',
            },
            options: Options(headers: {
              'Cookie': credential,
              'User-Agent': QuarkConstants.apiUserAgent,
            }),
          );
          final data = resp.data;
          if (data is Map && data['status'] == 200) {
            final list = data['data']?['list'] as List? ?? [];
            return list.map((e) => ShareFile(
              fid: e['fid']?.toString() ?? '',
              name: e['file_name']?.toString() ?? e['name']?.toString() ?? '',
              size: (e['size'] is num) ? e['size'].toInt() : 0,
              isDir: e['dir'] == true || e['is_dir'] == true,
            )).toList();
          }
          break;
        case SharePlatform.baidu:
          final resp = await _dio.get(
            'https://pan.baidu.com/api/list',
            queryParameters: {
              'dir': parentId == '0' ? '/' : parentId,
              'num': 200,
              'order': 'time',
              'desc': 1,
            },
            options: Options(headers: {
              'Cookie': credential,
              'User-Agent': BaiduConstants.uaWeb,
            }),
          );
          final data = resp.data;
          if (data is Map) {
            final list = data['list'] as List? ?? [];
            return list.map((e) => ShareFile(
              fid: e['fs_id']?.toString() ?? '',
              name: e['server_filename']?.toString() ?? e['name']?.toString() ?? '',
              size: (e['size'] is num) ? e['size'].toInt() : 0,
              isDir: e['isdir'] == 1 || e['is_dir'] == true,
            )).toList();
          }
          break;
        case SharePlatform.pan123:
          final resp = await _dio.get(
            Pan123Constants.fileListUrl,
            queryParameters: {
              'parentFileId': parentId,
              'page': 1,
              'size': 200,
            },
            options: Options(headers: {
              'Authorization': credential,
              'User-Agent': Pan123Constants.webUa,
            }),
          );
          final data = resp.data;
          if (data is Map && data['code'] == 200) {
            final list = data['data']?['list'] as List? ?? [];
            return list.map((e) => ShareFile(
              fid: e['fileId']?.toString() ?? '',
              name: e['fileName']?.toString() ?? '',
              size: (e['size'] is num) ? e['size'].toInt() : 0,
              isDir: e['type'] == 0 || e['dir'] == true,
            )).toList();
          }
          break;
        default:
          break;
      }
    } catch (_) {}
    return [];
  }

  /// 获取分享文件列表
  Future<List<ShareFile>> getShareFiles(
    SharePlatform platform,
    String shareId,
    String? pwd,
    String credential,
  ) async {
    switch (platform) {
      case SharePlatform.quark:
        final stoken = await _quark.getShareToken(shareId, pwd, credential);
        if (stoken == null) return [];
        return _quark.getShareFiles(shareId, stoken, credential);
      case SharePlatform.uc:
        final stoken = await _uc.getShareToken(shareId, pwd, credential);
        if (stoken == null) return [];
        return _uc.getShareFiles(shareId, stoken, credential);
      case SharePlatform.baidu:
        final randsk = await _baidu.verifyShare(shareId, pwd, credential);
        return _baidu.getShareFiles(shareId, randsk ?? '', credential);
      case SharePlatform.xunlei:
        return _xunlei.getShareFiles(shareId, pwd, credential);
      case SharePlatform.c139:
        return _c139.getShareFiles(shareId, pwd, credential);
      case SharePlatform.pan123:
        return _pan123.getShareFiles(shareId, pwd);
      case SharePlatform.tianyi:
      case SharePlatform.lanzou:
      case SharePlatform.alipan:
        // 解析功能开发中
        return [];
    }
  }

  /// 获取下载直链
  Future<DownloadLink?> getDownloadLink(
    SharePlatform platform,
    String shareId,
    String fileId,
    String? pwd,
    String credential,
  ) async {
    switch (platform) {
      case SharePlatform.quark:
        final stoken = await _quark.getShareToken(shareId, pwd, credential);
        if (stoken == null) return null;
        return _quark.getDownloadLink(shareId, stoken, fileId, credential);
      case SharePlatform.uc:
        final stoken = await _uc.getShareToken(shareId, pwd, credential);
        if (stoken == null) return null;
        return _uc.getDownloadLink(shareId, stoken, fileId, credential);
      case SharePlatform.baidu:
        final randsk = await _baidu.verifyShare(shareId, pwd, credential);
        return _baidu.getDownloadLink(fileId, credential, randsk ?? '');
      case SharePlatform.xunlei:
        return _xunlei.getDownloadLink(fileId, credential);
      case SharePlatform.c139:
        return _c139.getDownloadLink(shareId, fileId, credential);
      case SharePlatform.pan123:
        return _pan123.getDownloadLink(shareId, fileId, pwd, credential);
      case SharePlatform.tianyi:
      case SharePlatform.lanzou:
      case SharePlatform.alipan:
        return null;
    }
  }
}
