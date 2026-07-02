import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';

class UserSearchTile extends StatelessWidget {
  final MyUser user;
  final bool isFollowing;
  final bool hasPendingRequest;
  final bool hideFollowButton;
  final VoidCallback onToggleFollow;
  final VoidCallback onToggleRequest;

  const UserSearchTile({
    super.key,
    required this.user,
    required this.isFollowing,
    required this.hasPendingRequest,
    this.hideFollowButton = false,
    required this.onToggleFollow,
    required this.onToggleRequest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget actionButton;
    if (isFollowing) {
      actionButton = ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          foregroundColor: theme.colorScheme.onSurface,
          minimumSize: Size(47.w, 33.h),
          textStyle: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: onToggleFollow,
        child: const Text('구독 취소'),
      );
    } else if (user.isPrivate) {
      actionButton = ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: hasPendingRequest 
              ? theme.colorScheme.surfaceContainerHighest 
              : theme.colorScheme.primary,
          foregroundColor: hasPendingRequest 
              ? theme.colorScheme.onSurface 
              : theme.colorScheme.onPrimary,
          minimumSize: Size(47.w, 33.h),
          textStyle: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: onToggleRequest,
        child: Text(hasPendingRequest ? '요청 취소' : '요청'),
      );
    } else {
      actionButton = ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          minimumSize: Size(47.w, 33.h),
          textStyle: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: onToggleFollow,
        child: const Text('구독'),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            radius: 25.sp,
            backgroundImage: NetworkImage(user.url),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
                if (user.bio != null && user.bio!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    user.bio.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          if (!hideFollowButton) actionButton,
        ],
      ),
    );
  }
}
