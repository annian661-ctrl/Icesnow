import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/share_platform.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'cloud_file_browser_screen.dart';

class CloudScreen extends ConsumerWidget {
  const CloudScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('云库'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(accountsProvider.notifier).refresh(),
            tooltip: '刷新',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            '管理已接入的网盘账号',
            style: TextStyle(color: color.onSurfaceVariant, fontSize: 14),
          ),
          const SizedBox(height: 16),
          ...accounts.map((account) => _AccountCard(account: account)),
          ...SharePlatform.values
              .where((p) => !accounts.any((a) => a.platform == p))
              .map((p) => _AddAccountCard(platform: p)),
        ],
      ),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  final dynamic account;
  const _AccountCard({required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          // 进入网盘文件浏览
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CloudFileBrowserScreen(account: account),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 平台图标
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    account.platform.short,
                    style: TextStyle(
                      color: color.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // 名称 + 进度条
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          account.platform.label,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        if (account.totalSpace > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '会员',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      account.nickname,
                      style: TextStyle(
                          color: color.onSurfaceVariant, fontSize: 13),
                    ),
                    if (account.totalSpace > 0) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: account.usagePercent,
                          minHeight: 4,
                          backgroundColor: color.surfaceContainerHighest,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '剩余 ${formatBytes(account.totalSpace - account.usedSpace)} / 总 ${formatBytes(account.totalSpace)}',
                        style: TextStyle(
                            color: color.onSurfaceVariant, fontSize: 11),
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '点击刷新容量',
                          style: TextStyle(
                              color: color.onSurfaceVariant.withOpacity(0.6),
                              fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ),
              // 操作按钮
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    color: color.onSurfaceVariant, size: 22),
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'refresh', child: Text('刷新')),
                  const PopupMenuItem(value: 'logout', child: Text('退出登录')),
                ],
                onSelected: (v) async {
                  if (v == 'logout') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('退出登录'),
                        content:
                            Text('确定要退出${account.platform.label}吗？'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('取消')),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('退出'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref
                          .read(accountsProvider.notifier)
                          .remove(account.platform.name);
                    }
                  } else if (v == 'refresh') {
                    await ref.read(accountsProvider.notifier).refresh();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddAccountCard extends StatelessWidget {
  final SharePlatform platform;
  const _AddAccountCard({required this.platform});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LoginScreen(platform: platform)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    platform.short,
                    style: TextStyle(
                        color: color.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      platform.label,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '未登录',
                      style: TextStyle(
                          color: color.onSurfaceVariant, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
