import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/share_platform.dart';
import '../models/download_task.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

class ShareDetailScreen extends ConsumerStatefulWidget {
  final SharePlatform platform;
  final String shareId;
  final String? pwd;
  final List<ShareFile> files;

  const ShareDetailScreen({
    super.key,
    required this.platform,
    required this.shareId,
    required this.pwd,
    required this.files,
  });

  @override
  ConsumerState<ShareDetailScreen> createState() => _ShareDetailScreenState();
}

class _ShareDetailScreenState extends ConsumerState<ShareDetailScreen> {
  bool _loading = false;

  Future<void> _downloadFile(ShareFile file) async {
    if (file.isDir) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂不支持文件夹下载')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final accounts = ref.read(accountsProvider);
      final account = accounts.firstWhere(
        (a) => a.platform == widget.platform,
      );
      final api = ref.read(apiServiceProvider);
      final link = await api.getDownloadLink(
        widget.platform,
        widget.shareId,
        file.fid,
        widget.pwd,
        account.credential,
      );
      if (link == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('获取下载链接失败')),
          );
        }
        return;
      }

      final task = DownloadTask(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        url: link.url,
        fileName: link.fileName,
        totalBytes: link.fileSize,
        downloadedBytes: 0,
        status: DownloadStatus.downloading,
        savePath: '',
        headers: link.headers,
        createTime: DateTime.now(),
        source: widget.platform.label,
      );

      final tasksNotifier = ref.read(tasksProvider.notifier);
      final tasks = ref.read(tasksProvider);
      tasks.insert(0, task);
      await tasksNotifier.save(tasks);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('开始下载：${link.fileName}')),
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
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.platform.label}分享'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_done_outlined),
            tooltip: '全部下载',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请逐个点击文件下载')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: widget.files.length,
            itemBuilder: (ctx, i) {
              final file = widget.files[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: file.isDir
                          ? color.primaryContainer
                          : color.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      file.isDir ? Icons.folder : Icons.insert_drive_file,
                      color: file.isDir
                          ? color.onPrimaryContainer
                          : color.onSecondaryContainer,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    file.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    file.isDir ? '文件夹' : formatBytes(file.size),
                    style: TextStyle(
                        color: color.onSurfaceVariant, fontSize: 12),
                  ),
                  trailing: FilledButton.tonalIcon(
                    onPressed: file.isDir ? null : () => _downloadFile(file),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('下载'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              );
            },
          ),
          if (_loading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
