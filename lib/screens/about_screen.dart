import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('关于')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: color.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.ac_unit, size: 40, color: color.primary),
                ),
                const SizedBox(height: 12),
                const Text('冰雪助手', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('v1.1.7', style: TextStyle(color: color.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('简介', style: TextStyle(fontWeight: FontWeight.w600, color: color.primary)),
                  const SizedBox(height: 8),
                  const Text(
                    '冰雪助手是一款开源的网盘分享链接解析下载工具，支持夸克、UC、迅雷、百度、139、123 等主流网盘。\n\n'
                    '本项目基于 YunX（云析）开源项目进行 Flutter 重构，核心解析逻辑移植自原项目，UI 遵循 Material Design 3 规范。',
                    style: TextStyle(height: 1.6, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('开源协议', style: TextStyle(fontWeight: FontWeight.w600, color: color.primary)),
                  const SizedBox(height: 8),
                  const Text(
                    '本项目基于 GNU AGPL-3.0 协议开源。\n\n'
                    '本项目仅供个人学习与技术交流，请勿用于商业用途。下载内容版权归原作者所有，请在下载后 24 小时内删除。'
                    '使用本项目产生的任何后果由使用者自行承担。',
                    style: TextStyle(height: 1.6, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(Icons.link, color: color.primary),
              title: const Text('YunX 原项目'),
              subtitle: const Text('github.com/CYQawa/YunX'),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite, size: 14, color: Colors.red[400]),
                const SizedBox(width: 4),
                Text(
                  'made with love and GPT',
                  style: TextStyle(
                    color: color.onSurfaceVariant,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
