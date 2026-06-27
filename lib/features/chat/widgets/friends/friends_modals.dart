import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecommerece_app/features/auth/domain/auth_controller.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/chat/domain/chat_controller.dart';
import 'package:ecommerece_app/features/chat/domain/friends_controller.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';

// ─── Multi-field user search ──────────────────────────────────────────────

Future<List<MyUser>> searchUsersByAny(String query) async {
  if (query.trim().isEmpty) return [];
  final q = query.trim();
  final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final fs = FirebaseFirestore.instance;
  final currentDoc = await fs.collection('users').doc(currentUid).get();
  final currentUser = MyUser.fromDocument(currentDoc.data()!);
  final friendIds = currentUser.friends;

  Future<List<MyUser>> runQuery(String field, String value) async {
    final snap = await fs
        .collection('users')
        .where(field, isGreaterThanOrEqualTo: value)
        .where(field, isLessThan: '${value}z')
        .limit(20)
        .get();
    return snap.docs
        .map((d) => MyUser.fromDocument(d.data()))
        .where((u) => u.userId != currentUid && !friendIds.contains(u.userId))
        .toList();
  }

  final results = await Future.wait([
    runQuery('name', q),
    runQuery('email', q.toLowerCase()),
    runQuery('phoneNumber', q),
  ]);

  final seen = <String>{};
  final merged = <MyUser>[];
  for (final list in results) {
    for (final user in list) {
      if (seen.add(user.userId)) merged.add(user);
    }
  }
  return merged;
}

// ─── Hide friend ──────────────────────────────────────────────────────────

Future<void> hideFriend(BuildContext context, MyUser friend) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;
  try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('hiddenFriends')
        .doc(friend.userId)
        .set({'hiddenAt': FieldValue.serverTimestamp()});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${friend.name}님을 숨겼습니다'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    }
  }
}

// ─── Delete friend ────────────────────────────────────────────────────────

