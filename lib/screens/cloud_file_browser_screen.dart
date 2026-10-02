import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/share_platform.dart';
import '../models/cloud_account.dart';
import '../services/api_service.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

/// 网盘文件浏览器
class CloudFileBrowserScreen extends ConsumerStatefulWidget {
  final CloudAccount account;
  const CloudFileBrowserScreen({super.key, required this.account});

  @override
  ConsumerState<CloudFileBrowserScreen> createState() =>
      _CloudFileBrowserScreenState();
}

class _CloudFileBrowserScreenState
    extends ConsumerState<CloudFileBrowserScreen> {
  List<ShareFile> _files = [];
  bool _loading = true;
  String _currentDir = '0';
  final List<String> _pathStack = [];
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadFiles('0');
  }

  Future<void> _loadFiles(String dirId) async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final api = ref.read(apiServiceProvider);
      final files = await api.getCloudFiles(
        widget.account.platform,
        widget.account.credential,
        parentId: dirId,
      );
      // 文件夹排在前面
      files.sort((a, b) {
        if (a.isDir != b.isDir) return a.isDir ? -1 : 1;
        return a.name.compareTo(b.name);
      });
      if (mounted) {
        setState(() {
          _files = files;
          _loading = false;
          _currentDir = dirId;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '加载失败：$e';
          _loading = false;
        });
      }
    }
  }

  void _openDir(ShareFile file) {
    _pathStack.add(_currentDir);
    _loadFiles(file.fid);
  }

  void _goBack() {
    if (_pathStack.isNotEmpty) {
      final parent = _pathStack.removeLast();
      _loadFiles(parent);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _goBack,
        ),
        title: Text(widget.account.platform.label),
      ),
      body: Column(
        children: [
          // 路径面包屑
          if (_pathStack.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              color: color.surfaceContainerHighest.withOpacity(0.4),
              child: Text(
                '... / 当前目录',
                style: TextStyle(color: color.onSurfaceVariant, fontSize: 12),
              ),
            ),
          Expanded(
            child: _buildBody(color),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme color) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: color.error),
              const SizedBox(height: 12),
              Text(_error, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => _loadFiles(_currentDir),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }
    if (_files.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open, size: 56, color: color.onSurfaceVariant.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text('文件夹为空', style: TextStyle(color: color.onSurfaceVariant)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _files.length,
      itemBuilder: (ctx, i) {
        final f = _files[i];
        return _FileTile(
          file: f,
          onTap: f.isDir ? () => _openDir(f) : null,
        );
      },
    );
  }
}

class _FileTile extends StatelessWidget {
  final ShareFile file;
  final VoidCallback? onTap;
  const _FileTile({required this.file, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final isDir = file.isDir;
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDir
              ? Colors.amber.withOpacity(0.12)
              : color.primaryContainer.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          isDir ? Icons.folder : Icons.insert_drive_file,
          color: isDir ? Colors.amber : color.primary,
          size: 22,
        ),
      ),
      title: Text(
        file.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: isDir
          ? null
          : Text(
              formatBytes(file.size),
              style: TextStyle(color: color.onSurfaceVariant, fontSize: 12),
            ),
      trailing: isDir
          ? Icon(Icons.chevron_right, color: color.onSurfaceVariant)
          : const SizedBox(),
      onTap: onTap,
    );
  }
}
