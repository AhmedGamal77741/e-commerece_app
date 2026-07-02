import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/chat/services/contacts_service.dart';
import 'package:ecommerece_app/features/home/data/follow_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final followServiceProvider = Provider<FollowService>((ref) {
  return FollowService();
});

final contactServiceProvider = Provider<ContactService>((ref) {
  return ContactService();
});

final contactNameMapProvider = FutureProvider<Map<String, String>>((ref) async {
  final contactService = ref.watch(contactServiceProvider);
  return await contactService.loadContactNameMap();
});

final contactNicknameProvider = Provider.family<String?, String>((ref, userId) {
  final contactService = ref.watch(contactServiceProvider);
  if (contactService.isNameMapLoaded()) {
    return contactService.getContactNicknameSync(userId);
  }
  final mapAsync = ref.watch(contactNameMapProvider);
  return mapAsync.maybeWhen(
    data: (map) => map[userId],
    orElse: () => null,
  );
});

final followControllerProvider = Provider<FollowController>((ref) {
  return FollowController(
    ref.read(followServiceProvider),
    ref.read(contactServiceProvider),
  );
});

class FollowController {
  final FollowService _followService;
  final ContactService _contactService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FollowController(this._followService, this._contactService);

  Future<bool> toggleFollow(String targetUserId) async {
    return await _followService.toggleFollow(targetUserId);
  }

