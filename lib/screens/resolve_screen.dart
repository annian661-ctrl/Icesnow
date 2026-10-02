import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/share_platform.dart';
import '../models/download_task.dart';
import '../services/share_link_parser.dart';
import '../providers/providers.dart';
import 'share_detail_screen.dart';
import 'login_screen.dart';

class ResolveScreen extends ConsumerStatefulWidget {
  const ResolveScreen({super.key});

  /// 待填充的分享文本（来自剪切板监听）
  static String? pendingText;

  @override
  ConsumerState<ResolveScreen> createState() => _ResolveScreenState();
}

class _ResolveScreenState extends ConsumerState<ResolveScreen> {
  final _linkController = TextEditingController();
  final _pwdController = TextEditingController();
  bool _parsing = false;

  @override
  void initState() {
    super.initState();
    _linkController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ResolveScreen.pendingText != null) {
        _linkController.text = ResolveScreen.pendingText!;
        _autoExtractPwd();
        ResolveScreen.pendingText = null;
      }
    });
  }

  @override
  void dispose() {
    _linkController.dispose();
    _pwdController.dispose();
    super.dispose();
  }

  void _autoExtractPwd() {
    final parsed = ShareLinkParser.parse(_linkController.text);
    if (parsed?.pwd != null && _pwdController.text.isEmpty) {
      _pwdController.text = parsed!.pwd!;
    }
  }

  Future<void> _pasteFromClipboard() async {
    final clipboard = ref.read(clipboardServiceProvider);
    final text = await clipboard.getClipboardText();
    if (text != null) {
      _linkController.text = text;
      _autoExtractPwd();
    }
  }

  Future<void> _parse() async {
    final text = _linkController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入分享链接')),
      );
      return;
    }

    // BT / 磁力 / ed2k / 迅雷 直链：直接创建下载任务
    if (ShareLinkParser.isDirectLink(text)) {
      final url = ShareLinkParser.extractDirectLink(text);
      if (url != null) {
        await _downloadDirectUrl(url);
        return;
      }
    }

    final parsed = ShareLinkParser.parse(text);
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法识别的分享链接')),
      );
      return;
    }

    final accounts = ref.read(accountsProvider);
    final hasAccount = accounts.any((a) => a.platform == parsed.platform);
    if (!hasAccount) {
      final goLogin = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('需要登录${parsed.platform.label}'),
          content: Text('解析${parsed.platform.label}分享链接前需要先登录账号'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('去登录'),
            ),
          ],
        ),
      );
      if (goLogin == true) {
        _openLogin(parsed.platform);
      }
      return;
    }

    setState(() => _parsing = true);
    final api = ref.read(apiServiceProvider);
    try {
      final files = await api.getShareFiles(
        parsed.platform,
        parsed.shareId,
        _pwdController.text.isEmpty ? parsed.pwd : _pwdController.text,
        accounts.firstWhere((a) => a.platform == parsed.platform).credential,
      );
      if (!mounted) return;
      if (files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('未获取到文件，请检查链接或提取码')),
        );
      } else {
        final storage = ref.read(storageServiceProvider);
        await storage.addHistory(text);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ShareDetailScreen(
              platform: parsed.platform,
              shareId: parsed.shareId,
              pwd: _pwdController.text.isEmpty ? parsed.pwd : _pwdController.text,
              files: files,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('解析失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _parsing = false);
    }
  }

  void _openLogin(SharePlatform platform) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen(platform: platform)),
    );
  }

  /// 直接下载磁力/ed2k/迅雷链接
  Future<void> _downloadDirectUrl(String url) async {
    setState(() => _parsing = true);
    try {
      String fileName;
      if (url.startsWith('magnet')) {
        fileName = '磁力链接_${DateTime.now().millisecondsSinceEpoch}';
      } else if (url.startsWith('ed2k')) {
        final parts = url.split('|');
        fileName = parts.length > 2 ? Uri.decodeComponent(parts[2]) : 'ED2K下载';
      } else {
        fileName = url.split('/').isNotEmpty
            ? Uri.decodeComponent(url.split('/').last)
            : '下载任务';
      }

      final source = url.startsWith('magnet')
          ? '磁力'
          : url.startsWith('ed2k')
              ? 'ED2K'
              : '迅雷';

      // 磁力/ed2k/迅雷 需要 gopeed 下载器
      if (url.startsWith('magnet') ||
          url.startsWith('ed2k') ||
          url.startsWith('thunder')) {
        final gopeed = ref.read(gopeedServiceProvider);
        final settings = ref.read(settingsProvider);
        gopeed.address = settings['gopeedAddress'] ?? 'http://127.0.0.1:48686';
        gopeed.token = settings['gopeedToken'] ?? '';

        final running = await gopeed.isRunning();
        if (!running) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('BT/磁力下载需要 gopeed 下载器，请在「设置-下载器」中启动并配置 gopeed'),
              ),
            );
          }
          return;
        }

        final gopeedId = await gopeed.createTask(url: url, name: fileName);
        if (gopeedId == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('gopeed 创建任务失败')),
            );
          }
          return;
        }

        // 添加到本地任务列表
        final task = DownloadTask(
          id: gopeedId,
          url: url,
          fileName: fileName,
          totalBytes: 0,
          downloadedBytes: 0,
          status: DownloadStatus.downloading,
          savePath: '',
          createTime: DateTime.now(),
          source: source,
        );
        final tasksNotifier = ref.read(tasksProvider.notifier);
        final tasks = ref.read(tasksProvider);
        tasks.insert(0, task);
        await tasksNotifier.save(tasks);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已添加到 gopeed 下载')),
          );
        }
        return;
      }

      // HTTP(S) 直链用内置下载器
      final task = DownloadTask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        url: url,
        fileName: fileName,
        totalBytes: 0,
        downloadedBytes: 0,
        status: DownloadStatus.downloading,
        savePath: '',
        createTime: DateTime.now(),
        source: source,
      );

      final tasksNotifier = ref.read(tasksProvider.notifier);
      final tasks = ref.read(tasksProvider);
      tasks.insert(0, task);
      await tasksNotifier.save(tasks);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已添加下载任务')),
        );
      }

      final downloadService = ref.read(downloadServiceProvider);
      await downloadService.download(
        task: task,
        onProgress: (downloaded, total, speed) {
          final updated = task.copyWith(
            downloadedBytes: downloaded,
            totalBytes: total > 0 ? total : task.totalBytes,
            speed: speed,
            status: DownloadStatus.downloading,
          );
          tasksNotifier.updateTask(updated);
        },
        onComplete: () async {
          final dir = await downloadService.getDownloadDir();
          final updated = task.copyWith(
            status: DownloadStatus.completed,
            downloadedBytes: task.totalBytes,
            speed: 0,
            savePath: '$dir/${task.fileName}',
          );
          await tasksNotifier.updateAndSave(updated);
        },
        onError: (error) async {
          final updated = task.copyWith(status: DownloadStatus.failed);
          await tasksNotifier.updateAndSave(updated);
        },
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('下载失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _parsing = false);
    }
  }

  /// 弹出添加 BT/磁力 链接对话框
  Future<void> _showBtDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加 BT / 磁力链接'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '粘贴 magnet:? / ed2k:// / thunder:// 链接',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('开始下载'),
          ),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      final url = ShareLinkParser.extractDirectLink(result);
      if (url != null) {
        await _downloadDirectUrl(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('无法识别的链接，请粘贴磁力/ED2K/迅雷链接')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final hasLink = _linkController.text.trim().isNotEmpty;
    final greeting = _getGreeting(now.hour);

    return Scaffold(
      appBar: AppBar(
        title: const Text('分享解析'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日期 + 问候 + 品牌
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text('${now.day}',
                              style: TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.w300,
                                color: color.onSurface,
                                height: 1,
                              )),
                          const SizedBox(width: 6),
                          Text('/ ${_getMonthName(now.month)}',
                              style: TextStyle(
                                fontSize: 16,
                                color: color.onSurfaceVariant,
                              )),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(greeting,
                          style: TextStyle(
                            fontSize: 14,
                            color: color.primary,
                            fontWeight: FontWeight.w500,
                          )),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('冰雪助手',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: color.primary,
                        )),
                    const SizedBox(height: 2),
                    Text('多云盘管理工具',
                        style: TextStyle(
                          fontSize: 12,
                          color: color.onSurfaceVariant,
                        )),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 主卡片：粘贴内容
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题行
                    Row(
                      children: [
                        Icon(Icons.description_outlined,
                            color: color.primary, size: 22),
                        const SizedBox(width: 10),
                        Text('粘贴内容',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            )),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: _showHistory,
                          icon: const Icon(Icons.history, size: 16),
                          label: const Text('历史'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                  color: color.outlineVariant.withOpacity(0.4)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasLink ? '已粘贴链接' : '等待粘贴链接',
                      style: TextStyle(
                        fontSize: 13,
                        color: color.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // 大文本输入框
                    TextField(
                      controller: _linkController,
                      maxLines: 4,
                      minLines: 3,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: '粘贴分享链接或包含链接的文本',
                        hintStyle: TextStyle(
                          color: color.onSurfaceVariant.withOpacity(0.5),
                          fontSize: 14,
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                      onChanged: (_) => _autoExtractPwd(),
                    ),
                    const SizedBox(height: 12),
                    // 提取码
                    TextField(
                      controller: _pwdController,
                      decoration: InputDecoration(
                        hintText: '提取码（自动识别，可手动修改）',
                        hintStyle: TextStyle(
                          color: color.onSurfaceVariant.withOpacity(0.5),
                          fontSize: 14,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 18),
                    // 双按钮
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _showBtDialog,
                            icon: Icon(Icons.add,
                                size: 18, color: color.primary),
                            label: Text('添加BT',
                                style: TextStyle(color: color.primary)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: hasLink && !_parsing ? _parse : null,
                            style: FilledButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _parsing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white),
                                  )
                                : const Text('开始解析',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 支持类型卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified_outlined,
                            color: color.primary, size: 22),
                        const SizedBox(width: 10),
                        Text('支持类型',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${SharePlatform.values.map((p) => p.label).join('、')}；'
                      '支持分享链接、带提取码文本、磁力链接、ED2K 和迅雷链接。',
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.7,
                        color: color.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 6) return '凌晨好';
    if (hour < 12) return '早上好';
    if (hour < 14) return '中午好';
    if (hour < 18) return '下午好';
    return '晚上好';
  }

  String _getMonthName(int month) {
    const names = [
      '一月', '二月', '三月', '四月', '五月', '六月',
      '七月', '八月', '九月', '十月', '十一月', '十二月'
    ];
    return names[month - 1];
  }

  void _showHistory() {
    final storage = ref.read(storageServiceProvider);
    final history = storage.getHistory();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: history.length,
        itemBuilder: (ctx, i) => ListTile(
          title: Text(history[i], maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () {
            Navigator.pop(ctx);
            _linkController.text = history[i];
            _autoExtractPwd();
          },
        ),
      ),
    );
  }
}
