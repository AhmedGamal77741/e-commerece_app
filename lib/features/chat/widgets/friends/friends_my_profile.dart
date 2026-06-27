import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'friends_modals.dart';

class FriendsMyProfile extends ConsumerWidget {
  final bool isLoadingUser;
  final MyUser? currentUser;
  final Map<String, String> aliases;
  final Function(MyUser) onUpdateUser;

  const FriendsMyProfile({
    super.key,
    required this.isLoadingUser,
    required this.currentUser,
    required this.aliases,
    required this.onUpdateUser,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isLoadingUser) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: const SizedBox.shrink(),
      );
    }
    if (currentUser == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /*         GestureDetector(
          onTap: () => showBioEditDialog(context, ref, currentUser, onUpdateUser),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28.r,
                  backgroundImage:
                      currentUser!.url.isNotEmpty
                          ? NetworkImage(currentUser!.url)
                          : null,
                  backgroundColor: Colors.grey[200],
                  child:
                      currentUser!.url.isEmpty
                          ? Icon(Icons.person, color: Colors.grey, size: 28.sp)
                          : null,
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser!.name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        (currentUser!.bio != null &&
                                currentUser!.bio!.isNotEmpty)
                            ? currentUser!.bio!
                            : '상태 메시지',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color:
                              (currentUser!.bio != null &&
                                      currentUser!.bio!.isNotEmpty)
                                  ? Colors.grey[600]
                                  : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ), */
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: '채팅방 만들기',
                onTap: () => showCreateGroupDialog(context: context, ref: ref, aliases: aliases),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildActionButton(
                icon: Icons.person_add_outlined,
                label: '친구 추가',
                onTap: () => showAddFriendDialog(context, ref),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        color: Colors.transparent,
        child: Row(
          children: [
            Icon(icon, size: 28.sp, color: Colors.black87),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
