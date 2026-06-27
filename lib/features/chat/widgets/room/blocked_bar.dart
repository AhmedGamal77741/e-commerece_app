import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BlockedBar extends ConsumerWidget {
  final bool blocked;
  final bool isBlocked;
  final String chatRoomId;
  final String currentUserId;
  final Future<void> Function(String) onUnblock;

  const BlockedBar({
    super.key,
    required this.blocked,
    required this.isBlocked,
    required this.chatRoomId,
    required this.currentUserId,
    required this.onUnblock,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.grey[200],
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            Text(
              blocked && isBlocked
                  ? '이 사용자를 차단했고 상대방도 나를 차단했습니다.'
                  : blocked
                  ? '이 사용자를 차단했습니다.'
                  : '상대방이 나를 차단했습니다.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
            if (blocked) ...[
              SizedBox(height: 10.h),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: () async {
                  final doc =
                      await FirebaseFirestore.instance
                          .collection('chatRooms')
                          .doc(chatRoomId)
                          .get();
                  final other = List<String>.from(
                    doc['participants'],
                  ).firstWhere((id) => id != currentUserId);
                  await onUnblock(other);
                },
                child: const Text('차단 해제'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
