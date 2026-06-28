import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/chat/services/contacts_service.dart';
import 'package:ecommerece_app/features/home/domain/follow_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Requests extends ConsumerStatefulWidget {
  const Requests({super.key});

  @override
  ConsumerState<Requests> createState() => _RequestsState();
}

class _RequestsState extends ConsumerState<Requests> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  late Future<Map<String, Map<String, dynamic>>> _recommendationsFuture;
  bool _recommendationsInitialized = false;
  final ContactService _contactService = ContactService();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    // Initialize recommendations future once on load
    _initializeRecommendations();
  }

  Future<void> _initializeRecommendations() async {
    try {
      final currentUserId = ref.read(currentUserIdProvider);
      if (currentUserId.isEmpty) return;

      final followingIds = await ref.read(feedControllerProvider.notifier).getFollowingIds(currentUserId);

      // Compute recommendations ONCE and cache the Future (includes both recommendations and contacts)
      _recommendationsFuture = _buildFriendRecommendationsWithContacts(
        currentUserId,
        followingIds,
      );
      _recommendationsInitialized = true;

      // Trigger rebuild
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error initializing recommendations: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = ref.watch(currentUserIdProvider);

    if (currentUserId.isEmpty) {
      return const Center(child: Text('Please sign in'));
    }

    return Column(
      children: [
        // Search field - sticky at the top
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '검색',
              prefixIcon: const Icon(Icons.search),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 10.h,
              ),
              border: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.r),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.black),
                borderRadius: BorderRadius.circular(8.r),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Colors.grey),
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
          ),
        ),
        // Scrollable content
        Expanded(
          child: SingleChildScrollView(
            child: StreamBuilder<DocumentSnapshot?>(
              stream: ref.watch(userProfileDocProvider(currentUserId).future).asStream(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final currentUserData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                final isCurrentUserPrivate =
                    currentUserData['isPrivate'] ?? false;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===================== Section 1: 친구요청 (Only if PRIVATE) =====================
                    if (isCurrentUserPrivate)
                      Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
                        child: Text(
                          '친구요청',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    // Requests list - adapts to content, max 5 items with internal scroll
                    if (isCurrentUserPrivate)
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: 220.h),
                        child: StreamBuilder<QuerySnapshot>(
                          stream: ref.watch(feedControllerProvider.notifier).getFollowRequestsStream(currentUserId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                !snapshot.hasData) {
                              return const SizedBox.shrink();
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            }

                            final requests = snapshot.data?.docs ?? [];

                            if (requests.isEmpty) {
                              return Center(
                                child: Text(
                                  searchQuery.isNotEmpty
                                      ? '일치하는 요청이 없습니다'
                                      : '받은 요청이 없습니다',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            }

                            // Build map of requesting user IDs
                            final requestingUserIds =
                                requests.map((doc) => doc.id).toList();

                            // Stream all requesting users at once
                            return StreamBuilder<QuerySnapshot>(
                              stream: ref.read(feedControllerProvider.notifier).getUsersByIdsStream(requestingUserIds),
                              builder: (context, usersSnapshot) {
                                if (!usersSnapshot.hasData) {
                                  return const SizedBox.shrink();
                                }

                                // Build user map for quick lookup
                                final usersMap = <String, MyUser>{};
                                for (var doc in usersSnapshot.data!.docs) {
                                  final user = MyUser.fromDocument(
                                    doc.data() as Map<String, dynamic>,
                                  );
                                  usersMap[doc.id] = user;
                                }

                                // Filter by search query
                                final filteredRequests =
                                    requests.where((requestDoc) {
                                      final user = usersMap[requestDoc.id];
                                      if (user == null) return false;
                                      if (searchQuery.isEmpty) return true;
                                      return user.name.toLowerCase().contains(
                                        searchQuery,
                                      );
                                    }).toList();

                                return filteredRequests.isEmpty
                                    ? Center(
                                      child: Text(
                                        searchQuery.isNotEmpty
                                            ? '일치하는 요청이 없습니다'
                                            : '받은 요청이 없습니다',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                    : ListView.builder(
                                      itemCount: filteredRequests.length,
                                      itemBuilder: (context, index) {
                                        final requestDoc =
                                            filteredRequests[index];
                                        final requestingUserId = requestDoc.id;
                                        final requestingUser =
                                            usersMap[requestingUserId];

                                        if (requestingUser == null) {
                                          return const SizedBox.shrink();
                                        }

                                        return Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16.w,
                                            vertical: 8.h,
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.all(12.w),
                                            child: Row(
                                              children: [
                                                // User avatar
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        24.r,
                                                      ),
                                                  child: Image.network(
                                                    requestingUser.url,
                                                    width: 48.w,
                                                    height: 48.w,
                                                  ),
                                                ),
                                                SizedBox(width: 12.w),
                                                // User info
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        requestingUser.name,
                                                        style: TextStyle(
                                                          fontSize: 14.sp,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                      if (requestingUser.bio !=
                                                              null &&
                                                          requestingUser
                                                              .bio!
                                                              .isNotEmpty)
                                                        Text(
                                                          requestingUser.bio!,
                                                          style: TextStyle(
                                                            fontSize: 12.sp,
                                                            color:
                                                                Colors
                                                                    .grey[600],
                                                          ),
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(width: 8.w),
                                                // Accept button
                                                GestureDetector(
                                                  onTap: () async {
                                                    await ref.read(followControllerProvider).acceptFollowRequest(
                                                      currentUserId,
                                                      requestingUserId,
                                                    );
                                                  },
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 12.w,
                                                          vertical: 6.h,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          ColorsManager
                                                              .primaryblack,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8.r,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '수락',
                                                      style: TextStyle(
                                                        fontSize: 12.sp,
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 8.w),
                                                // Decline button
                                                GestureDetector(
                                                  onTap: () async {
                                                    await ref.read(followControllerProvider).declineFollowRequest(
                                                      currentUserId,
                                                      requestingUserId,
                                                    );
                                                  },
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 12.w,
                                                          vertical: 6.h,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                        color:
                                                            Colors.grey[300]!,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8.r,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '거절',
                                                      style: TextStyle(
                                                        fontSize: 12.sp,
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    );
                              },
                            );
                          },
                        ),
                      ),

                    // ===================== Section 2: 친구추천 (Always shown) =====================
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
                      child: Text(
                        '친구추천(친구의 친구)',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    // Friend recommendations - adapts to content, max 5 items with internal scroll
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 220.h),
                      child:
                          _recommendationsInitialized
                              ? FutureBuilder<
                                Map<String, Map<String, dynamic>>
                              >(
                                future: _recommendationsFuture,
                                builder: (context, recommendationsSnapshot) {
                                  if (recommendationsSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const SizedBox.shrink();
                                  }

                                  if (recommendationsSnapshot.hasError) {
                                    return Center(
                                      child: Text(
                                        'Error: ${recommendationsSnapshot.error}',
                                      ),
                                    );
                                  }

                                  final recommendations =
                                      recommendationsSnapshot.data ?? {};

                                  // Filter by search query
                                  final filteredRecommendations =
                                      <String, Map<String, dynamic>>{};
                                  for (final entry in recommendations.entries) {
                                    final user = entry.value['user'] as MyUser;
                                    if (searchQuery.isEmpty) {
                                      filteredRecommendations[entry.key] =
                                          entry.value;
                                    } else if (user.name.toLowerCase().contains(
                                      searchQuery,
                                    )) {
                                      filteredRecommendations[entry.key] =
                                          entry.value;
                                    }
                                  }

                                  if (filteredRecommendations.isEmpty) {
                                    return Center(
                                      child: Text(
                                        searchQuery.isNotEmpty
                                            ? '일치하는 추천이 없습니다'
                                            : '추천할 친구가 없습니다',
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    itemCount: filteredRecommendations.length,
                                    itemBuilder: (context, index) {
                                      final userId =
                                          filteredRecommendations.keys
                                              .toList()[index];
                                      final data =
                                          filteredRecommendations[userId]!;
                                      final user = data['user'] as MyUser;
                                      final mutualCount = data['count'] as int;
                                      final isContact =
                                          data['isContact'] as bool? ?? false;

                                      return Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 16.w,
                                          vertical: 8.h,
                                        ),
                                        child: Container(
                                          padding: EdgeInsets.all(12.w),
                                          child: Row(
                                            children: [
                                              // User avatar
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(24.r),
                                                child: Image.network(
                                                  user.url,
                                                  width: 48.w,
                                                  height: 48.w,
                                                ),
                                              ),
                                              SizedBox(width: 12.w),
                                              // User info
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      user.name,
                                                      style: TextStyle(
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    Text(
                                                      isContact
                                                          ? '연락처에서'
                                                          : '$mutualCount명의 친구를 팔로우 중',
                                                      style: TextStyle(
                                                        fontSize: 12.sp,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(width: 8.w),
                                              // Follow button
                                              StreamBuilder<bool>(
                                                stream: ref.watch(isFollowingProvider(userId).future).asStream(),
                                                builder: (context, snapshot) {
                                                  final isFollowing = snapshot.data ?? false;

                                                  if (isFollowing) {
                                                    return ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            Colors.grey[300],
                                                        foregroundColor:
                                                            Colors.black,
                                                        minimumSize: Size(
                                                          70.w,
                                                          32.h,
                                                        ),
                                                        textStyle: TextStyle(
                                                          fontSize: 12.sp,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8.r,
                                                              ),
                                                        ),
                                                      ),
                                                      onPressed: () async {
                                                          ref.read(followControllerProvider).handleFollowAction(
                                                              targetUserId: user.userId,
                                                              currentUserId: currentUserId,
                                                              isPrivate: user.isPrivate,
                                                              isFollowing: isFollowing,
                                                              hasRequest: false,
                                                            );
                                                      },
                                                      child: Text('구독 취소'),
                                                    );
                                                  }

                                                  final isPrivate =
                                                      user.isPrivate;

                                                  if (isPrivate) {
                                                    return StreamBuilder<bool>(
                                                      stream: ref.watch(hasFollowRequestProvider(userId).future).asStream(),
                                                      builder: (
                                                        context,
                                                        snapshot,
                                                      ) {
                                                        final hasRequest = snapshot.data ?? false;

                                                        return ElevatedButton(
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                                hasRequest
                                                                    ? Colors
                                                                        .grey[300]
                                                                    : ColorsManager
                                                                        .primaryblack,
                                                            foregroundColor:
                                                                hasRequest
                                                                    ? Colors
                                                                        .black
                                                                    : Colors
                                                                        .white,
                                                            minimumSize: Size(
                                                              70.w,
                                                              32.h,
                                                            ),
                                                            textStyle:
                                                                TextStyle(
                                                                  fontSize:
                                                                      12.sp,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8.r,
                                                                  ),
                                                            ),
                                                          ),
                                                          onPressed: () async {
                                                            ref.read(followControllerProvider).handleFollowAction(
                                                              targetUserId: userId,
                                                              currentUserId: currentUserId,
                                                              isPrivate: user.isPrivate,
                                                              isFollowing: isFollowing,
                                                              hasRequest: hasRequest,
                                                            );
                                                          },
                                                          child: Text(
                                                            hasRequest
                                                                ? '요청 중'
                                                                : '요청',
                                                          ),
                                                        );
                                                      },
                                                    );
                                                  }

                                                  return ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          ColorsManager
                                                              .primaryblack,
                                                      foregroundColor:
                                                          Colors.white,
                                                      minimumSize: Size(
                                                        70.w,
                                                        32.h,
                                                      ),
                                                      textStyle: TextStyle(
                                                        fontSize: 12.sp,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8.r,
                                                            ),
                                                      ),
                                                    ),
                                                    onPressed: () async {
                                                      ref.read(followControllerProvider)
                                                          .toggleFollow(userId);
                                                    },
                                                    child: Text('구독'),
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              )
                              : const SizedBox.shrink(),
                    ),

                    // ===================== Section 3: 차단친구 보기 (Always shown) =====================
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
                      child: Text(
                        '차단친구 보기',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    // Blocked friends list
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 220.h),
                      child: StreamBuilder<DocumentSnapshot?>(
                        stream: ref.watch(userProfileDocProvider(currentUserId).future).asStream(),
                        builder: (context, userSnapshot) {
                          if (!userSnapshot.hasData) {
                            return const SizedBox.shrink();
                          }

                          final blockedList = List<String>.from(
                            userSnapshot.data!.get('blocked') ?? [],
                          );

                          if (blockedList.isEmpty) {
                            return Center(
                              child: Text(
                                '차단된 친구가 없습니다',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          }

                          return StreamBuilder<QuerySnapshot>(
                            stream: ref.read(feedControllerProvider.notifier).getUsersByIdsStream(blockedList),
                            builder: (context, blockedSnapshot) {
                              if (!blockedSnapshot.hasData) {
                                return const SizedBox.shrink();
                              }

                              final blockedUsers = blockedSnapshot.data!.docs;

                              // Filter by search query
                              final filteredBlockedUsers =
                                  blockedUsers.where((doc) {
                                    final blockedUser = MyUser.fromDocument(
                                      doc.data() as Map<String, dynamic>,
                                    );
                                    if (searchQuery.isEmpty) return true;
                                    return blockedUser.name
                                        .toLowerCase()
                                        .contains(searchQuery);
                                  }).toList();

                              if (filteredBlockedUsers.isEmpty) {
                                return Center(
                                  child: Text(
                                    searchQuery.isNotEmpty
                                        ? '일치하는 차단된 친구가 없습니다'
                                        : '차단된 친구가 없습니다',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.grey,
                                    ),
                                  ),
                                );
                              }

                              return ListView.builder(
                                itemCount: filteredBlockedUsers.length,
                                itemBuilder: (context, index) {
                                  final blockedUser = MyUser.fromDocument(
                                    filteredBlockedUsers[index].data()
                                        as Map<String, dynamic>,
                                  );

                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 8.h,
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.all(12.w),
                                      child: Row(
                                        children: [
                                          // User avatar
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              24.r,
                                            ),
                                            child: Image.network(
                                              blockedUser.url,
                                              width: 48.w,
                                              height: 48.w,
                                            ),
                                          ),
                                          SizedBox(width: 12.w),
                                          // User info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  blockedUser.name,
                                                  style: TextStyle(
                                                    fontSize: 14.sp,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                if (blockedUser.bio != null &&
                                                    blockedUser.bio!.isNotEmpty)
                                                  Text(
                                                    blockedUser.bio!,
                                                    style: TextStyle(
                                                      fontSize: 12.sp,
                                                      color: Colors.grey[600],
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 8.w),
                                          // Unblock button
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  ColorsManager.primaryblack,
                                              foregroundColor: Colors.white,
                                              minimumSize: Size(70.w, 32.h),
                                              textStyle: TextStyle(
                                                fontSize: 12.sp,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.r),
                                              ),
                                            ),
                                            onPressed: () async {
                                              await _unblockUser(
                                                blockedUser.userId,
                                                currentUserId,
                                              );
                                            },
                                            child: Text('차단해제'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 12.h),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }


  Future<Map<String, Map<String, dynamic>>> _buildFriendRecommendations(
    String currentUserId,
    List<String> followingIds,
  ) async {
    return await ref.read(followControllerProvider).getFriendRecommendations(currentUserId, followingIds);
  }

  Future<void> _unblockUser(String blockedUserId, String currentUserId) async {
    try {
      await ref.read(feedControllerProvider.notifier).unblockUser(userIdToUnblock: blockedUserId);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('차단이 해제되었습니다')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    }
  }

  Future<Map<String, Map<String, dynamic>>>
  _buildFriendRecommendationsWithContacts(
    String currentUserId,
    List<String> followingIds,
  ) async {
    try {
      // Get friend recommendations first
      final recommendations = await _buildFriendRecommendations(
        currentUserId,
        followingIds,
      );

      // Get contact matches
      final contactMatches = await _getContactMatches(
        currentUserId,
        followingIds,
      );

      // Merge contacts with recommendations (contacts won't override recommendations)
      for (final entry in contactMatches.entries) {
        if (!recommendations.containsKey(entry.key)) {
          recommendations[entry.key] = entry.value;
        }
      }

      return recommendations;
    } catch (e) {
      debugPrint('Error building recommendations with contacts: $e');
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
      final matchingUsers = await _contactService.findUsersByPhoneNumbers(
        phoneNumbers,
      );

      final currentFollowers = await ref.read(feedControllerProvider.notifier).getFollowersIds(currentUserId);

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
      debugPrint('Error getting contact matches: $e');
      return {};
    }
  }
}
