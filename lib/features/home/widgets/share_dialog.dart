import 'package:ecommerece_app/core/models/product_model.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/services/share_service.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/chat/services/chat_service.dart';
import 'package:ecommerece_app/features/chat/services/friends_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';


Widget _buildSquareAction({
  required IconData icon,
  String? asset,
  required String label,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 110.w,
      height: 160.h,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SizedBox(height: 8.h),
          if (asset != null)
            Opacity(
              opacity: 0.2,
              child: Image.asset(asset, width: 80.w, height: 80.h),
            )
          else
            Icon(icon, size: 80.sp, color: Colors.grey[600]),
          SizedBox(height: 8.h),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18.sp, color: Colors.black54),
          ),
        ],
      ),
    ),
  );
}

Widget _buildFriendItem({
  required MyUser friend,
  required BuildContext context,
  required Map<String, dynamic> postData,
  required String type,
  required String url,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16),
    child: InkWell(
      onTap: () async {
        try {
          final chatRoomId = await ChatService().createDirectChatRoom(
            friend.userId,
            friend.type != 'user',
          );
          if (type == 'post') {
            final contentText = postData['text'] ?? '';
            ChatService().sendMessage(
              chatRoomId: chatRoomId,
              content: contentText.isEmpty ? url : '$url\n$contentText',
              postData: postData,
            );
          } else if (type == 'product') {
            ChatService().sendMessage(
              chatRoomId: chatRoomId,
              content: url,
              productData: Product.fromMap(postData),
            );
          }

          if (!context.mounted) return;
          context.pushNamed(
            Routes.chatScreen,
            pathParameters: {'id': chatRoomId},
            extra: {'name': friend.name},
          );
                } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey[300],
            backgroundImage: NetworkImage(friend.url),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                if (friend.bio != null && friend.bio!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    friend.bio ?? '',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
/* Widget buildFriendItem() {
  return ListTile(
    leading: const CircleAvatar(
      radius: 24,
      /*       backgroundImage: NetworkImage('https://via.placeholder.com/150'),
 */
    ),
    title: const Text('노찌', style: TextStyle(fontWeight: FontWeight.bold)),
    subtitle: const Text('상태 메시지', style: TextStyle(fontSize: 12)),
    onTap: () {},
  );
} */

void showShareDialog(
  BuildContext context,
  String type,
  String url,
  String id,
  String name,
  String imgUrl,
  Map<String, dynamic> mapData, {
  bool isLoggedIn = false,
}) {
  showDialog(
    context: context,
    builder: (context) {
      if (type == 'post') {
        mapData.addEntries({'authorName': name}.entries);
      }
      String searchQuery = '';
      final TextEditingController searchController = TextEditingController();
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 40,
            ),
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      '공유',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // 1. Horizontal Actions (Add to Story, Copy Link)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildSquareAction(
                          icon: Icons.link,
                          label: '링크 복사',
                          onTap: () {
                            if (type == 'post') {
                              ShareService.sharePost(id);
                            } else if (type == 'product') {
                              ShareService.shareProduct(id, name);
                            }
                          } /* _copyToClipboard(postUrl) */,
                        ),
                      ],
                    ),
                  ),
                  if (isLoggedIn) ...[
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: '친구 검색',
                          filled: true,
                          fillColor: Colors.grey[200],
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          searchQuery = value.trim().toLowerCase();
                          setState(() {});
                        },
                      ),
                    ),

                    // 3. Scrollable Friends List
                    Expanded(
                      child: FutureBuilder(
                        future: FriendsService().getFriendsList(
                          includeHidden: false,
                        ),
                        builder: (context, asyncSnapshot) {
                          if (asyncSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox.shrink();
                          }
                          if (asyncSnapshot.hasError) {
                            return Center(child: Text('친구 목록을 불러오는 데 실패했습니다.'));
                          }
                          final friends = asyncSnapshot.data ?? [];

                          return ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            itemCount: friends.length,
                            itemBuilder: (context, index) {
                              if (searchQuery.isNotEmpty &&
                                  !friends[index].name.toLowerCase().contains(
                                    searchQuery,
                                  )) {
                                return const SizedBox.shrink();
                              }
                              return _buildFriendItem(
                                friend: friends[index],
                                context: context,
                                postData: mapData,
                                type: type,
                                url: url,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          '로그인하시면 친구들에게 직접 공유할 수 있습니다!',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontFamily: 'NotoSans',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
