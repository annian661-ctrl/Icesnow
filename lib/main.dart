import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/providers.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const IceSnowApp(),
    ),
  );
}

/// 请求运行时权限
Future<void> requestAllPermissions() async {
  // 通知权限（下载进度通知）
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }
  // 存储权限 - Android 12 及以下
  if (await Permission.storage.isDenied) {
    await Permission.storage.request();
  }
  // Android 13+ 媒体权限
  if (await Permission.photos.isDenied) {
    await Permission.photos.request();
  }
  if (await Permission.videos.isDenied) {
    await Permission.videos.request();
  }
  if (await Permission.audio.isDenied) {
    await Permission.audio.request();
  }
  // 所有文件访问权限（保存到公共 Downloads 需要）
  if (await Permission.manageExternalStorage.isDenied) {
    await Permission.manageExternalStorage.request();
  }
}

class IceSnowApp extends ConsumerWidget {
  const IceSnowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeModeStr = settings['themeMode'] ?? 'system';
    final seedName = settings['seedColor'] as String?;

    ThemeMode themeMode;
    switch (themeModeStr) {
      case 'dark':
        themeMode = ThemeMode.dark;
        break;
      case 'light':
        themeMode = ThemeMode.light;
        break;
      default:
        themeMode = ThemeMode.system;
    }

    return MaterialApp(
      title: '冰雪助手',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(seedName),
      darkTheme: AppTheme.dark(seedName),
      themeMode: themeMode,
      // 页面过渡动画
      onGenerateRoute: (settings) {
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(opacity: anim, child: child);
          },
        );
      },
      home: const HomeScreen(),
    );
  }
}
