import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../models/share_platform.dart';
import '../models/cloud_account.dart';
import '../services/api/platform_constants.dart';
import '../providers/providers.dart';

/// 网盘登录页 - 全屏 WebView 桌面 UA，或手动输入 Token
class LoginScreen extends ConsumerStatefulWidget {
  final SharePlatform platform;
  const LoginScreen({super.key, required this.platform});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final WebViewController _controller;
  bool _loading = true;
  bool _saving = false;
  late final TabController _tabController;
  final _tokenController = TextEditingController();

  static const _cookieChannel = MethodChannel('com.icesnow.annian/cookies');

  /// 桌面端 UA
  String get _desktopUA {
    switch (widget.platform) {
      case SharePlatform.quark:
        return QuarkConstants.userAgent;
      case SharePlatform.uc:
        return UCConstants.userAgent;
      case SharePlatform.baidu:
        return BaiduConstants.uaWeb;
      case SharePlatform.c139:
        return C139Constants.pcUa;
      case SharePlatform.pan123:
        return Pan123Constants.webUa;
      case SharePlatform.xunlei:
        return XunleiConstants.webUa;
      case SharePlatform.tianyi:
        return TianyiConstants.webUa;
      case SharePlatform.lanzou:
        return LanzouConstants.webUa;
      case SharePlatform.alipan:
        return AlipanConstants.webUa;
    }
  }

  String get _loginUrl {
    switch (widget.platform) {
      case SharePlatform.quark:
        return QuarkConstants.loginUrl;
      case SharePlatform.uc:
        return UCConstants.loginUrl;
      case SharePlatform.baidu:
        return BaiduConstants.loginUrl;
      case SharePlatform.c139:
        return C139Constants.loginUrl;
      case SharePlatform.pan123:
        return Pan123Constants.webLoginUrl;
      case SharePlatform.xunlei:
        return 'https://pan.xunlei.com/';
      case SharePlatform.tianyi:
        return TianyiConstants.loginUrl;
      case SharePlatform.lanzou:
        return LanzouConstants.loginUrl;
      case SharePlatform.alipan:
        return AlipanConstants.loginUrl;
    }
  }

