import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsAndConditionsCheckbox extends StatelessWidget {
  final bool agreedToTerms;
  final bool agreedToPrivacy;
  final ValueChanged<bool> onChanged;

  const TermsAndConditionsCheckbox({
    super.key,
    required this.agreedToTerms,
    required this.agreedToPrivacy,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 20.w,
          height: 20.w,
          child: Checkbox(
            value: agreedToTerms && agreedToPrivacy,
            onChanged: (value) => onChanged(value ?? false),
            activeColor: theme.colorScheme.primary,
            checkColor: theme.colorScheme.onPrimary,
            side: BorderSide(
              color: theme.colorScheme.onSurface, 
              width: 1.5,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          '개인정보 수집 및 이용약관 동의 ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        GestureDetector(
          onTap: () async {
            final url = Uri.parse(
              'https://flowery-tub-f11.notion.site/1d938af9230b80fa9d64ce280f6eacbd',
            );
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            }
          },
          child: Text(
            '이용약관',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
