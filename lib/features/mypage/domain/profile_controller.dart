import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:ecommerece_app/core/routing/app_router.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/features/auth/data/auth_repository.dart';
import 'package:ecommerece_app/features/auth/domain/auth_controller.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/chat/domain/chat_controller.dart';
import 'package:ecommerece_app/features/mypage/data/profile_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final subscriptionStreamProvider =
    StreamProvider.autoDispose<QuerySnapshot<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return const Stream.empty();
  }
  return FirebaseFirestore.instance
      .collection('subscriptions')
      .where('userId', isEqualTo: user.uid)
      .orderBy('nextBillingDate', descending: true)
      .limit(1)
      .snapshots();
});

final profileControllerProvider =
    AsyncNotifierProvider.autoDispose<ProfileController, void>(ProfileController.new);

class ProfileController extends AsyncNotifier<void> {
  final String supportUserId = 'JuxEfED9YSc2XyHRFgkPcNCFUSJ3';

  @override
  FutureOr<void> build() {}

  Future<void> deleteAccount({required String reason}) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) throw Exception("User not signed in");

    await ref.read(profileRepositoryProvider).softDeleteUser(user.uid, reason);
  }

  Future<void> signOut() async {
    await ref.read(profileRepositoryProvider).signOut();
  }

  Future<void> reauthenticateUser(String password) async {
    final user = ref.read(authStateProvider).value;
    if (user == null || user.email == null) {
      throw Exception("User not signed in or missing email");
    }

    await ref.read(profileRepositoryProvider).reauthenticateUser(user.email!, password);
  }

  Future<void> cancelSubscription(String reason) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) throw Exception("User not signed in");

    await ref.read(profileRepositoryProvider).cancelSubscription(user.uid, reason);
  }

  Future<void> performUpdate({
    required MyUser currentUser,
    String? newNickname,
    required String password,
    required String phone,
  }) async {
    final isUpdatingName =
        newNickname != null && newNickname.isNotEmpty && newNickname != currentUser.name;
    final isUpdatingPassword = password.isNotEmpty;
    final isUpdatingPhone = phone.isNotEmpty && phone != (currentUser.phoneNumber ?? '');

    if (!isUpdatingName && !isUpdatingPassword && !isUpdatingPhone) {
      throw Exception("변경된 내용이 없습니다");
    }

    if (isUpdatingName) {
      final name = newNickname.trim();
      final existing = await ref.read(authRepositoryProvider).isNicknameTaken(name);
      if (existing && name != currentUser.name) {
        throw Exception("이미 사용 중인 닉네임입니다");
      }
    }

    final updatedUser = MyUser(
      userId: currentUser.userId,
      email: currentUser.email,
      name: isUpdatingName ? newNickname.trim() : currentUser.name,
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
      phoneNumber: isUpdatingPhone ? phone : currentUser.phoneNumber,
    );

    if (isUpdatingPassword) {
      await reauthenticateUser(password);
    }

    await ref.read(authNotifierProvider.notifier).updateUser(
      updatedUser,
      isUpdatingPassword ? password : "",
    );
  }

  Future<void> updatePrivacy(bool isPrivate, String userId) async {
    if (!isPrivate) {
      await _acceptAllPendingRequests(userId);
    }
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'isPrivate': isPrivate});
  }

  Future<void> _acceptAllPendingRequests(String userId) async {
    final requestsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('followRequests')
        .get();

    if (requestsSnapshot.docs.isEmpty) {
      return;
    }

    final batch = FirebaseFirestore.instance.batch();

    for (var requestDoc in requestsSnapshot.docs) {
      final requestingUserId = requestDoc.id;

      batch.set(
        FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('followers')
            .doc(requestingUserId),
        {'userId': requestingUserId, 'createdAt': FieldValue.serverTimestamp()},
      );

      batch.set(
        FirebaseFirestore.instance
            .collection('users')
            .doc(requestingUserId)
            .collection('following')
            .doc(userId),
        {'userId': userId, 'createdAt': FieldValue.serverTimestamp()},
      );

      batch.delete(requestDoc.reference);

      final mutualFollowCheck = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('following')
          .doc(requestingUserId)
          .get();

      if (mutualFollowCheck.exists) {
        batch.update(
          FirebaseFirestore.instance.collection('users').doc(userId),
          {'friends': FieldValue.arrayUnion([requestingUserId])},
        );
        batch.update(
          FirebaseFirestore.instance.collection('users').doc(requestingUserId),
          {'friends': FieldValue.arrayUnion([userId])},
        );

        final participants = [userId, requestingUserId]..sort();
        final chatRoomId = participants.join('_');
        final chatRoomDoc = await FirebaseFirestore.instance
            .collection('chatRooms')
            .doc(chatRoomId)
            .get();
        if (chatRoomDoc.exists) {
          batch.update(chatRoomDoc.reference, {
            'deletedBy': FieldValue.arrayRemove([userId, requestingUserId]),
          });
        }
      }
    }

    await batch.commit();
  }

  Future<void> openSupportChat(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (user.uid == supportUserId) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('고객센터 계정에서는 고객센터 채팅을 이용할 수 없습니다.')),
        );
      }
      return;
    }
    String chatRoomId = '';
    try {
      chatRoomId = await ref.read(chatControllerProvider.notifier).createDirectChatRoom(
        supportUserId,
        true,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('고객센터 채팅방 생성에 실패했습니다.')),
        );
      }
      return;
    }

    if (chatRoomId.isEmpty) {
      return;
    }

    String supportName = '고객센터';
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(supportUserId)
          .get();
      final data = doc.data();
      if (doc.exists && data != null && (data['name'] as String?)?.isNotEmpty == true) {
        supportName = data['name'] as String;
      }
    } catch (_) {}

    if (context.mounted) {
      AppRouter.router.pushNamed(
        Routes.chatScreen,
        pathParameters: {'id': chatRoomId},
        extra: {'name': supportName},
      );
    }
  }

  Future<void> resubscribe() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final subSnap = await FirebaseFirestore.instance
        .collection('subscriptions')
        .where('userId', isEqualTo: user.uid)
        .orderBy('nextBillingDate', descending: true)
        .limit(1)
        .get();
    if (subSnap.docs.isNotEmpty) {
      await subSnap.docs.first.reference.update({'status': 'active'});
      final cancelsSnap = await FirebaseFirestore.instance
          .collection('cancels')
          .where('userId', isEqualTo: user.uid)
          .get();
      for (final doc in cancelsSnap.docs) {
        await doc.reference.delete();
      }
    }
  }
}
