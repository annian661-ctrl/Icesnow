import 'dart:convert';
import 'package:dio/dio.dart';
import '../../models/share_platform.dart';
import 'platform_constants.dart';

/// 迅雷网盘 API（移植自 YunX XunleiApi.kt）
class XunleiApi {
  final Dio _dio;
  XunleiApi(this._dio);

  /// 账号密码登录
  Future<Map<String, dynamic>?> login(
      String username, String password) async {
    try {
      final resp = await _dio.post(
        XunleiConstants.loginUrl,
        data: jsonEncode({
          'username': username,
          'password': password,
          'client_id': XunleiConstants.clientId,
          'client_secret': XunleiConstants.clientSecret,
        }),
        options: Options(headers: {
          'User-Agent': XunleiConstants.webUa,
          'Content-Type': 'application/json',
        }),
      );
      if (resp.data is Map) return resp.data;
    } catch (_) {}
    return null;
  }

  /// 发送短信验证码
  Future<bool> sendSms(String phone) async {
    try {
      final resp = await _dio.post(
        XunleiConstants.sendSmsUrl,
        data: jsonEncode({
          'mobile': phone,
          'client_id': XunleiConstants.clientId,
        }),
        options: Options(headers: {
          'User-Agent': XunleiConstants.webUa,
          'Content-Type': 'application/json',
        }),
      );
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 短信验证码登录
  Future<Map<String, dynamic>?> smsLogin(String phone, String code) async {
    try {
      final resp = await _dio.post(
        XunleiConstants.smsLoginUrl,
        data: jsonEncode({
          'mobile': phone,
          'code': code,
          'client_id': XunleiConstants.clientId,
          'client_secret': XunleiConstants.clientSecret,
        }),
        options: Options(headers: {
          'User-Agent': XunleiConstants.webUa,
          'Content-Type': 'application/json',
        }),
      );
      if (resp.data is Map) return resp.data;
    } catch (_) {}
    return null;
  }

  /// 获取分享文件
  Future<List<ShareFile>> getShareFiles(
      String shareId, String? passCode, String token) async {
    try {
      final params = {
        'share_id': shareId,
        if (passCode != null) 'pass_code': passCode,
        'thumbnail_size': '200,200',
        'limit': 100,
      };
      final resp = await _dio.get(
        XunleiConstants.shareUrl,
        queryParameters: params,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'User-Agent': XunleiConstants.webUa,
        }),
      );
      final data = resp.data;
      if (data is Map) {
        final files = data['files'] as List? ?? [];
        return files
            .map((e) => ShareFile(
                  fid: e['id']?.toString() ?? '',
                  name: e['name']?.toString() ?? '',
                  size: (e['size'] is num) ? e['size'].toInt() : 0,
                  isDir: e['kind'] == 'drive#folder',
                ))
            .toList();
      }
    } catch (_) {}
    return [];
  }

  /// 获取下载直链
  Future<DownloadLink?> getDownloadLink(
      String fileId, String token) async {
    try {
      final resp = await _dio.get(
        '${XunleiConstants.filesUrl}/$fileId',
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'User-Agent': XunleiConstants.webUa,
        }),
      );
      final data = resp.data;
      if (data is Map) {
        final url = data['download_url'];
        if (url != null) {
          return DownloadLink(
            url: url,
            fileName: data['name']?.toString() ?? '',
            fileSize: (data['size'] is num) ? data['size'].toInt() : 0,
            headers: {'User-Agent': XunleiConstants.webUa},
          );
        }
      }
    } catch (_) {}
    return null;
  }
}
