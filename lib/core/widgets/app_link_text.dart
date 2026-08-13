import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class AppLinkText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final int? maxLines;
  final TextOverflow? overflow;

  const AppLinkText({
    super.key,
    required this.text,
    this.style,
    this.linkStyle,
    this.maxLines,
    this.overflow,
  });

  static final RegExp _urlRegex = RegExp(
    r'(https?://[^\s]+|/(?:product|comment)/[^\s]+)',
    caseSensitive: false,
  );

  @override
  Widget build(BuildContext context) {
    final defaultStyle = style ?? DefaultTextStyle.of(context).style;
    final defaultLinkStyle = linkStyle ??
        defaultStyle.copyWith(
          color: const Color(0xFF1E88E5),
          decoration: TextDecoration.underline,
        );

    final List<InlineSpan> spans = [];
    final matches = _urlRegex.allMatches(text);

    int lastIndex = 0;
    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }

      final urlString = match.group(0)!;
      final recognizer = TapGestureRecognizer()
        ..onTap = () async {
          final uri = Uri.tryParse(urlString);
          if (uri != null) {
            // Check if product link
            final productMatch = RegExp(r'(?:/product/|productId=)([a-zA-Z0-9_-]+)').firstMatch(urlString);
            if (productMatch != null) {
              final productId = productMatch.group(1);
              if (productId != null && productId.isNotEmpty) {
                if (context.mounted) {
                  context.pushNamed(
                    'productDetails',
                    pathParameters: {'productId': productId},
                  );
                }
                return;
              }
            }

            // Check if comment link
            final commentMatch = RegExp(r'(?:/comment|/guest_comment)\?postId=([a-zA-Z0-9_-]+)').firstMatch(urlString);
            if (commentMatch != null) {
              final postId = commentMatch.group(1);
              if (postId != null && postId.isNotEmpty && context.mounted) {
                context.pushNamed(
                  'guestCommentsScreen',
                  queryParameters: {'postId': postId},
                );
                return;
              }
            }

            // Fallback: external launcher
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          }
        };

      spans.add(
        TextSpan(
          text: urlString,
          style: defaultLinkStyle,
          recognizer: recognizer,
        ),
      );

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return RichText(
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      text: TextSpan(
        style: defaultStyle,
        children: spans,
      ),
    );
  }
}
