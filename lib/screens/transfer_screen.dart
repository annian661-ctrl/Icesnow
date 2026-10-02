import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/download_task.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  int _filterIndex = 0; // 0=全部, 1=下载中, 2=已完成, 3=失败
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _refreshTasks();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshTasks() async {
    final settings = ref.read(settingsProvider);
    if (settings['gopeedEnabled'] != true) return;
    final gopeed = ref.read(gopeedServiceProvider);
    gopeed.address = settings['gopeedAddress'] ?? 'http://127.0.0.1:48686';
    gopeed.token = settings['gopeedToken'] ?? '';
    final running = await gopeed.isRunning();
    if (!running) return;
    final tasks = await gopeed.getTasks();
    if (tasks.isNotEmpty) {
      await ref.read(tasksProvider.notifier).save(tasks);
    }
  }

  List<DownloadTask> _filtered(List<DownloadTask> tasks) {
    switch (_filterIndex) {
      case 1:
        return tasks.where((t) => t.status == DownloadStatus.downloading).toList();
      case 2:
        return tasks.where((t) => t.status == DownloadStatus.completed).toList();
      case 3:
        return tasks.where((t) => t.status == DownloadStatus.failed).toList();
      default:
        return tasks;
    }
  }

  String _statusText(DownloadStatus s) {
    switch (s) {
      case DownloadStatus.downloading:
        return '下载中';
      case DownloadStatus.completed:
        return '已完成';
      case DownloadStatus.paused:
        return '已暂停';
      case DownloadStatus.failed:
        return '失败';
      case DownloadStatus.pending:
        return '等待中';
    }
  }

  Color _statusColor(DownloadStatus s, ColorScheme color) {
    switch (s) {
      case DownloadStatus.downloading:
        return color.primary;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.paused:
        return Colors.orange;
      case DownloadStatus.failed:
        return Colors.red;
      case DownloadStatus.pending:
        return color.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final filtered = _filtered(tasks);
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('传输'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshTasks,
            tooltip: '刷新',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 分段筛选器（MD3 SegmentedButton）
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('全部')),
                ButtonSegment(value: 1, label: Text('下载中')),
                ButtonSegment(value: 2, label: Text('已完成')),
                ButtonSegment(value: 3, label: Text('失败')),
              ],
              selected: {_filterIndex},
              onSelectionChanged: (s) => setState(() => _filterIndex = s.first),
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.download_outlined,
                            size: 64, color: color.outline),
                        const SizedBox(height: 12),
                        Text('暂无下载任务',
                            style: TextStyle(color: color.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text(
                          '解析分享链接后可添加下载',
                          style: TextStyle(
                              color: color.onSurfaceVariant.withOpacity(0.6),
                              fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final task = filtered[i];
                      final statusColor = _statusColor(task.status, color);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 顶部：图标 + 文件名 + 状态
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: color.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.insert_drive_file,
                                      color: color.onPrimaryContainer,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.fileName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            // 来源标签
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: color
                                                    .surfaceContainerHighest,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                task.source,
                                                style: TextStyle(
                                                    color: color
                                                        .onSurfaceVariant,
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w500),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            // 状态标签
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: statusColor
                                                    .withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                _statusText(task.status),
                                                style: TextStyle(
                                                    color: statusColor,
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // 进度条
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: task.progress,
                                  minHeight: 4,
                                  backgroundColor:
                                      color.surfaceContainerHighest,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // 底部：大小 + 速度 + 按钮
                              Row(
                                children: [
                                  Icon(Icons.cloud_outlined,
                                      size: 14, color: color.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${formatBytes(task.downloadedBytes)} · ${(task.progress * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                        color: color.onSurfaceVariant,
                                        fontSize: 12),
                                  ),
                                  const SizedBox(width: 8),
                                  if (task.totalBytes > 0)
                                    Text(
                                      '/ ${formatBytes(task.totalBytes)}',
                                      style: TextStyle(
                                          color: color.onSurfaceVariant
                                              .withOpacity(0.6),
                                          fontSize: 12),
                                    ),
                                  const Spacer(),
                                  if (task.status == DownloadStatus.downloading)
                                    Text(
                                      formatSpeed(task.speed),
                                      style: TextStyle(
                                          color: color.primary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  const SizedBox(width: 16),
                                  // 打开按钮
                                  if (task.status == DownloadStatus.completed)
                                    OutlinedButton.icon(
                                      onPressed: () {},
                                      icon: const Icon(Icons.open_in_new,
                                          size: 16),
                                      label: const Text('打开',
                                          style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  // 删除按钮
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      await ref
                                          .read(tasksProvider.notifier)
                                          .save(ref
                                              .read(tasksProvider)
                                              .where((t) => t.id != task.id)
                                              .toList());
                                    },
                                    icon: const Icon(Icons.delete_outline,
                                        size: 16, color: Colors.red),
                                    label: const Text('删除',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.red)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      side: BorderSide(
                                          color: Colors.red.withOpacity(0.3)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