Future<void> deleteFriend(BuildContext context, WidgetRef ref, MyUser friend) async {
  final displayName = (await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .collection('aliases')
              .doc(friend.userId)
              .get())
          .data()?['alias'] as String? ??
      friend.name;

  if (!context.mounted) return;
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '친구 삭제',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              '$displayName님을 친구 목록에서 삭제하시겠습니까?\n대화 내용도 함께 삭제됩니다.',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(
                      '취소',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(
                      '삭제',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  if (confirm != true) return;
  try {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    await ref.read(friendsControllerProvider.notifier).removeFriend(friend.userId);
    final chatRoomId = ([currentUid, friend.userId]..sort()).join('_');
    await ref.read(chatControllerProvider.notifier).softDeleteChatForCurrentUser(chatRoomId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$displayName님을 친구 목록에서 삭제했습니다'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
    }
  }
}

// ─── Block friend ─────────────────────────────────────────────────────────

Future<void> blockFriend(BuildContext context, WidgetRef ref, MyUser friend) async {
  final displayName = friend.name;
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '차단',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              '$displayName님을 차단하시겠습니까?\n차단하면 서로 메시지를 보낼 수 없습니다.',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(
                      '취소',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(
                      '차단',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  if (confirm != true) return;
  try {
    await ref.read(friendsControllerProvider.notifier).blockFriend(friend.name);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$displayName님을 차단했습니다'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('차단 실패: $e')));
    }
  }
}

// ─── Bio edit dialog ─────────────────────────────────────────────────────

void showBioEditDialog(BuildContext context, WidgetRef ref, MyUser? currentUser, Function(MyUser) onUpdate) {
  final bioController = TextEditingController(text: currentUser?.bio ?? '');
  showDialog(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 20.w,
        vertical: 80.h,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '상태 메시지',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20.h),
            TextField(
              controller: bioController,
              maxLength: 60,
              autofocus: true,
              style: TextStyle(fontSize: 14.sp, color: Colors.black),
              decoration: InputDecoration(
                hintText: '소개를 입력하세요',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14.sp,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black),
                ),
                counterStyle: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey,
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    '취소',
                    style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                  ),
                ),
                SizedBox(width: 8.w),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 8.h,
                    ),
                  ),
                  onPressed: () async {
                    final newBio = bioController.text.trim();
                    Navigator.pop(dialogContext);
                    if (currentUser == null) return;
                    final updatedUser = MyUser(
                      userId: currentUser.userId,
                      email: currentUser.email,
                      name: currentUser.name,
                      url: currentUser.url,
                      isSub: currentUser.isSub,
                      defaultAddressId: currentUser.defaultAddressId,
                      blocked: currentUser.blocked,
                      payerId: currentUser.payerId,
                      isOnline: currentUser.isOnline,
                      lastSeen: currentUser.lastSeen,
                      chatRooms: currentUser.chatRooms,
                      friends: currentUser.friends,
                      friendRequestsSent: currentUser.friendRequestsSent,
                      friendRequestsReceived: currentUser.friendRequestsReceived,
                      bio: newBio,
                      phoneNumber: currentUser.phoneNumber,
                    );
                    try {
                      await ref.read(authNotifierProvider.notifier).updateUser(updatedUser, '');
                      onUpdate(updatedUser);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('업데이트 실패: ${e.toString()}'),
                          ),
                        );
                      }
                    }
                  },
                  child: Text(
                    '변경',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── Change Name / Alias dialog ───────────────────────────────────────────

void showChangeNameDialog(BuildContext context, MyUser friend, String? currentAlias) {
  final aliasController = TextEditingController(text: currentAlias ?? '');
  final uid = FirebaseAuth.instance.currentUser?.uid;

  showDialog(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(
        horizontal: 24.w,
        vertical: 80.h,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(28.w, 32.h, 28.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                '이름 변경',
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: 6.h),
            Center(
              child: Text(
                '나에게만 보이는 별명을 설정합니다',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[400],
                ),
              ),
            ),
            SizedBox(height: 28.h),
            Text(
              '별명',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 6.h),
            TextField(
              controller: aliasController,
              maxLength: 30,
              autofocus: true,
              style: TextStyle(fontSize: 16.sp, color: Colors.black),
              decoration: InputDecoration(
                hintText: friend.name,
                hintStyle: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 16.sp,
                ),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1.2,
                  ),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black, width: 1.5),
                ),
                counterStyle: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey[400],
                ),
              ),
            ),
            if (currentAlias != null && currentAlias.isNotEmpty) ...[
              SizedBox(height: 14.h),
              GestureDetector(
                onTap: () async {
                  Navigator.pop(dialogContext);
                  if (uid == null) return;
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('aliases')
                        .doc(friend.userId)
                        .delete();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${friend.name}님의 이름을 원래대로 되돌렸습니다'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
                    }
                  }
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 13.sp,
                      color: Colors.grey[400],
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '원래 이름으로 되돌리기  (${friend.name})',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[400],
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.grey[300],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 28.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 13.h),
                    ),
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(
                      '취소',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 13.h),
                    ),
                    onPressed: () async {
                      final newAlias = aliasController.text.trim();
                      Navigator.pop(dialogContext);
                      if (uid == null) return;
                      try {
                        if (newAlias.isEmpty) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .collection('aliases')
                              .doc(friend.userId)
                              .delete();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${friend.name}님의 이름을 원래대로 되돌렸습니다'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } else {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(uid)
                              .collection('aliases')
                              .doc(friend.userId)
                              .set({'alias': newAlias});
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${friend.name}님의 이름을 "$newAlias"(으)로 변경했습니다'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('오류: $e')),
                          );
                        }
                      }
                    },
                    child: Text(
                      '변경',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// ─── Add friend dialog ────────────────────────────────────────────────────

void showAddFriendDialog(BuildContext context, WidgetRef ref) {
  final controller = TextEditingController();
  List<MyUser> results = [];
  bool isSearching = false;
  String? feedbackMessage;
  bool feedbackIsError = false;

  showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        Future<void> runSearch(String query) async {
          if (query.trim().isEmpty) {
            setDialogState(() {
              results = [];
              isSearching = false;
            });
            return;
          }
          setDialogState(() => isSearching = true);
          final found = await searchUsersByAny(query.trim());
          setDialogState(() {
            results = found;
            isSearching = false;
          });
        }

        Future<void> addFriend(MyUser user) async {
          setDialogState(() => feedbackMessage = null);
          final success = await ref.read(friendsControllerProvider.notifier).addFriend(user.name);
          setDialogState(() {
            if (success) {
              feedbackMessage = '${user.name}님과 친구가 되었습니다!';
              feedbackIsError = false;
              results.removeWhere((u) => u.userId == user.userId);
            } else {
              feedbackMessage = '친구 추가에 실패했습니다.';
              feedbackIsError = true;
            }
          });
        }

        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            top: 60.h,
            bottom: 20.h,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '친구 추가',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 14.h),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        color: Colors.grey[300],
                      ),
                      child: TextField(
                        controller: controller,
                        autofocus: true,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: '이름, 전화번호, 이메일',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14.sp,
                          ),
                          suffixIcon: isSearching
                              ? Padding(
                                  padding: EdgeInsets.all(12.r),
                                  child: SizedBox(
                                    width: 16.w,
                                    height: 16.w,
                                    child: const SizedBox.shrink(),
                                  ),
                                )
                              : Icon(
                                  Icons.search,
                                  size: 22.sp,
                                  color: Colors.black,
                                ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 12.h,
                          ),
                        ),
                        onChanged: runSearch,
                      ),
                    ),
                    if (feedbackMessage != null) ...[
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Icon(
                            feedbackIsError ? Icons.error_outline : Icons.check_circle_outline,
                            size: 14.sp,
                            color: feedbackIsError ? Colors.red : Colors.green[700],
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              feedbackMessage!,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: feedbackIsError ? Colors.red : Colors.green[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    SizedBox(height: 10.h),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: 260.h),
                    child: results.isNotEmpty
                        ? Column(
                            children: List.generate(results.length, (index) {
                              final user = results[index];
                              return Column(
                                children: [
                                  InkWell(
                                    borderRadius: BorderRadius.circular(8.r),
                                    onTap: () => addFriend(user),
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12.h,
                                        horizontal: 4.w,
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 22.r,
                                            backgroundImage: user.url.isNotEmpty ? NetworkImage(user.url) : null,
                                            backgroundColor: Colors.grey[200],
                                            child: user.url.isEmpty
                                                ? Icon(
                                                    Icons.person,
                                                    size: 22.sp,
                                                    color: Colors.grey,
                                                  )
                                                : null,
                                          ),
                                          SizedBox(width: 12.w),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  user.name,
                                                  style: TextStyle(
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                if (user.bio != null && user.bio!.isNotEmpty)
                                                  Text(
                                                    user.bio!,
                                                    style: TextStyle(
                                                      fontSize: 12.sp,
                                                      color: Colors.grey,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.person_add_outlined,
                                            size: 20.sp,
                                            color: Colors.grey[400],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (index < results.length - 1)
                                    Divider(
                                      height: 1,
                                      color: Colors.grey[100],
                                    ),
                                ],
                              );
                            }),
                          )
                        : SizedBox(
                            height: 260.h,
                            child: Center(
                              child: Text(
                                controller.text.isNotEmpty && !isSearching
                                    ? '검색 결과가 없습니다'
                                    : '이름, 전화번호 또는 이메일로\n친구를 검색해보세요',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 16.h),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(
                      '닫기',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

// ─── Create group dialog ──────────────────────────────────────────────────

Future<void> showCreateGroupDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Map<String, String> aliases,
}) async {
  final nameController = TextEditingController();
  final searchCtrl = TextEditingController();
  List<String> selectedUserIds = [];
  String? groupImagePath;
  String groupSearch = '';
  final friends = ref.read(friendsProvider).value ?? <MyUser>[];
  if (!context.mounted) return;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setDialogState) {
        final filteredFriends = groupSearch.isEmpty
            ? friends
            : friends.where((u) {
                final q = groupSearch.toLowerCase();
                final alias = aliases[u.userId]?.toLowerCase() ?? '';
                return u.name.toLowerCase().contains(q) || alias.contains(q);
              }).toList();

        final selectedFriends = friends.where((u) => selectedUserIds.contains(u.userId)).toList();

        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.only(
            left: 16.w,
            right: 16.w,
            top: 60.h,
            bottom: 20.h,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 24.h, bottom: 12.h),
                child: Text(
                  '채팅방 만들기',
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Group image picker ──
                      GestureDetector(
                        onTap: () async {
                          groupImagePath = await ref.read(feedControllerProvider.notifier).uploadImageToFirebaseStorageHome();
                          setDialogState(() {});
                        },
                        child: CircleAvatar(
                          radius: 40.r,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: groupImagePath != null ? NetworkImage(groupImagePath!) : null,
                          child: groupImagePath == null
                              ? Icon(
                                  Icons.image_outlined,
                                  size: 32.sp,
                                  color: Colors.grey[400],
                                )
                              : null,
                        ),
                      ),
                      SizedBox(height: 10.h),

                      // ── Group name field ──
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40.w),
                        child: TextField(
                          controller: nameController,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText: '채팅방 이름',
                            hintStyle: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14.sp,
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.grey[300]!,
                              ),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            isDense: true,
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // ── Selected friends horizontal chips ──
                      if (selectedFriends.isNotEmpty) ...[
                        SizedBox(
                          height: 90.h,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const ClampingScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                            ),
                            itemCount: selectedFriends.length,
                            itemBuilder: (context, idx) {
                              final user = selectedFriends[idx];
                              final displayName = aliases[user.userId] ?? user.name;
                              final hasAlias = aliases.containsKey(user.userId) && aliases[user.userId]!.isNotEmpty;

                              return Padding(
                                padding: EdgeInsets.only(right: 12.w),
                                child: SizedBox(
                                  width: 54.w,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          CircleAvatar(
                                            radius: 22.r,
                                            backgroundImage: user.url.isNotEmpty ? NetworkImage(user.url) : null,
                                            backgroundColor: Colors.grey[200],
                                            child: user.url.isEmpty
                                                ? Text(
                                                    user.name.isNotEmpty ? user.name[0] : '?',
                                                    style: TextStyle(
                                                      fontSize: 14.sp,
                                                      color: Colors.black,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          Positioned(
                                            top: -4,
                                            right: -4,
                                            child: GestureDetector(
                                              onTap: () => setDialogState(() => selectedUserIds.remove(user.userId)),
                                              child: Container(
                                                width: 16.w,
                                                height: 16.w,
                                                decoration: const BoxDecoration(
                                                  color: Colors.black,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.close,
                                                  size: 10.sp,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        displayName,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          color: Colors.black,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (hasAlias)
                                        Text(
                                          user.name,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 9.sp,
                                            color: Colors.grey[400],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(height: 8.h),
                      ],

                      // ── Search field ──
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Container(
                          height: 40.h,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: TextField(
                            controller: searchCtrl,
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Colors.black,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: '이름 또는 별명으로 검색',
                              hintStyle: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13.sp,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 10.h,
                              ),
                              suffixIcon: Icon(
                                Icons.search,
                                size: 20.sp,
                                color: Colors.black,
                              ),
                              isDense: true,
                            ),
                            onChanged: (val) => setDialogState(() => groupSearch = val),
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),

                      Padding(
                        padding: EdgeInsets.only(left: 16.w, bottom: 6.h),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '친구',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      // ── Friends list ──
                      if (filteredFriends.isEmpty)
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.h),
                          child: Center(
                            child: Text(
                              groupSearch.isNotEmpty ? '검색 결과가 없습니다' : '친구가 없습니다',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      else
                        Column(
                          children: filteredFriends.map((user) {
                            final isSelected = selectedUserIds.contains(user.userId);
                            final displayName = aliases[user.userId] ?? user.name;
                            final hasAlias = aliases.containsKey(user.userId) && aliases[user.userId]!.isNotEmpty;

                            return InkWell(
                              onTap: () => setDialogState(() {
                                if (isSelected) {
                                  selectedUserIds.remove(user.userId);
                                } else {
                                  selectedUserIds.add(user.userId);
                                }
                              }),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 8.h,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? Colors.black : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                      child: CircleAvatar(
                                        radius: 22.r,
                                        backgroundImage: user.url.isNotEmpty ? NetworkImage(user.url) : null,
                                        backgroundColor: Colors.grey[200],
                                        child: user.url.isEmpty
                                            ? Text(
                                                user.name.isNotEmpty ? user.name[0] : '?',
                                                style: TextStyle(
                                                  fontSize: 14.sp,
                                                  color: Colors.black,
                                                ),
                                              )
                                            : null,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          groupSearch.isNotEmpty
                                              ? _buildHighlightedNameGroup(displayName, groupSearch)
                                              : Text(
                                                  displayName,
                                                  style: TextStyle(
                                                    fontSize: 15.sp,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                          if (hasAlias)
                                            Text(
                                              user.name,
                                              style: TextStyle(
                                                fontSize: 11.sp,
                                                color: Colors.grey[400],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      width: 22.w,
                                      height: 22.w,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSelected ? Colors.black : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected ? Colors.black : Colors.grey[400]!,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: isSelected
                                          ? Icon(
                                              Icons.check,
                                              size: 13.sp,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      SizedBox(height: 8.h),
                    ],
                  ),
                ),
              ),

              // ── Bottom buttons ──
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.grey[100]!, width: 1),
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        '취소',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: selectedUserIds.isEmpty ? Colors.grey[300] : Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 10.h,
                        ),
                      ),
                      onPressed: selectedUserIds.isEmpty
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              await ref.read(chatControllerProvider.notifier).createGroupChatRoom(
                                    name: nameController.text,
                                    participantIds: selectedUserIds,
                                    groupImage: groupImagePath,
                                  );
                            },
                      child: Text(
                        '생성',
                        style: TextStyle(
                          color: selectedUserIds.isEmpty ? Colors.grey[500] : Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

Widget _buildHighlightedNameGroup(String name, String query) {
  final lowerName = name.toLowerCase();
  final lowerQuery = query.toLowerCase();
  final matchIndex = lowerName.indexOf(lowerQuery);

  if (matchIndex == -1) {
    return Text(
      name,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: Colors.black,
      ),
    );
  }

  return RichText(
    text: TextSpan(
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w400,
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
