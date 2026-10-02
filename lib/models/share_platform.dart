/// 网盘平台枚举
enum SharePlatform {
  quark('夸克网盘', '夸', 'quark'),
  uc('UC网盘', 'UC', 'uc'),
  xunlei('迅雷网盘', '迅', 'xunlei'),
  baidu('百度网盘', '度', 'baidu'),
  c139('139网盘', '139', 'c139'),
  pan123('123云盘', '123', 'pan123'),
  tianyi('天翼云盘', '翼', 'tianyi'),
  lanzou('蓝奏云', '蓝', 'lanzou'),
  alipan('阿里云盘', '阿', 'alipan');

  final String label;
  final String short;
  final String key;
  const SharePlatform(this.label, this.short, this.key);

  static SharePlatform? fromKey(String? key) {
    for (final p in values) {
      if (p.key == key) return p;
    }
    return null;
  }
}

/// 解析结果
class ParsedShare {
  final String shareId;
  final String? pwd;
  final SharePlatform platform;

  const ParsedShare({
    required this.shareId,
    required this.pwd,
    required this.platform,
  });
}

/// 分享文件
class ShareFile {
  final String fid;
  final String name;
  final int size;
  final bool isDir;
  final String? icon;
  final String? parentFid;

  const ShareFile({
    required this.fid,
    required this.name,
    required this.size,
    required this.isDir,
    this.icon,
    this.parentFid,
  });

  factory ShareFile.fromJson(Map<String, dynamic> json) => ShareFile(
        fid: json['fid']?.toString() ?? json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? json['file_name']?.toString() ?? '',
        size: (json['size'] is int)
            ? json['size']
            : int.tryParse(json['size']?.toString() ?? '0') ?? 0,
        isDir: json['is_dir'] == true || json['dir'] == true || json['type'] == 'folder',
        icon: json['icon']?.toString(),
        parentFid: json['pdir_fid']?.toString() ?? json['parent_id']?.toString(),
      );
}

/// 下载直链信息
class DownloadLink {
  final String url;
  final String fileName;
  final int fileSize;
  final Map<String, String> headers;

  const DownloadLink({
    required this.url,
    required this.fileName,
    required this.fileSize,
    this.headers = const {},
  });
}
