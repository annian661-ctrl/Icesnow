/// 各网盘平台常量（移植自 YunX）
class QuarkConstants {
  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36 QuarkPC/6.0.8.649';
  static const String apiUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) quark-cloud-drive/2.5.20 Chrome/100.0.4896.160 Electron/18.3.5.12-a038f7b798 Safari/537.36 Channel/pckk_other_ch';
  static const String loginUrl = 'https://pan.quark.cn/?fr=pc&platform=pc';
  static const String cookieDomain = 'https://pan.quark.cn';
  static const String accountInfoUrl = 'https://pan.quark.cn/account/info';
  static const String apiBase = 'https://drive-pc.quark.cn';
  static const String shareTokenUrl =
      '$apiBase/1/clouddrive/share/sharepage/token?pr=ucpro&fr=pc';
  static const String sharePasswordUrl =
      '$apiBase/1/clouddrive/share/password?pr=ucpro&fr=pc';
  static const String shareDetailUrl =
      '$apiBase/1/clouddrive/share/sharepage/detail?pr=ucpro&fr=pc';
  static const String downloadUrl =
      '$apiBase/1/clouddrive/file/download?pr=ucpro&fr=pc&sys=win32&ve=3.23.2';
  static const String defaultPdirFid = '0';
  static const String downloadReferer = 'https://pan.quark.cn/';

  static bool isValidCookie(String? cookie) =>
      cookie != null &&
      cookie.contains('__pus=') &&
      cookie.contains('__puus=');
}

class UCConstants {
  static const String userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  static const String webOrigin = 'https://drive.uc.cn';
  static const String downloadReferer = '$webOrigin/';
  static const String loginUrl = 'https://drive.uc.cn/';
  static const String cookieDomain = 'https://drive.uc.cn';
  static const String accountInfoUrl = 'https://drive.uc.cn/account/info';
  static const String apiBase = 'https://pc-api.uc.cn';
  static const String shareTokenUrl =
      '$apiBase/1/clouddrive/share/sharepage/token?pr=UCBrowser&fr=pc';
  static const String shareDetailUrl =
      '$apiBase/1/clouddrive/share/sharepage/v2/detail?pr=UCBrowser&fr=pc';
  static const String downloadUrl =
      '$apiBase/1/clouddrive/file/download?entry=ft&fr=pc&pr=UCBrowser';
  static const String defaultPdirFid = '0';
  static const String cloudUa =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) uc-cloud-drive/1.6.1 Chrome/100.0.4896.160 Electron/18.3.5.16-b62cf9c50d Safari/537.36 Channel/ucpan_other_ch';

  static bool isValidCookie(String? cookie) =>
      cookie != null &&
      cookie.contains('__pus=') &&
      cookie.contains('__puus=');
}

class BaiduConstants {
  static const String loginUrl = 'https://pan.baidu.com/';
  static const String cookieDomain = 'https://pan.baidu.com';
  static const String uaWeb =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';
  static const String uaNetdisk =
      'netdisk;12.24.6;piano;android-android;16;JSbridge4.4.0;jointBridge;1.1.0';
  static const String appId = '250528';

  static bool isValidCookie(String? cookie) =>
      cookie != null && cookie.contains('BDUSS=');
}

class XunleiConstants {
  static const String authBase = 'https://xluser-ssl.xunlei.com';
  static const String panBase = 'https://api-pan.xunlei.com';
  static const String clientId = 'Xp6pAdwyJv9sQuoN';
  static const String clientSecret = 'standard_a@api#';
  static const String webUa = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36';
  static const String captchaInitUrl = '$authBase/v1/shield/captcha/init';
  static const String loginUrl = '$authBase/xluser.core.login/v3/login';
  static const String sendSmsUrl = '$authBase/xluser.core.login/v3/sendsms';
  static const String smsLoginUrl = '$authBase/xluser.core.login/v3/smslogin';
  static const String tokenUrl = '$authBase/v1/auth/signin/token';
  static const String refreshUrl = '$authBase/v1/auth/token';
  static const String filesUrl = '$panBase/drive/v1/files';
  static const String shareUrl = '$panBase/drive/v1/share';
  static const String shareDetailUrl = '$panBase/drive/v1/share/detail';
  static const String restoreUrl = '$panBase/drive/v1/share/restore';
}

class C139Constants {
  static const String loginUrl = 'https://yun.139.com/';
  static const String cookieDomain = 'https://mail.10086.cn';
  static const String cookieDomainBackup = 'https://yun.139.com';
  static const String shareBase = 'https://share-kd-njs.yun.139.com';
  static const String shareListUrl =
      '$shareBase/yun-share/richlifeApp/devapp/IOutLink/getOutLinkInfoV6';
  static const String shareLinkUrl =
      '$shareBase/yun-share/richlifeApp/devapp/IOutLink/dlFromOutLinkV3';
  static const String pcUa =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  static const String shareAesKey = 'PVGDwmcvfs1uV3d1';
  static const String X_CLIENT_INFO =
      '||9|7.17.9|chrome|116.0.0.0|2cdaf7ada9e353c70eba99092e177991||windows 10||zh-CN|||dW5kZWZpbmVk||';

  static bool isValidCookie(String? cookie) {
    if (cookie == null || cookie.isEmpty) return false;
    if (cookie.contains('authorization=')) return true;
    return cookie.contains('Os_SSo_Sid=') && cookie.contains('RMKEY=');
  }
}

class Pan123Constants {
  static const String apiBase = 'https://yun.123pan.cn';
  static const String downloadBase = 'https://www.123865.com';
  static const String webLoginUrl = 'https://yun.123pan.cn/';
  static const String localStorageTokenKey = 'authorToken';
  static const String shareGetUrl = '$apiBase/b/api/share/get';
  static const String shareDownloadInfoUrl =
      '$downloadBase/b/api/share/download/info';
  static const String fileListUrl = '$apiBase/b/api/file/list/new';
  static const String userInfoUrl = '$apiBase/b/api/user/info';
  static const String webUa =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36';
  static const String downloadReferer = 'https://yun.123pan.cn/';
}

class TianyiConstants {
  static const String loginUrl = 'https://cloud.189.cn/';
  static const String webUa =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  static const String cookieDomain = 'https://cloud.189.cn';
  static const String apiBase = 'https://cloud.189.cn/api';

  static bool isValidCookie(String? cookie) =>
      cookie != null && cookie.contains('COOKIE_LOGIN_USER=');
}

class LanzouConstants {
  static const String loginUrl = 'https://pc.woozooo.com/';
  static const String webUa =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  static const String cookieDomain = 'https://www.lanzou.com';
  static const String apiBase = 'https://pc.woozooo.com';

  static bool isValidCookie(String? cookie) =>
      cookie != null && cookie.contains('ylogin=');
}

class AlipanConstants {
  static const String loginUrl = 'https://www.alipan.com/';
  static const String webUa =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  static const String cookieDomain = 'https://www.alipan.com';
  static const String apiBase = 'https://api.alipan.com';
  static const String userInfoUrl = 'https://user.aliyundrive.com/v2/user/get';

  static bool isValidCookie(String? cookie) =>
      cookie != null && cookie.contains('refresh_token=');
}
