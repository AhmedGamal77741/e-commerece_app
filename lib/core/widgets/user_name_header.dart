import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ecommerece_app/features/home/domain/follow_controller.dart';

final userAliasesStreamProvider = StreamProvider<Map<String, String>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value({});
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('aliases')
      .snapshots()
      .map((snap) {
        final map = <String, String>{};
        for (final doc in snap.docs) {
          final alias = doc.data()['alias'] as String?;
          if (alias != null && alias.isNotEmpty) {
            map[doc.id] = alias;
          }
        }
        return map;
      });
});

class UserNameHeader extends ConsumerWidget {
  final String userId;
  final String accountName;
  final Map<String, String>? aliases;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? textColor;
  final double? realNameFontSize;
  final Color? realNameColor;
  final double? contactFontSize;
  final Color? contactColor;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;

  const UserNameHeader({
    super.key,
    required this.userId,
    required this.accountName,
    this.aliases,
    this.fontSize,
    this.fontWeight,
    this.textColor,
    this.realNameFontSize,
    this.realNameColor,
    this.contactFontSize,
    this.contactColor,
    this.mainAxisSize = MainAxisSize.min,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String? alias;
    if (aliases != null) {
      alias = aliases![userId];
    } else if (userId.isNotEmpty) {
      final aliasesAsync = ref.watch(userAliasesStreamProvider);
      alias = aliasesAsync.maybeWhen(
        data: (map) => map[userId],
        orElse: () => null,
      );
    }

    final bool hasAlias = alias != null && alias.isNotEmpty && alias != accountName;
    final String displayName = (alias != null && alias.isNotEmpty) ? alias : accountName;
    final String? contactName = userId.isNotEmpty ? ref.watch(contactNicknameProvider(userId)) : null;

    final effectiveFontSize = fontSize ?? 16.sp;
    final effectiveFontWeight = fontWeight ?? FontWeight.w500;
    final effectiveTextColor = textColor ?? Colors.black;
    final effectiveRealNameFontSize = realNameFontSize ?? 11.sp;
    final effectiveRealNameColor = realNameColor ?? Colors.grey[400];
    final effectiveContactFontSize = contactFontSize ?? 12.sp;
    final effectiveContactColor = contactColor ?? Colors.grey[600];

    return Row(
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: Text(
            displayName,
            style: TextStyle(
              fontSize: effectiveFontSize,
              fontWeight: effectiveFontWeight,
              color: effectiveTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (hasAlias && accountName.isNotEmpty) ...[
          SizedBox(width: 4.w),
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              '($accountName)',
              style: TextStyle(
                fontSize: effectiveRealNameFontSize,
                color: effectiveRealNameColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        if (contactName != null && contactName.isNotEmpty) ...[
          SizedBox(width: 6.w),
          Flexible(
            fit: FlexFit.loose,
            child: Text(
              '@$contactName',
              style: TextStyle(
                fontSize: effectiveContactFontSize,
                color: effectiveContactColor,
                fontWeight: FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
