import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ShareService {
  static const String _appDomain = 'https://www.pang2chocolate.com';

  static Future<void> copyProductLink(BuildContext context, String productId) async {
    final link = '$_appDomain/product/$productId';
    await Clipboard.setData(ClipboardData(text: link));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('링크가 클립보드에 복사되었습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  static Future<void> copyPostLink(BuildContext context, String postId) async {
    final link = '$_appDomain/comment?postId=$postId';
    await Clipboard.setData(ClipboardData(text: link));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('링크가 클립보드에 복사되었습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  static Future<void> shareProduct(
    String productId,
    String productName, {
    String? imageUrl,
    String? description,
    BuildContext? context,
  }) async {
    final link = '$_appDomain/product/$productId';
    await Clipboard.setData(ClipboardData(text: link));
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('링크가 클립보드에 복사되었습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  static Future<void> sharePost(String postId, {BuildContext? context}) async {
    final link = '$_appDomain/comment?postId=$postId';
    await Clipboard.setData(ClipboardData(text: link));
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('링크가 클립보드에 복사되었습니다.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
