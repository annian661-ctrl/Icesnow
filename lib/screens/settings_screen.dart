import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../models/cloud_account.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../main.dart';
import 'about_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() => _version = info.version);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text('下载策略、外观与账号',
                style: TextStyle(color: color.onSurfaceVariant, fontSize: 13)),
          ),

          // 外观
          _sectionTitle('外观'),
          _cardGroup([
            _listTile(
              icon: Icons.brightness_6_outlined,
              title: '主题模式',
              subtitle: _themeModeLabel(settings['themeMode']),
              onTap: () => _showThemeModePicker(),
            ),
            _listTile(
              icon: Icons.palette_outlined,
              title: '主题色',
              subtitle: settings['seedColor'] ?? '冰雪蓝',
              onTap: () => _showSeedColorPicker(),
            ),
          ]),

          // 帮助与反馈
          _sectionTitle('帮助与反馈'),
          _cardGroup([
            _listTile(
              icon: Icons.help_outline,
              title: '帮助与反馈',
              subtitle: '遇到问题或建议？在这里告诉我们',
              onTap: () => _showInfoSheet('帮助与反馈', '如有问题请反馈给开发者。'),
            ),
          ]),

          // 账号
          _sectionTitle('账号'),
          _cardGroup([
            _listTile(
              icon: Icons.person_outline,
              title: '用户中心',
              subtitle: '修改密码、账号迁移、注销账号',
              onTap: () => _showInfoSheet('用户中心', '本应用为纯本地工具，无需注册账号。网盘凭证保存在本机。'),
            ),
          ]),

          // 下载
          _sectionTitle('下载'),
          _cardGroup([
            _switchTile(
              icon: Icons.wifi,
              title: '仅在 Wi-Fi 下载',
              subtitle: settings['wifiOnly'] == true ? '已开启' : '已关闭',
              value: settings['wifiOnly'] == true,
              onChanged: (v) => ref.read(settingsProvider.notifier).set('wifiOnly', v),
            ),
            _listTile(
              icon: Icons.linear_scale,
              title: '下载线程数',
              subtitle: '${settings['threadCount'] ?? 64} 线程（gopeed，最高 512）',
              onTap: () => _showNumberPicker('下载线程数', 'threadCount', 1, 512),
            ),
            _listTile(
              icon: Icons.folder_outlined,
              title: '保存目录',
              subtitle: (settings['saveDirectory']?.toString().isNotEmpty == true)
                  ? settings['saveDirectory']
                  : '系统默认 Download',
              onTap: () => _showTextInput('保存目录', 'saveDirectory', hint: '/sdcard/Download'),
            ),
            _listTile(
              icon: Icons.dashboard,
              title: '同时下载任务数',
              subtitle: '${settings['concurrentTasks'] ?? 8} 个',
              onTap: () => _showNumberPicker('同时下载任务数', 'concurrentTasks', 1, 16),
            ),
            _listTile(
              icon: Icons.speed,
              title: '速度限制',
              subtitle: (settings['speedLimit'] == 0) ? '不限速' : '${settings['speedLimit']} KB/s',
              onTap: () => _showSpeedLimitPicker(),
            ),
            _listTile(
              icon: Icons.refresh,
              title: '失败自动重试',
              subtitle: '重试 ${settings['autoRetry'] ?? 3} 次',
              onTap: () => _showNumberPicker('失败自动重试', 'autoRetry', 0, 10),
            ),
            _switchTile(
              icon: Icons.check_circle_outline,
              title: '按大小校验完整性',
              subtitle: '下载完成后核对文件大小（推荐）',
              value: settings['verifyIntegrity'] != false,
              onChanged: (v) => ref.read(settingsProvider.notifier).set('verifyIntegrity', v),
            ),
            _switchTile(
              icon: Icons.lock_outline,
              title: '锁屏后保持下载',
              subtitle: '获取 WakeLock 维持网络连接',
              value: settings['keepScreenOn'] != false,
              onChanged: (v) => ref.read(settingsProvider.notifier).set('keepScreenOn', v),
            ),
            _switchTile(
              icon: Icons.notifications_none,
              title: '通知栏进度',
              subtitle: '显示进度条与速度',
              value: settings['showNotification'] != false,
              onChanged: (v) => ref.read(settingsProvider.notifier).set('showNotification', v),
            ),
          ]),

          // 解析设置
          _sectionTitle('解析设置'),
          _cardGroup([
            _switchTile(
              icon: Icons.cloud_outlined,
              title: '在线解析',
              subtitle: '凭证经加密传输',
              value: settings['onlineParse'] != false,
              onChanged: (v) => ref.read(settingsProvider.notifier).set('onlineParse', v),
            ),
          ]),

          // gopeed 下载器
          _sectionTitle('gopeed 下载器'),
          _cardGroup([
            _switchTile(
              icon: Icons.rocket_launch_outlined,
              title: '启用 gopeed',
              subtitle: '通过 HTTP API 连接 gopeed 下载器',
              value: settings['gopeedEnabled'] != false,
              onChanged: (v) => ref.read(settingsProvider.notifier).set('gopeedEnabled', v),
            ),
            _listTile(
              icon: Icons.link,
              title: 'gopeed 地址',
              subtitle: settings['gopeedAddress'] ?? 'http://127.0.0.1:48686',
              onTap: () => _showTextInput('gopeed 地址', 'gopeedAddress',
                  hint: 'http://127.0.0.1:48686'),
            ),
            _listTile(
              icon: Icons.key,
              title: 'API Token',
              subtitle: (settings['gopeedToken']?.toString().isNotEmpty == true)
                  ? '已配置'
                  : '未配置',
              onTap: () => _showTextInput('API Token', 'gopeedToken', hint: 'gopeed API Token'),
            ),
          ]),

          // 传输与转存
          _sectionTitle('传输与转存'),
          _cardGroup([
            _switchTile(
              icon: Icons.folder_copy_outlined,
              title: '文件夹批量操作',
              subtitle: settings['folderBatch'] == true
                  ? '已开启：递归处理子文件夹'
                  : '已关闭：只处理选中条目',
              value: settings['folderBatch'] == true,
              onChanged: (v) => ref.read(settingsProvider.notifier).set('folderBatch', v),
            ),
          ]),

          // 隐私安全
          _sectionTitle('隐私安全'),
          _cardGroup([
            _switchTile(
              icon: Icons.lock_outline,
              title: '应用启动锁',
              subtitle: settings['appLock'] == true ? '已开启' : '关闭',
              value: settings['appLock'] == true,
              onChanged: (v) => ref.read(settingsProvider.notifier).set('appLock', v),
            ),
            _listTile(
              icon: Icons.delete_sweep_outlined,
              title: '清空全部记录',
              subtitle: '删除解析历史与收藏',
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('清空记录'),
                    content: const Text('确定要清空全部解析历史吗？'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
                      FilledButton(
                          onPressed: () => Navigator.pop(ctx, true), child: const Text('清空')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(storageServiceProvider).clearHistory();
                  if (mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('已清空')));
                  }
                }
              },
            ),
          ]),

          // 网盘认证
          _sectionTitle('网盘认证'),
          _cardGroup([
            _listTile(
              icon: Icons.upload_file,
              title: '导出认证',
              subtitle: '加密保存所有网盘凭证到下载目录',
              onTap: () => _exportCredentials(),
            ),
            _listTile(
              icon: Icons.file_download,
              title: '导入认证',
              subtitle: '从文件选择凭证恢复登录',
              onTap: () => _importCredentials(),
            ),
          ]),

          // 通用
          _sectionTitle('通用'),
          _cardGroup([
            _switchTile(
              icon: Icons.content_paste,
              title: '剪切板监听',
              subtitle: '复制分享链接后回到应用提示解析',
              value: settings['clipboardListen'] != false,
              onChanged: (v) => ref.read(settingsProvider.notifier).set('clipboardListen', v),
            ),
            _listTile(
              icon: Icons.system_update,
              title: '检查更新',
              subtitle: '当前版本 v$_version',
              onTap: () => _checkUpdate(),
            ),
            _listTile(
              icon: Icons.security,
              title: '权限状态',
              subtitle: '点击查看详情',
              onTap: () => _showInfoSheet('权限状态',
                  '需要的权限：\n• 网络访问：用于解析与下载\n• 通知：显示下载进度\n• 前台服务：保持下载运行\n• 启动自启：开机后恢复下载\n• 存储读写：保存下载文件到公共目录'),
            ),
            _listTile(
              icon: Icons.folder_shared,
              title: '申请存储权限',
              subtitle: '下载文件需要存储权限',
              onTap: () async {
                await requestAllPermissions();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已申请权限，请在弹窗中允许')),
                  );
                }
              },
            ),
            _listTile(
              icon: Icons.info_outline,
              title: '关于',
              subtitle: '版本信息与免责声明',
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const AboutScreen())),
            ),
          ]),
          const SizedBox(height: 24),
          Center(
            child: Text('冰雪助手 v$_version',
                style: TextStyle(color: color.outline, fontSize: 12)),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _themeModeLabel(String? mode) {
    switch (mode) {
      case 'light':
        return '浅色';
      case 'dark':
        return '深色';
      default:
        return '跟随系统';
    }
  }

  // ---------- 主题选择 ----------

  void _showThemeModePicker() {
    final settings = ref.read(settingsProvider);
    final current = settings['themeMode'] ?? 'system';
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final options = [
          ('system', '跟随系统', Icons.brightness_auto_outlined),
          ('light', '浅色', Icons.light_mode_outlined),
          ('dark', '深色', Icons.dark_mode_outlined),
        ];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('主题模式',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              ...options.map((opt) {
                final selected = current == opt.$1;
                return ListTile(
                  leading: Icon(opt.$3),
                  title: Text(opt.$2),
                  trailing: selected
                      ? Icon(Icons.check_circle,
                          color: Theme.of(ctx).colorScheme.primary)
                      : null,
                  onTap: () {
                    ref.read(settingsProvider.notifier).set('themeMode', opt.$1);
                    Navigator.pop(ctx);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showSeedColorPicker() {
    final settings = ref.read(settingsProvider);
    final current = settings['seedColor'] ?? '冰雪蓝';
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('主题色',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: AppTheme.seedColors.entries.map((e) {
                    final selected = current == e.key;
                    return GestureDetector(
                      onTap: () {
                        ref
                            .read(settingsProvider.notifier)
                            .set('seedColor', e.key);
                        Navigator.pop(ctx);
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: e.value,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: selected
                                    ? Theme.of(ctx).colorScheme.primary
                                    : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: selected
                                  ? [
                                      BoxShadow(
                                        color: e.value.withOpacity(0.4),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: selected
                                ? const Icon(Icons.check,
                                    color: Colors.white, size: 28)
                                : null,
                          ),
                          const SizedBox(height: 4),
                          Text(e.key, style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ---------- 通用组件 ----------

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Text(title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          )),
    );
  }

  /// 将一组列表项包裹在白色卡片中
  Widget _cardGroup(List<Widget> children) {
    final color = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Card(
        child: Column(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              children[i],
              if (i < children.length - 1)
                Padding(
                  padding: const EdgeInsets.only(left: 56),
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: color.outlineVariant.withOpacity(0.3),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _listTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12.5, height: 1.3)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, size: 22),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12.5, height: 1.3)),
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  // ---------- 对话框 ----------

  void _showNumberPicker(String title, String key, int min, int max) {
    final settings = ref.read(settingsProvider);
    int current = (settings[key] is int) ? settings[key] : min;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: StatefulBuilder(
          builder: (ctx, setSt) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$current',
                  style: const TextStyle(
                      fontSize: 36, fontWeight: FontWeight.bold)),
              Slider(
                value: current.toDouble(),
                min: min.toDouble(),
                max: max.toDouble(),
                divisions: (max - min).clamp(1, 100),
                label: '$current',
                onChanged: (v) => setSt(() => current = v.toInt()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).set(key, current);
              Navigator.pop(ctx);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showSpeedLimitPicker() {
    final settings = ref.read(settingsProvider);
    int current = (settings['speedLimit'] is int) ? settings['speedLimit'] : 0;
    final speeds = [0, 128, 512, 1024, 2048, 5120, 10240];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text('速度限制',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...speeds.map((s) {
              final selected = current == s;
              return ListTile(
                title: Text(s == 0 ? '不限速' : '$s KB/s'),
                trailing: selected
                    ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                    : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).set('speedLimit', s);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showTextInput(String title, String key, {String? hint}) {
    final settings = ref.read(settingsProvider);
    final controller = TextEditingController(text: settings[key]?.toString() ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).set(key, controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showInfoSheet(String title, String content) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Text(content),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('知道了'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _checkUpdate() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('检查更新'),
        content: Text('当前已是最新版本 v$_version'),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('确定')),
        ],
      ),
    );
  }

  // ---------- 凭证导入导出（密码 AES 加密，参考 YunX） ----------

  enc.Encrypter _getEncrypter(String password) {
    // 用密码 SHA256 作为 AES-256 密钥
    final keyBytes = sha256.convert(utf8.encode(password)).bytes;
    final key = enc.Key(Uint8List.fromList(keyBytes));
    return enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
  }

  Future<String?> _askPassword({bool confirm = false}) async {
    final pwdCtrl = TextEditingController();
    final pwd2Ctrl = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(confirm ? '设置加密密码' : '输入解密密码'),
        content: StatefulBuilder(
          builder: (ctx, setSt) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pwdCtrl,
                obscureText: true,
                decoration: const InputDecoration(hintText: '请输入密码'),
              ),
              if (confirm) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: pwd2Ctrl,
                  obscureText: true,
                  decoration: const InputDecoration(hintText: '再次输入密码'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () {
              final p1 = pwdCtrl.text;
              if (p1.isEmpty) return;
              if (confirm && p1 != pwd2Ctrl.text) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('两次密码不一致')),
                );
                return;
              }
              Navigator.pop(ctx, p1);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCredentials() async {
    final accounts = ref.read(accountsProvider);
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('暂无可导出的凭证')));
      return;
    }
    final password = await _askPassword(confirm: true);
    if (password == null) return;

    try {
      final data = {
        'exportedAt': DateTime.now().toIso8601String(),
        'app': '冰雪助手',
        'accounts': accounts.map((a) => a.toJson()).toList(),
      };
      final plainJson = jsonEncode(data);
      final encrypter = _getEncrypter(password);
      final iv = enc.IV.fromSecureRandom(16);
      final encrypted = encrypter.encrypt(plainJson, iv: iv);
      // 格式：base64(iv):base64(cipher)
      final exportStr = '${iv.base64}:${encrypted.base64}';

      // 保存到下载目录
      final dir = await getExternalStorageDirectory();
      final downloadDir = Directory('${dir!.path}/Download');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      final fileName = '冰雪助手_凭证_${DateTime.now().millisecondsSinceEpoch}.icesnow';
      final file = File('${downloadDir.path}/$fileName');
      await file.writeAsString(exportStr);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已导出 ${accounts.length} 个账号凭证到：Download/$fileName')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('导出失败：$e')));
      }
    }
  }

  Future<void> _importCredentials() async {
    // 选择凭证文件
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['icesnow', 'json', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    String? text;
    if (file.bytes != null) {
      text = utf8.decode(file.bytes!);
    } else if (file.path != null) {
      text = await File(file.path!).readAsString();
    }
    if (text == null || text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('文件为空')));
      }
      return;
    }
    text = text.trim();

    // 尝试兼容旧版（明文 JSON）
    if (text.startsWith('{')) {
      try {
        final parsed = jsonDecode(text) as Map<String, dynamic>;
        final accounts = (parsed['accounts'] as List)
            .map((e) => CloudAccount.fromJson(e as Map<String, dynamic>))
            .toList();
        for (final a in accounts) {
          await ref.read(accountsProvider.notifier).upsert(a);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('成功导入 ${accounts.length} 个账号')),
          );
        }
        return;
      } catch (_) {
        // 不是明文 JSON，继续尝试解密
      }
    }

    // 加密格式：base64(iv):base64(cipher)
    if (!text.contains(':')) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('凭证格式不正确')));
      }
      return;
    }

    final password = await _askPassword();
    if (password == null) return;

    try {
      final parts = text.split(':');
      final iv = enc.IV.fromBase64(parts[0]);
      final encrypted = enc.Encrypted.fromBase64(parts[1]);
      final encrypter = _getEncrypter(password);
      final decrypted = encrypter.decrypt(encrypted, iv: iv);
      final parsed = jsonDecode(decrypted) as Map<String, dynamic>;
      final accounts = (parsed['accounts'] as List)
          .map((e) => CloudAccount.fromJson(e as Map<String, dynamic>))
          .toList();
      for (final a in accounts) {
        await ref.read(accountsProvider.notifier).upsert(a);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('成功导入 ${accounts.length} 个账号')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('解密失败，请检查密码是否正确')));
      }
    }
  }
}
