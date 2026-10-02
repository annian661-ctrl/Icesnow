/// 下载任务状态
enum DownloadStatus {
  pending,
  downloading,
  paused,
  completed,
  failed,
}

/// 下载任务
class DownloadTask {
  final String id;
  final String url;
  final String fileName;
  final int totalBytes;
  final int downloadedBytes;
  final DownloadStatus status;
  final double speed; // bytes/s
  final String savePath;
  final Map<String, String> headers;
  final DateTime createTime;
  final String source;

  const DownloadTask({
    required this.id,
    required this.url,
    required this.fileName,
    required this.totalBytes,
    required this.downloadedBytes,
    required this.status,
    this.speed = 0,
    required this.savePath,
    this.headers = const {},
    required this.createTime,
    this.source = '未知',
  });

  double get progress =>
      totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;

  DownloadTask copyWith({
    String? id,
    String? url,
    String? fileName,
    int? totalBytes,
    int? downloadedBytes,
    DownloadStatus? status,
    double? speed,
    String? savePath,
    Map<String, String>? headers,
    DateTime? createTime,
    String? source,
  }) =>
      DownloadTask(
        id: id ?? this.id,
        url: url ?? this.url,
        fileName: fileName ?? this.fileName,
        totalBytes: totalBytes ?? this.totalBytes,
        downloadedBytes: downloadedBytes ?? this.downloadedBytes,
        status: status ?? this.status,
        speed: speed ?? this.speed,
        savePath: savePath ?? this.savePath,
        headers: headers ?? this.headers,
        createTime: createTime ?? this.createTime,
        source: source ?? this.source,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'fileName': fileName,
        'totalBytes': totalBytes,
        'downloadedBytes': downloadedBytes,
        'status': status.name,
        'speed': speed,
        'savePath': savePath,
        'headers': headers,
        'createTime': createTime.toIso8601String(),
        'source': source,
      };

  factory DownloadTask.fromJson(Map<String, dynamic> json) => DownloadTask(
        id: json['id']?.toString() ?? '',
        url: json['url']?.toString() ?? '',
        fileName: json['fileName']?.toString() ?? '',
        totalBytes: json['totalBytes'] is int
            ? json['totalBytes']
            : int.tryParse(json['totalBytes']?.toString() ?? '0') ?? 0,
        downloadedBytes: json['downloadedBytes'] is int
            ? json['downloadedBytes']
            : int.tryParse(json['downloadedBytes']?.toString() ?? '0') ?? 0,
        status: DownloadStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => DownloadStatus.pending,
        ),
        speed: (json['speed'] is num) ? json['speed'].toDouble() : 0,
        savePath: json['savePath']?.toString() ?? '',
        headers: Map<String, String>.from(json['headers'] ?? {}),
        createTime: DateTime.tryParse(json['createTime']?.toString() ?? '') ??
            DateTime.now(),
        source: json['source']?.toString() ?? '未知',
      );
}