  String get _credentialHint {
    switch (widget.platform) {
      case SharePlatform.pan123:
        return '请输入 123 云盘的 authorToken（从浏览器 localStorage 获取）';
      case SharePlatform.alipan:
        return '请输入 refresh_token（从浏览器 Cookie 获取）';
      default:
        return '请输入 Cookie 字符串（从浏览器开发者工具复制）';
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 全屏沉浸式
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initWebView();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _tabController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(_desktopUA)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
            // 注入 JS 强制允许网页缩放（覆盖网页 viewport 限制）
            _controller.runJavaScript('''
              (function(){
                var m = document.querySelector('meta[name="viewport"]');
                if(m){ m.setAttribute('content','width=device-width,initial-scale=1.0,maximum-scale=10.0,user-scalable=yes'); }
                else {
                  var meta = document.createElement('meta');
                  meta.name='viewport';
                  meta.content='width=device-width,initial-scale=1.0,maximum-scale=10.0,user-scalable=yes';
                  document.head.appendChild(meta);
                }
                document.body.style.webkitUserSelect='text';
                document.body.style.userSelect='text';
              })();
            ''');
          },
        ),
      )
      ..loadRequest(Uri.parse(_loginUrl));

    final androidCtrl = _controller.platform as AndroidWebViewController;
    androidCtrl.setMediaPlaybackRequiresUserGesture(false);
    // 开启缩放（捏合缩放 + 双击缩放）
    androidCtrl.enableZoom(true);
    androidCtrl.setTextZoom(100);
  }

  Future<String> _extractCookies() async {
    // 通过 Android 原生 CookieManager 获取全部 Cookie（含 HttpOnly）
    final urls = <String>[];
    switch (widget.platform) {
      case SharePlatform.quark:
        urls.add('https://pan.quark.cn');
        break;
      case SharePlatform.uc:
        urls.add('https://drive.uc.cn');
        break;
      case SharePlatform.baidu:
        urls.add('https://pan.baidu.com');
        urls.add('https://www.baidu.com');
        break;
      case SharePlatform.c139:
        urls.add('https://yun.139.com');
        break;
      case SharePlatform.pan123:
        urls.add('https://www.123pan.com');
        break;
      case SharePlatform.xunlei:
        urls.add('https://pan.xunlei.com');
        break;
      case SharePlatform.tianyi:
        urls.add('https://cloud.189.cn');
        break;
      case SharePlatform.lanzou:
        urls.add('https://www.lanzou.com');
        break;
      case SharePlatform.alipan:
        urls.add('https://www.alipan.com');
        urls.add('https://www.aliyundrive.com');
        break;
    }

    String nativeCookies = '';
    try {
      nativeCookies = await _cookieChannel.invokeMethod(
        'getCookiesForUrls',
        {'urls': urls},
      ) as String? ?? '';
    } catch (_) {}

    // 兜底：再用 document.cookie 拿非 HttpOnly 的
    final cookies = <String, String>{};
    try {
      final result = await _controller.runJavaScriptReturningResult('document.cookie');
      final cookieStr = result.toString();
      for (final kv in cookieStr.split(';')) {
        final trimmed = kv.trim();
        final eq = trimmed.indexOf('=');
        if (eq > 0) {
          cookies[trimmed.substring(0, eq)] = trimmed.substring(eq + 1);
        }
      }
    } catch (_) {}

    // 合并：原生 Cookie 优先
    final all = <String, String>{};
    for (final kv in nativeCookies.split(';')) {
      final trimmed = kv.trim();
      final eq = trimmed.indexOf('=');
      if (eq > 0) {
        all[trimmed.substring(0, eq)] = trimmed.substring(eq + 1);
      }
    }
    cookies.forEach((k, v) {
      if (!all.containsKey(k)) all[k] = v;
    });

    return all.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  Future<String?> _extractPan123Token() async {
    try {
      final result = await _controller.runJavaScriptReturningResult(
        "localStorage.getItem('${Pan123Constants.localStorageTokenKey}')",
      );
      final str = result.toString().replaceAll('"', '');
      if (str.isNotEmpty && str != 'null') return str;
    } catch (_) {}
    return null;
  }

  Future<void> _saveCredential() async {
    setState(() => _saving = true);
    try {
      String? credential;

      if (_tabController.index == 1) {
        // 手动输入模式
        credential = _tokenController.text.trim();
      } else if (widget.platform == SharePlatform.pan123) {
        credential = await _extractPan123Token();
      } else {
        credential = await _extractCookies();
      }

      if (credential == null || credential.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('未检测到登录凭证，请先完成登录或粘贴 Token')),
          );
        }
        return;
      }

      // 校验凭证有效性（失败也保存，避免因 API 变更导致无法保存）
      final api = ref.read(apiServiceProvider);
      String? nickname;
      try {
        nickname = await api.fetchNickname(widget.platform, credential);
      } catch (_) {}

      final account = CloudAccount(
        platform: widget.platform,
        credential: credential,
        nickname: nickname ?? '${widget.platform.label}用户',
        loginTime: DateTime.now(),
      );
      await ref.read(accountsProvider.notifier).upsert(account);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nickname != null
                  ? '登录成功：$nickname'
                  : '凭证已保存（未能获取昵称，请到云库页确认）',
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('${widget.platform.label}登录'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.language), text: '网页登录'),
            Tab(icon: Icon(Icons.key), text: '手动输入'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _saveCredential,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存凭证'),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // 网页登录 - WebView 默认手势（可缩放、可输入）
          Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_loading)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
          // 手动输入 Token/Cookie - 可滚动，避免键盘遮挡
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Theme.of(context).colorScheme.onPrimaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '可直接粘贴 Cookie 或 Token，无需在网页中登录',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _tokenController,
                  maxLines: 10,
                  minLines: 6,
                  decoration: InputDecoration(
                    hintText: _credentialHint,
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () async {
                        final data = await Clipboard.getData('text/plain');
                        if (data?.text != null) {
                          _tokenController.text = data!.text!;
                        }
                      },
                      icon: const Icon(Icons.paste, size: 18),
                      label: const Text('粘贴'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () => _tokenController.clear(),
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('清空'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _saveCredential,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check, size: 20),
                    label: Text(_saving ? '保存中...' : '保存凭证'),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
