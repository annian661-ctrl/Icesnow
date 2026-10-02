import 'share_platform.dart';

/// 网盘账号
class CloudAccount {
  final SharePlatform platform;
  final String credential; // Cookie 或 JWT
  final String nickname;
  final int totalSpace;
  final int usedSpace;
  final DateTime loginTime;

  const CloudAccount({
    required this.platform,
    required this.credential,
    required this.nickname,
    this.totalSpace = 0,
    this.usedSpace = 0,
    required this.loginTime,
  });

  Map<String, dynamic> toJson() => {
        'platform': platform.name,
        'credential': credential,
        'nickname': nickname,
        'totalSpace': totalSpace,
        'usedSpace': usedSpace,
        'loginTime': loginTime.toIso8601String(),
      };

  factory CloudAccount.fromJson(Map<String, dynamic> json) => CloudAccount(
        platform: SharePlatform.values.firstWhere(
          (e) => e.name == json['platform'],
          orElse: () => SharePlatform.quark,
        ),
        credential: json['credential']?.toString() ?? '',
        nickname: json['nickname']?.toString() ?? '',
        totalSpace: json['totalSpace'] is int
            ? json['totalSpace']
            : int.tryParse(json['totalSpace']?.toString() ?? '0') ?? 0,
        usedSpace: json['usedSpace'] is int
            ? json['usedSpace']
            : int.tryParse(json['usedSpace']?.toString() ?? '0') ?? 0,
        loginTime: DateTime.tryParse(json['loginTime']?.toString() ?? '') ??
            DateTime.now(),
      );

  CloudAccount copyWith({
    SharePlatform? platform,
    String? credential,
    String? nickname,
    int? totalSpace,
    int? usedSpace,
    DateTime? loginTime,
  }) =>
      CloudAccount(
        platform: platform ?? this.platform,
        credential: credential ?? this.credential,
        nickname: nickname ?? this.nickname,
        totalSpace: totalSpace ?? this.totalSpace,
        usedSpace: usedSpace ?? this.usedSpace,
        loginTime: loginTime ?? this.loginTime,
      );

  double get usagePercent =>
      totalSpace > 0 ? usedSpace / totalSpace : 0.0;
}
