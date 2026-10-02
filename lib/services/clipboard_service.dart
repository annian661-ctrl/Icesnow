import 'package:flutter/services.dart';
import 'share_link_parser.dart';

/// 剪切板监听服务
/// 监听剪切板内容，识别分享链接
class ClipboardService {
  String? _lastClipboard;

  /// 获取剪切板内容
  Future<String?> getClipboardText() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }

  /// 检查剪切板是否包含分享链接
  /// 返回解析结果，无则返回 null
  Future<String?> checkShareLink() async {
    final text = await getClipboardText();
    if (text == null || text.isEmpty) return null;
    // 跳过已处理过的内容
    if (text == _lastClipboard) return null;
    _lastClipboard = text;
    final parsed = ShareLinkParser.parse(text);
    if (parsed != null) {
      return text;
    }
    return null;
  }

  /// 复制文本到剪切板
  Future<void> copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// 重置（清空上次记录）
  void reset() {
    _lastClipboard = null;
  }
}