  Future<void> sendFollowRequest(String targetUserId, String currentUserId) async {
    await _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followRequests')
        .doc(currentUserId)
        .set({'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> cancelFollowRequest(String targetUserId, String currentUserId) async {
    await _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followRequests')
        .doc(currentUserId)
        .delete();
  }

  Future<void> declineFollowRequest(String currentUserId, String requestingUserId) async {
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('followRequests')
        .doc(requestingUserId)
        .delete();
  }

  Future<void> acceptFollowRequest(String currentUserId, String requestingUserId) async {
    final batch = _firestore.batch();

    // Add to followers subcollection
    final followerRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('followers')
        .doc(requestingUserId);

    batch.set(followerRef, {
      'userId': requestingUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Add to requesting user's following subcollection
    final followingRef = _firestore
        .collection('users')
        .doc(requestingUserId)
        .collection('following')
        .doc(currentUserId);

    batch.set(followingRef, {
      'userId': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Delete the follow request
    final requestRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('followRequests')
        .doc(requestingUserId);

    batch.delete(requestRef);

    // Check for mutual follow
    final mutualFollowCheck = await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(requestingUserId)
        .get();

    if (mutualFollowCheck.exists) {
      // Create friendship
      batch.update(_firestore.collection('users').doc(currentUserId), {
        'friends': FieldValue.arrayUnion([requestingUserId]),
      });
      batch.update(_firestore.collection('users').doc(requestingUserId), {
        'friends': FieldValue.arrayUnion([currentUserId]),
      });

      // Restore chat room if it was previously soft-deleted
      final participants = [currentUserId, requestingUserId]..sort();
      final chatRoomId = participants.join('_');
      final chatRoomDoc = await _firestore.collection('chatRooms').doc(chatRoomId).get();
      if (chatRoomDoc.exists) {
        batch.update(chatRoomDoc.reference, {
          'deletedBy': FieldValue.arrayRemove([currentUserId, requestingUserId]),
        });
      }
    }

    await batch.commit();
  }

  Future<Map<String, Map<String, dynamic>>> getFriendRecommendations(
    String currentUserId,
    List<dynamic> followingIdsDynamic,
  ) async {
    List<String> followingIds = followingIdsDynamic.cast<String>();
    
    try {
      // Get friend recommendations first
      final recommendations = await _buildFriendRecommendations(currentUserId, followingIds);

      // Get contact matches
      final contactMatches = await _getContactMatches(currentUserId, followingIds);

      // Merge contacts with recommendations
      for (final entry in contactMatches.entries) {
        if (!recommendations.containsKey(entry.key)) {
          recommendations[entry.key] = entry.value;
        }
      }

      return recommendations;
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, Map<String, dynamic>>> _buildFriendRecommendations(
    String currentUserId,
    List<String> followingIds,
  ) async {
    final recommendations = <String, int>{};

    try {
      // Get current user's followers to exclude them
      final currentFollowersSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('followers')
          .get();
      final currentFollowers =
          currentFollowersSnapshot.docs.map((doc) => doc.id).toSet();

      // For each person the current user follows, get their following list
      for (final followingId in followingIds) {
        try {
          final theirFollowingSnapshot = await _firestore
              .collection('users')
              .doc(followingId)
              .collection('following')
              .get();

          for (final doc in theirFollowingSnapshot.docs) {
            final userId = doc.id;
            // Skip current user
            if (userId == currentUserId) continue;
            // Skip people already following or followers
            if (currentFollowers.contains(userId)) continue;
            // Skip people current user already follows
            if (followingIds.contains(userId)) continue;

            // Count occurrences
            recommendations[userId] = (recommendations[userId] ?? 0) + 1;
          }
        } catch (e) {
          continue;
        }
      }

      // Sort by count (highest first) and limit to top 20 recommendations
      final sortedRecs = recommendations.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final result = <String, Map<String, dynamic>>{};
      for (final entry in sortedRecs.take(20)) {
        try {
          final userDoc = await _firestore.collection('users').doc(entry.key).get();

          if (userDoc.exists) {
            final user = MyUser.fromDocument(userDoc.data() as Map<String, dynamic>);
            result[entry.key] = {'user': user, 'count': entry.value};
          }
        } catch (e) {
          continue;
        }
      }

      return result;
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, Map<String, dynamic>>> _getContactMatches(
    String currentUserId,
    List<String> followingIds,
  ) async {
    try {
      // Get phone contacts
      final contacts = await _contactService.getPhoneContacts();
      final phoneNumbers = _contactService.extractPhoneNumbers(contacts);

      // Find users matching phone numbers
      final matchingUsers = await _contactService.findUsersByPhoneNumbers(phoneNumbers);

      // Get current user's followers to exclude them
      final currentFollowersSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('followers')
          .get();
      final currentFollowers =
          currentFollowersSnapshot.docs.map((doc) => doc.id).toSet();

      // Filter and build result
      final result = <String, Map<String, dynamic>>{};
      for (final user in matchingUsers) {
        // Skip self
        if (user.userId == currentUserId) continue;
        // Skip if already following
        if (followingIds.contains(user.userId)) continue;
        // Skip if already a follower
        if (currentFollowers.contains(user.userId)) continue;

        result[user.userId] = {'user': user, 'count': 0, 'isContact': true};
      }

      return result;
    } catch (e) {
      return {};
    }
  }

  /// Consolidated follow action handler used by comment_item popup menu.
  /// Mirrors the exact logic that was previously inline in the UI.
  Future<void> handleFollowAction({
    required String targetUserId,
    required String currentUserId,
    required bool isPrivate,
    required bool isFollowing,
    required bool hasRequest,
  }) async {
    if (isFollowing) {
      await directUnfollow(targetUserId: targetUserId, currentUserId: currentUserId);
    } else if (isPrivate && !hasRequest) {
      await sendFollowRequest(targetUserId, currentUserId);
    } else if (isPrivate && hasRequest) {
      await cancelFollowRequest(targetUserId, currentUserId);
    } else {
      await directFollow(targetUserId: targetUserId, currentUserId: currentUserId);
    }
  }

  /// Directly follow a public user (batch write follower + following docs).
  Future<void> directFollow({
    required String targetUserId,
    required String currentUserId,
  }) async {
    final batch = _firestore.batch();

    final followerRef = _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId);

    final followingRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId);

    batch.set(followerRef, {
      'userId': currentUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.set(followingRef, {
      'userId': targetUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  /// Directly unfollow a user (batch delete follower + following docs).
  Future<void> directUnfollow({
    required String targetUserId,
    required String currentUserId,
  }) async {
    final batch = _firestore.batch();

    final followerRef = _firestore
        .collection('users')
        .doc(targetUserId)
        .collection('followers')
        .doc(currentUserId);

    final followingRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('following')
        .doc(targetUserId);

    batch.delete(followerRef);
    batch.delete(followingRef);

    await batch.commit();
  }
}
