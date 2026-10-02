import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart';
import '../../models/share_platform.dart';
import 'platform_constants.dart';

/// 139 网盘 API（移植自 YunX C139Api.kt）
class C139Api {
  final Dio _dio;
  C139Api(this._dio);

  /// AES-CBC 加密
  String _aesEncrypt(String plain, String keyStr) {
    final key = Key.fromUtf8(keyStr);
    final iv = IV.fromUtf8(keyStr);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));
    return encrypter.encrypt(plain, iv: iv).base64;
  }

  String _aesDecrypt(String cipherBase64, String keyStr) {
    final key = Key.fromUtf8(keyStr);
    final iv = IV.fromUtf8(keyStr);
    final encrypter = Encrypter(AES(key, mode: AESMode.cbc, padding: 'PKCS7'));
    return encrypter.decrypt64(cipherBase64, iv: iv);
  }

  /// 获取账号信息
  Future<String?> fetchAccount(String cookie) async {
    // 从 cookie 中提取账号
    for (final kv in cookie.split(';')) {
      final trimmed = kv.trim();
      if (trimmed.startsWith('Login_UserNumber=')) {
        return trimmed.substring('Login_UserNumber='.length);
      }
    }
    return null;
  }

  /// 获取分享文件列表
  Future<List<ShareFile>> getShareFiles(
      String linkId, String? pwd, String cookie) async {
    try {
      final auth = _extractAuthorization(cookie);
      final payload = jsonEncode({
        'linkID': linkId,
        'accessCode': pwd ?? '',
        'pageNum': 1,
        'pageSize': 200,
      });
      final encrypted = _aesEncrypt(payload, C139Constants.shareAesKey);
      final resp = await _dio.post(
        C139Constants.shareListUrl,
        data: jsonEncode({'data': encrypted}),
        options: Options(headers: {
          'Authorization': auth ?? '',
          'User-Agent': C139Constants.pcUa,
          'Content-Type': 'application/json',
          'mcloud-channel': '1000101',
          'x-yun-client-info': C139Constants.X_CLIENT_INFO,
        }),
      );
      final data = resp.data;
      if (data is Map && data['result'] == 0) {
        final decrypted = _aesDecrypt(data['data'], C139Constants.shareAesKey);
        final result = jsonDecode(decrypted) as Map;
        final list = result['contentList'] as List? ?? [];
        return list
            .map((e) => ShareFile(
                  fid: e['contentID']?.toString() ?? '',
                  name: e['contentName']?.toString() ?? '',
                  size: (e['contentSize'] is num) ? e['contentSize'].toInt() : 0,
                  isDir: e['contentType'] == 0,
                ))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// 获取下载直链
  Future<DownloadLink?> getDownloadLink(
      String linkId, String contentId, String cookie) async {
    try {
      final auth = _extractAuthorization(cookie);
      final payload = jsonEncode({
        'linkID': linkId,
        'contentID': contentId,
      });
      final encrypted = _aesEncrypt(payload, C139Constants.shareAesKey);
      final resp = await _dio.post(
        C139Constants.shareLinkUrl,
        data: jsonEncode({'data': encrypted}),
        options: Options(headers: {
          'Authorization': auth ?? '',
          'User-Agent': C139Constants.pcUa,
          'Content-Type': 'application/json',
        }),
      );
      final data = resp.data;
      if (data is Map && data['result'] == 0) {
        final decrypted = _aesDecrypt(data['data'], C139Constants.shareAesKey);
        final result = jsonDecode(decrypted) as Map;
        final url = result['downloadURL'] ?? result['url'];
        if (url != null) {
          return DownloadLink(
            url: url,
            fileName: result['contentName']?.toString() ?? '',
            fileSize: (result['contentSize'] is num)
                ? result['contentSize'].toInt()
                : 0,
            headers: {'User-Agent': C139Constants.pcUa},
          );
        }
      }
    } catch (_) {}
    return null;
  }

  String? _extractAuthorization(String cookie) {
    for (final kv in cookie.split(';')) {
      final trimmed = kv.trim();
      if (trimmed.startsWith('authorization=')) {
        final v = trimmed.substring('authorization='.length);
        if (v.isNotEmpty) return v;
      }
    }
    return null;
  }
}
