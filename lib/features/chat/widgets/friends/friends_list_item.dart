import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:go_router/go_router.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/features/chat/domain/chat_controller.dart';
import 'friends_modals.dart';

class FriendsListItem extends ConsumerWidget {
  final MyUser friend;
  final Map<String, String> aliases;
  final bool showCheckbox;
  final bool isBrand;
  final String effectiveQuery;
  final String? contactName;
  final bool isSearchActive;
  final Set<String> selectedChatIds;
  final Function(String, bool) onCheckboxChanged;

  const FriendsListItem({
    super.key,
    required this.friend,
    required this.aliases,
    this.showCheckbox = false,
    this.isBrand = false,
    this.effectiveQuery = '',
    this.contactName,
    this.isSearchActive = false,
    required this.selectedChatIds,
    required this.onCheckboxChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GlobalKey itemKey = GlobalKey();
    final String displayName = aliases[friend.userId] ?? friend.name;
    final bool hasAlias =
        aliases.containsKey(friend.userId) &&
        aliases[friend.userId]!.isNotEmpty;

    void showFriendMenu() {
      if (isBrand) return;
      final RenderBox box =
          itemKey.currentContext!.findRenderObject() as RenderBox;
      final Offset offset = box.localToGlobal(Offset.zero);
      final screenWidth = MediaQuery.of(context).size.width;
      const double popupWidth = 220;
      const double popupHeight = 380;

      double left = offset.dx + 55;
      double top = offset.dy - 60;
      final screenHeight = MediaQuery.of(context).size.height;

      if (left + popupWidth > screenWidth - 12) {
        left = screenWidth - popupWidth - 12;
      }
      if (top + popupHeight > screenHeight - 20) {
        top = offset.dy - popupHeight + 20;
      }
      if (top < 8) top = 8;

      showDialog(
        context: context,
        barrierColor: Colors.transparent,
        barrierDismissible: false,
        builder:
            (_) => Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                Positioned(
                  left: left,
                  top: top,
                  width: popupWidth,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 20.h),
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          if (hasAlias) ...[
                            SizedBox(height: 2.h),
                            Text(
                              friend.name,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                          SizedBox(height: 4.h),
                          Divider(
                            color: Colors.grey[200],
                            thickness: 1,
                            height: 1,
                          ),

                          _buildMenuOption(
                            label: '이름 변경',
                            onTap: () {
                              Navigator.pop(context);
                              showChangeNameDialog(
                                context,
                                ref,
                                friend,
                                aliases[friend.userId],
                              );
                            },
                          ),
                          _buildMenuOption(
                            label: '거리두기',
                            onTap: () {
                              Navigator.pop(context);
                              hideFriend(context, ref, friend);
                            },
                          ),
                          _buildMenuOption(
                            label: '삭제',
                            labelColor: Colors.red[600],
                            onTap: () {
                              Navigator.pop(context);
                              deleteFriend(context, ref, friend);
                            },
                          ),
                          _buildMenuOption(
                            label: '차단',
                            labelColor: Colors.red[800],
                            onTap: () {
                              Navigator.pop(context);
                              blockFriend(context, ref, friend);
                            },
                            isLast: true,
                          ),
                          SizedBox(height: 12.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      );
    }

    return Container(
      key: itemKey,
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              InkWell(
                onTap: () {
                  context.pushNamed(
                    Routes.profileTabScreen,
                    extra: {'userId': friend.userId},
                  );
                },
                onLongPress: showFriendMenu,
                child: CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  radius: 25.r,
                  backgroundImage: NetworkImage(friend.url),
                ),
              ),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isSearchActive
                    ? InkWell(
                      onTap: () async {
                        try {
                          final chatRoomId = await ref
                              .read(chatControllerProvider.notifier)
                              .createDirectChatRoom(friend.userId, isBrand);
                          if (context.mounted) {
                            context.pushNamed(
                              Routes.chatScreen,
                              pathParameters: {'id': chatRoomId},
                              extra: {'name': displayName},
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      onLongPress: showFriendMenu,
                      child: Row(
                        children: [
                          _buildHighlightedName(displayName, effectiveQuery),
                          if (contactName != null &&
                              contactName!.isNotEmpty) ...[
                            SizedBox(width: 6.w),
                            Text(
                              '@$contactName',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                    : InkWell(
                      onTap: () async {
                        try {
                          final chatRoomId = await ref
                              .read(chatControllerProvider.notifier)
                              .createDirectChatRoom(friend.userId, isBrand);
                          if (context.mounted) {
                            context.pushNamed(
                              Routes.chatScreen,
                              pathParameters: {'id': chatRoomId},
                              extra: {'name': displayName},
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                      onLongPress: showFriendMenu,
                      child: Row(
                        children: [
                          Text(
                            displayName,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          if (hasAlias) ...[
                            SizedBox(width: 4.w),
                            Text(
                              '(${friend.name})',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                          if (contactName != null &&
                              contactName!.isNotEmpty) ...[
                            SizedBox(width: 6.w),
                            Text(
                              '@$contactName',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
              ],
            ),
          ),
          if (showCheckbox)
            Checkbox(
              value: selectedChatIds.contains(friend.userId),
              onChanged:
                  (checked) =>
                      onCheckboxChanged(friend.userId, checked ?? false),
            ),
        ],
      ),
    );
  }

  Widget _buildHighlightedName(String name, String query) {
    final lowerName = name.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matchIndex = lowerName.indexOf(lowerQuery);

    if (matchIndex == -1) {
      return Text(
        name,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
        children: [
          if (matchIndex > 0) TextSpan(text: name.substring(0, matchIndex)),
          TextSpan(
            text: name.substring(matchIndex, matchIndex + query.length),
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (matchIndex + query.length < name.length)
            TextSpan(text: name.substring(matchIndex + query.length)),
        ],
      ),
    );
  }

  Widget _buildMenuOption({
    required String label,
    required VoidCallback onTap,
    Color? labelColor,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w400,
                  color: labelColor ?? Colors.black,
                ),
              ),
            ),
          ),
          if (!isLast)
            Divider(color: Colors.grey[200], thickness: 1, height: 1),
        ],
      ),
    );
  }
}
