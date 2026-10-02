import '../models/share_platform.dart';

/// 分享链接解析器（移植自 YunX ShareLinkParser.kt）
class ShareLinkParser {
  static final RegExp _urlRegex = RegExp(r'https?://[^\s]+');
  static final RegExp _quarkRegex =
      RegExp(r'pan\.quark\.cn/s/([A-Za-z0-9]+)', caseSensitive: false);
  static final RegExp _ucRegex =
      RegExp(r'drive\.uc\.cn/s/([A-Za-z0-9]+)', caseSensitive: false);
  static final RegExp _xunleiRegex =
      RegExp(r'pan\.xunlei\.com/s/([A-Za-z0-9_-]+)', caseSensitive: false);
  static final RegExp _baiduRegex =
      RegExp(r'pan\.baidu\.com/s/(1[A-Za-z0-9_-]+)', caseSensitive: false);
  static final RegExp _c139Regex = RegExp(
      r'yun\.139\.com/shareweb/.*?/w/i/([A-Za-z0-9_-]+)',
      caseSensitive: false);
  static final RegExp _pan123Regex = RegExp(
      r'123(?:865|pan)\.(?:com|cn)/s/([A-Za-z0-9]+-[A-Za-z0-9]+)',
      caseSensitive: false);
  static final RegExp _pan123SubRegex =
      RegExp(r'share\.123pan\.cn/123pan/([A-Za-z0-9-]+)', caseSensitive: false);
  static final RegExp _pan123SrrRegex =
      RegExp(r'api/srr\?sk=([A-Za-z0-9-]+)', caseSensitive: false);
  static final RegExp _tianyiRegex =
      RegExp(r'cloud\.189\.cn/t/([A-Za-z0-9]+)', caseSensitive: false);
  static final RegExp _lanzouRegex =
      RegExp(r'(?:www\.)?lanzou(?:s)?\.com/([A-Za-z0-9]+)', caseSensitive: false);
  static final RegExp _alipanRegex =
      RegExp(r'(?:www\.)?(?:alipan|aliyundrive)\.com/s/([A-Za-z0-9]+)', caseSensitive: false);
  static final RegExp _pwdInUrlRegex = RegExp(r'[?&]pwd=([A-Za-z0-9]+)');
  static final RegExp _pwdInTextRegex =
      RegExp(r'(?:提取码|访问码|密码)[：:]\s*([A-Za-z0-9]{4,8})');
  // BT / 磁力 / ed2k / 迅雷
  static final RegExp _magnetRegex =
      RegExp(r'magnet:\?[^\s]+', caseSensitive: false);
  static final RegExp _ed2kRegex =
      RegExp(r'ed2k://[^\s]+', caseSensitive: false);
  static final RegExp _thunderRegex =
      RegExp(r'thunder://[^\s]+', caseSensitive: false);

  /// 是否为 BT/磁力/ed2k/迅雷 直链（无需网盘解析）
  static bool isDirectLink(String text) {
    final t = text.trim();
    return _magnetRegex.hasMatch(t) ||
        _ed2kRegex.hasMatch(t) ||
        _thunderRegex.hasMatch(t);
  }

  /// 提取直链 URL
  static String? extractDirectLink(String text) {
    final t = text.trim();
    final m = _magnetRegex.firstMatch(t);
    if (m != null) return m.group(0);
    final e = _ed2kRegex.firstMatch(t);
    if (e != null) return e.group(0);
    final th = _thunderRegex.firstMatch(t);
    if (th != null) return th.group(0);
    return null;
  }

  /// 从文本中解析分享链接
  static ParsedShare? parse(String text) {
    final trimmed = text.trim();
    final urlMatch = _urlRegex.firstMatch(trimmed);
    if (urlMatch == null) return null;
    var url = urlMatch.group(0)!;
    url = url.replaceAll(RegExp(r'[。，,；;)\]}]+$'), '');
    // 去掉末尾引号
    if (url.endsWith('"')) url = url.substring(0, url.length - 1);
    if (url.endsWith("'")) url = url.substring(0, url.length - 1);

    String? extractPwd() {
      final urlPwd = _pwdInUrlRegex.firstMatch(url)?.group(1);
      if (urlPwd != null) return urlPwd;
      return _pwdInTextRegex.firstMatch(text)?.group(1);
    }

    // 夸克
    final q = _quarkRegex.firstMatch(url);
    if (q != null) {
      return ParsedShare(
        shareId: q.group(1)!,
        pwd: extractPwd(),
        platform: SharePlatform.quark,
      );
    }
    // UC
    final u = _ucRegex.firstMatch(url);
    if (u != null) {
      return ParsedShare(
        shareId: u.group(1)!,
        pwd: extractPwd(),
        platform: SharePlatform.uc,
      );
    }
    // 迅雷
    final x = _xunleiRegex.firstMatch(url);
    if (x != null) {
      return ParsedShare(
        shareId: x.group(1)!,
        pwd: extractPwd(),
        platform: SharePlatform.xunlei,
      );
    }
    // 百度
    final b = _baiduRegex.firstMatch(url);
    if (b != null) {
      // 百度 surl 不包含开头的 "1"
      final sid = b.group(1)!.replaceFirst(RegExp(r'^1'), '');
      return ParsedShare(
        shareId: sid,
        pwd: extractPwd(),
        platform: SharePlatform.baidu,
      );
    }
    // 139
    final c = _c139Regex.firstMatch(url);
    if (c != null) {
      return ParsedShare(
        shareId: c.group(1)!,
        pwd: extractPwd(),
        platform: SharePlatform.c139,
      );
    }
    // 123
    final p1 = _pan123Regex.firstMatch(url);
    if (p1 != null) {
      return ParsedShare(
        shareId: p1.group(1)!,
        pwd: extractPwd(),
        platform: SharePlatform.pan123,
      );
    }
    final p2 = _pan123SubRegex.firstMatch(url);
    if (p2 != null) {
      return ParsedShare(
        shareId: p2.group(1)!,
        pwd: extractPwd(),
        platform: SharePlatform.pan123,
      );
    }
    final p3 = _pan123SrrRegex.firstMatch(url);
    if (p3 != null) {
      return ParsedShare(
        shareId: p3.group(1)!,
        pwd: extractPwd(),
        platform: SharePlatform.pan123,
      );
    }
    // 天翼云盘
    final t = _tianyiRegex.firstMatch(url);
    if (t != null) {
      return ParsedShare(
        shareId: t.group(1)!,
        pwd: extractPwd(),
        platform: SharePlatform.tianyi,
      );
    }
    // 蓝奏云
    final l = _lanzouRegex.firstMatch(url);
    if (l != null) {
      return ParsedShare(
        shareId: l.group(1)!,
        pwd: extractPwd(),
        platform: SharePlatform.lanzou,
      );
    }
    // 阿里云盘
    final a = _alipanRegex.firstMatch(url);
    if (a != null) {
      return ParsedShare(
        shareId: a.group(1)!,
        pwd: extractPwd(),
        platform: SharePlatform.alipan,
      );
    }
    return null;
  }

  /// 判断文本是否包含可识别的分享链接
  static bool containsShareLink(String text) => parse(text) != null;
}
