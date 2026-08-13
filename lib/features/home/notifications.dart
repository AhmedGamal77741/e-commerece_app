import 'package:go_router/go_router.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/features/home/comments.dart';
import 'package:ecommerece_app/features/auth/domain/auth_controller.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Notifications extends ConsumerStatefulWidget {
  const Notifications({super.key});

  @override
  ConsumerState<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends ConsumerState<Notifications> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(feedControllerProvider.notifier).markAllNotificationsAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    return SafeArea(
      child: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('로그인이 필요합니다')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('로그인이 필요합니다'));
          }
          return StreamBuilder<QuerySnapshot>(
            stream: ref.watch(feedControllerProvider.notifier).getNotificationsStream(user.userId),
            builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox.shrink();
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('알림이 없습니다.'));
                  }
                  final notifications = snapshot.data!.docs;
                  return ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: 5.w,
                      vertical: 10.h,
                    ),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => Divider(),
                    itemBuilder: (context, index) {
                      final data =
                          notifications[index].data() as Map<String, dynamic>;
                      return ListTile(
                        onTap: () {
                          final chatRoomId = (data['chatRoomId']) as String?;
                          final postId = (data['postId']) as String?;
                          final commentId = (data['commentId']) as String?;

                          if (chatRoomId != null && chatRoomId.isNotEmpty) {
                            context.pushNamed(
                              Routes.chatScreen,
                              pathParameters: {'id': chatRoomId},
                            );
                          } else if (postId != null && postId.isNotEmpty) {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder:
                                  (context) => Container(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.95,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF2F2F2),
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                      child: Comments(
                                        postId: postId,
                                        commentId: commentId,
                                      ),
                                    ),
                                  ),
                            );
                          }
                        },
                        title: Text(
                          data['title'] ?? '',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18.sp,
                            fontFamily: 'NotoSans',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle:
                            data['body'] != null
                                ? Text(
                                  data['body'],
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 15.sp,
                                    fontFamily: 'NotoSans',
                                  ),
                                )
                                : null,
                        trailing:
                            data['isRead'] == false
                                ? Icon(
                                  Icons.circle,
                                  color: Colors.red,
                                  size: 12,
                                )
                                : null,
                        dense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 6.h,
                          horizontal: 8.w,
                        ),
                      );
                    },
                  );
                },
              );
        },
      ),
    );
  }
}
