import 'dart:async';
import 'package:ecommerece_app/core/providers/firebase_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
import 'package:ecommerece_app/features/home/follow_feed_screen.dart';
import 'package:ecommerece_app/features/home/search_screen.dart';
import 'package:ecommerece_app/features/home/widgets/guest_preview.dart/guest_post_item.dart';
import 'package:ecommerece_app/features/home/widgets/post_item.dart';
import 'package:ecommerece_app/features/home/my_story.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final ScrollController? scrollController;
  final TabController? tabController;
  const HomeScreen({super.key, this.scrollController, this.tabController});

  @override
  ConsumerState<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends ConsumerState<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int _selectedIndex = 0;
  bool isSub = false;
  late final ScrollController _feedTabController;
  late final ScrollController _followingTabController;
  late final ScrollController _myStoryTabController;

  /// Called by NavBar when the home icon is tapped while already on home.
  void resetToTop() {
    // Pop any navigator sub-pages back to root
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    // Scroll to top of the current tab
    final controller =
        _selectedIndex == 0
            ? _feedTabController
            : _selectedIndex == 1
            ? _followingTabController
            : _myStoryTabController;

    if (controller.hasClients) {
      controller.animateTo(
        0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _feedTabController = ScrollController();
    _followingTabController = ScrollController();
    _myStoryTabController = ScrollController();
  }

  @override
  void dispose() {
    _feedTabController.dispose();
    _followingTabController.dispose();
    _myStoryTabController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _userTabs = [
    {'label': '추천'},
    {'label': '구독'},
    {'label': 'MY'},
  ];

  final List<Map<String, dynamic>> _nonUserTabs = [
    {'label': '추천'},
  ];

  Widget _buildPill(int index) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _userTabs[index]['label'],
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildNormalPillRow(User? firebaseUser) {
    return Padding(
      padding: EdgeInsets.fromLTRB(5.w, 0, 5.w, 5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        key: const ValueKey('pills'),
        children: [
          firebaseUser == null
              ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int i = 0; i < _nonUserTabs.length; i++) ...[
                      _buildPill(i),
                      if (i < _nonUserTabs.length - 1) SizedBox(width: 8.w),
                    ],
                  ],
                ),
              )
              : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int i = 0; i < _userTabs.length; i++) ...[
                      _buildPill(i),
                      if (i < _userTabs.length - 1) SizedBox(width: 8.w),
                    ],
                  ],
                ),
              ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: () {
                  if (firebaseUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("검색은 회원가입 후 이용가능합니다")),
                    );
                    return;
                  }
                  context.pushNamed(Routes.alertsScreen);
                },
                child:
                    firebaseUser == null
                        ? Image.asset(
                          'assets/notification_bell_transparent.png',
                          height: 35.h,
                          width: 35.w,
                        )
                        : StreamBuilder<QuerySnapshot>(
                          stream: ref.read(feedControllerProvider).getUnreadNotificationsStream(firebaseUser.uid),
                          builder: (context, notifSnapshot) {
                            final hasUnread =
                                notifSnapshot.hasData &&
                                notifSnapshot.data!.docs.isNotEmpty;
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Image.asset(
                                  'assets/notification_bell_transparent.png',
                                  height: 35.h,
                                  width: 35.w,
                                ),
                                if (hasUnread)
                                  Positioned(
                                    left: 0.w,
                                    top: 0.h,
                                    child: Image.asset(
                                      'assets/notification_dot.png',
                                      width: 18.w,
                                      height: 18.h,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
              ),
              InkWell(
                onTap: () {
                  if (firebaseUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("검색은 회원가입 후 이용가능합니다")),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeSearch(initialTabIndex: 1),
                    ),
                  );
                },
                child: ImageIcon(
                  AssetImage('assets/search_icon.png'),
                  color: Colors.black,
                  size: 30.r,
                ),
              ),
              horizontalSpace(5),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authState = ref.watch(authStateProvider);
    final firebaseUser = authState.value;
    return _buildScaffold(firebaseUser, widget.tabController, _selectedIndex);
  }

  Widget _buildScaffold(
    User? firebaseUser,
    TabController? tabController,
    int floating,
  ) {
    return SafeArea(
      child: Scaffold(
        floatingActionButton:
            (floating == 0 || floating == 2) && firebaseUser != null
                ? StreamBuilder(
                  stream: ref.read(feedControllerProvider).getUserStream(firebaseUser.uid),
                  builder: (context, asyncSnapshot) {
                    if (!asyncSnapshot.hasData) {
                      return SizedBox.shrink();
                    }
                    final userData =
                        asyncSnapshot.data!.data() as Map<String, dynamic>?;
                    if (userData == null) {
                      return SizedBox.shrink();
                    }
                    final currentUser = MyUser.fromDocument(userData);
                    if (!currentUser.isSub) {
                      return SizedBox.shrink();
                    }
                    return FloatingActionButton(
                      heroTag: floating == 0 ? "home_feed_fab" : "MY_feed_fab",
                      shape: CircleBorder(),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      highlightElevation: 0,
                      onPressed: () {
                        context.go(Routes.addPostScreen);
                      },
                      child: ClipOval(
                        child: Image.asset(
                          "assets/add_post_transparent.png",
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                )
                : null,

        body: Column(
          children: [
            _buildNormalPillRow(firebaseUser),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _HomeFeedTab(scrollController: _feedTabController),
                  FollowingTab(
                    firebaseUser: firebaseUser,
                    scrollController: _followingTabController,
                  ),
                  MyStory(scrollController: _myStoryTabController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeFeedTab extends ConsumerStatefulWidget {
  final ScrollController? scrollController;
  const _HomeFeedTab({this.scrollController});
  @override
  ConsumerState<_HomeFeedTab> createState() => _HomeFeedTabState();
}

class _HomeFeedTabState extends ConsumerState<_HomeFeedTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Data caches to prevent StreamBuilder flickering and waiting states
  DocumentSnapshot? _lastProfileDoc;
  QuerySnapshot? _lastFollowingDocs;
  QuerySnapshot? _lastPostsDocs;
  Map<String, Map<String, dynamic>>? _lastAuthorsData;

  Stream<QuerySnapshot>? _postsStream;

  Stream<DocumentSnapshot>? _userProfileStream;
  Stream<QuerySnapshot>? _followingStream;
  Stream<QuerySnapshot>? _hiddenFriendsStream;
  String? _cachedUserId;

  List<String> _cachedAuthorIds = [];
  Stream<Map<String, Map<String, dynamic>>>? _cachedAuthorStream;



  // Helper to get or update stable streams based on current user
  void _updateStreamsIfNecessary(String uid) {
    if (_cachedUserId != uid) {
      _cachedUserId = uid;
      final feedController = ref.read(feedControllerProvider);
      _userProfileStream = feedController.getUserStream(uid);
      _followingStream = feedController.getFollowingStreamForUser(uid);
      _hiddenFriendsStream = feedController.getHiddenFriendsStream(uid);
    }
  }

  Stream<Map<String, Map<String, dynamic>>> _getStableAuthorStream(
    List<String> newAuthorIds,
  ) {
    bool isSame = _cachedAuthorIds.length == newAuthorIds.length;
    if (isSame) {
      final sortedCached = List<String>.from(_cachedAuthorIds)..sort();
      final sortedNew = List<String>.from(newAuthorIds)..sort();
      for (int i = 0; i < sortedNew.length; i++) {
        if (sortedCached[i] != sortedNew[i]) {
          isSame = false;
          break;
        }
      }
    }

    if (!isSame || _cachedAuthorStream == null) {
      _cachedAuthorIds = List.from(newAuthorIds);
      _cachedAuthorStream = ref.read(feedControllerProvider).getAuthorsDataStreamRealtime(_cachedAuthorIds);
    }

    return _cachedAuthorStream!;
  }

  @override
  void dispose() {
    super.dispose();
  }



  bool _shouldShowPost({
    required String postAuthorId,
    required String currentUserId,
    required Map<String, dynamic> authorData,
    required Set<String> followingSet,
  }) {
    if (postAuthorId == currentUserId) {
      return false;
    }

    final bool isPrivate = authorData['isPrivate'] ?? false;

    if (!isPrivate) {
      return true;
    }

    return followingSet.contains(postAuthorId);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    _postsStream ??= ref.read(feedControllerProvider).searchPostsStream();

    final authState = ref.watch(authStateProvider);
    if (authState.isLoading) {
      return const Center();
    }

    final firebaseUser = authState.value;
    final postsProvider = ref.read(feedControllerProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (firebaseUser == null) {
        postsProvider.resetListening();
      } else {
        postsProvider.startListening();
      }
    });

    if (firebaseUser == null) {
          _cachedUserId = null;
          _lastProfileDoc = null;
          _lastFollowingDocs = null;
          _lastAuthorsData = null;
          _cachedAuthorIds.clear();
          _cachedAuthorStream = null;
          return StreamBuilder<QuerySnapshot>(
            stream: _postsStream,
            initialData: _lastPostsDocs,
            builder: (context, postsSnapshot) {
              if (postsSnapshot.hasData) {
                _lastPostsDocs = postsSnapshot.data;
              }
              if (postsSnapshot.connectionState == ConnectionState.waiting &&
                  !postsSnapshot.hasData) {
                return Center();
              }
              if (postsSnapshot.hasError) {
                return Center(child: Text('Error: ${postsSnapshot.error}'));
              }

              final List<QueryDocumentSnapshot> posts = postsSnapshot.data?.docs ?? [];

              final authorIds = <String>{};
              for (var post in posts) {
                final data = post.data() as Map<String, dynamic>;
                authorIds.add(data['userId'] as String);
              }

              return StreamBuilder<Map<String, Map<String, dynamic>>>(
                stream: _getStableAuthorStream(authorIds.toList()),
                initialData: _lastAuthorsData,
                builder: (context, authorsSnapshot) {
                  if (authorsSnapshot.hasData) {
                    _lastAuthorsData = authorsSnapshot.data;
                  }
                  if (!authorsSnapshot.hasData) {
                    return Center();
                  }

                  final authorsMap = authorsSnapshot.data ?? {};

                  final filteredPosts =
                      posts.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final authorData =
                            authorsMap[data['userId'] as String] ?? {};
                        return (authorData['isPrivate'] ?? false) == false;
                      }).toList();

                  return ListView.builder(
                    shrinkWrap: true,
                    controller: widget.scrollController,
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      final post =
                          filteredPosts[index].data() as Map<String, dynamic>;
                      final postId = filteredPosts[index].id;
                      if (post['postId'] == null) {
                        post['postId'] = postId;
                      }
                      return Column(
                        key: ValueKey(postId),
                        children: [
                          GuestPostItem(post: post),
                          verticalSpace(10),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        }

        _updateStreamsIfNecessary(firebaseUser.uid);

        return StreamBuilder<DocumentSnapshot>(
          stream: _userProfileStream,
          initialData: _lastProfileDoc,
          builder: (context, userSnapshot) {
            if (userSnapshot.hasData) {
              _lastProfileDoc = userSnapshot.data;
            }
            if (!userSnapshot.hasData) {
              return Center();
            }
            final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
            if (userData == null) {
              return Center(child: Text('User profile not found'));
            }
            final currentUser = MyUser.fromDocument(userData);

            List<String> blockedUsers = List<String>.from(
              (userData['blocked'] as List<dynamic>?) ?? [],
            );

            return StreamBuilder<QuerySnapshot>(
              stream: _hiddenFriendsStream,
              builder: (context, hiddenFriendsSnapshot) {
                final hiddenFriendsSet = <String>{};
                if (hiddenFriendsSnapshot.hasData) {
                  for (var doc in hiddenFriendsSnapshot.data!.docs) {
                    hiddenFriendsSet.add(doc.id);
                  }
                }

                if (!currentUser.isSub) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: _postsStream,
                    initialData: _lastPostsDocs,
                    builder: (context, postsSnapshot) {
                      if (postsSnapshot.hasData) {
                        _lastPostsDocs = postsSnapshot.data;
                      }
                      if (postsSnapshot.connectionState ==
                              ConnectionState.waiting &&
                          !postsSnapshot.hasData) {
                        return Center();
                      }
                      if (postsSnapshot.hasError) {
                        return Center(
                          child: Text('Error: ${postsSnapshot.error}'),
                        );
                      }

                      final posts = postsSnapshot.data?.docs ?? [];

                      final authorIds = <String>{};
                      for (var post in posts) {
                        final data = post.data() as Map<String, dynamic>;
                        if ((data['userId'] as String) == currentUser.userId) {
                          continue;
                        }
                        authorIds.add(data['userId'] as String);
                      }

                      return StreamBuilder<Map<String, Map<String, dynamic>>>(
                        stream: _getStableAuthorStream(authorIds.toList()),
                        initialData: _lastAuthorsData,
                        builder: (context, authorsSnapshot) {
                          if (authorsSnapshot.hasData) {
                            _lastAuthorsData = authorsSnapshot.data;
                          }
                          if (!authorsSnapshot.hasData) {
                            return Center();
                          }

                          final authorsMap = authorsSnapshot.data ?? {};

                          final filteredPosts =
                              posts.where((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final postAuthorId = data['userId'] as String;

                                if (postAuthorId == currentUser.userId) {
                                  return false;
                                }
                                if (blockedUsers.contains(postAuthorId) ||
                                    hiddenFriendsSet.contains(postAuthorId)) {
                                  return false;
                                }

                                final authorData =
                                    authorsMap[postAuthorId] ?? {};
                                final authorBlockedUsers = List<dynamic>.from(
                                  authorData['blocked'] ?? [],
                                );
                                if (authorBlockedUsers.contains(
                                  currentUser.userId,
                                )) {
                                  return false;
                                }

                                final notInterestedBy = List<dynamic>.from(
                                  data['notInterestedBy'] ?? [],
                                );
                                if (notInterestedBy.contains(
                                  currentUser.userId,
                                )) {
                                  return false;
                                }

                                return (authorData['isPrivate'] ?? false) ==
                                    false;
                              }).toList();

                          return ListView.builder(
                            shrinkWrap: true,
                            controller: widget.scrollController,
                            itemCount: filteredPosts.length,
                            itemBuilder: (context, index) {
                              final post =
                                  filteredPosts[index].data()
                                      as Map<String, dynamic>;
                              final postId = filteredPosts[index].id;
                              if (post['postId'] == null) {
                                post['postId'] = postId;
                              }
                              return Column(
                                key: ValueKey(post['postId']),
                                children: [
                                  PostItem(
                                    postId: post['postId'],
                                    fromComments: false,
                                  ),
                                  verticalSpace(10),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                }

                // (blockedUsers already extracted above)

                return StreamBuilder<QuerySnapshot>(
                  stream: _followingStream,
                  initialData: _lastFollowingDocs,
                  builder: (context, followingSnapshot) {
                    if (followingSnapshot.hasData) {
                      _lastFollowingDocs = followingSnapshot.data;
                    }
                    final followingSet = <String>{};
                    if (followingSnapshot.hasData) {
                      for (var doc in followingSnapshot.data!.docs) {
                        final userId = doc.get('userId') as String?;
                        if (userId != null) {
                          followingSet.add(userId);
                        }
                      }
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream: _postsStream,
                      initialData: _lastPostsDocs,
                      builder: (context, postsSnapshot) {
                        if (postsSnapshot.hasData) {
                          _lastPostsDocs = postsSnapshot.data;
                        }
                        if (postsSnapshot.connectionState ==
                                ConnectionState.waiting &&
                            !postsSnapshot.hasData) {
                          return Center();
                        }
                        if (postsSnapshot.hasError) {
                          return Center(
                            child: Text('Error: ${postsSnapshot.error}'),
                          );
                        }

                        final posts = postsSnapshot.data?.docs ?? [];

                        final authorIds = <String>{};
                        for (var post in posts) {
                          final data = post.data() as Map<String, dynamic>;
                          if ((data['userId'] as String) ==
                              currentUser.userId) {
                            continue;
                          }
                          authorIds.add(data['userId'] as String);
                        }

                        return StreamBuilder<Map<String, Map<String, dynamic>>>(
                          stream: _getStableAuthorStream(authorIds.toList()),
                          initialData: _lastAuthorsData,
                          builder: (context, authorsSnapshot) {
                            if (authorsSnapshot.hasData) {
                              _lastAuthorsData = authorsSnapshot.data;
                            }
                            if (!authorsSnapshot.hasData) {
                              return Center();
                            }

                            final authorsMap = authorsSnapshot.data ?? {};

                            final List<DocumentSnapshot> filteredPosts =
                                posts.where((doc) {
                                  final data =
                                      doc.data() as Map<String, dynamic>;
                                  final postAuthorId = data['userId'] as String;
                                  final authorData =
                                      authorsMap[postAuthorId] ?? {};

                                  if (blockedUsers.contains(postAuthorId) ||
                                      hiddenFriendsSet.contains(postAuthorId)) {
                                    return false;
                                  }

                                  final authorBlockedUsers = List<dynamic>.from(
                                    authorData['blocked'] ?? [],
                                  );
                                  if (authorBlockedUsers.contains(
                                    currentUser.userId,
                                  )) {
                                    return false;
                                  }

                                  final notInterestedBy = List<dynamic>.from(
                                    data['notInterestedBy'] ?? [],
                                  );
                                  if (notInterestedBy.contains(
                                    currentUser.userId,
                                  )) {
                                    return false;
                                  }

                                  return _shouldShowPost(
                                    postAuthorId: postAuthorId,
                                    currentUserId: currentUser.userId,
                                    authorData: authorData,
                                    followingSet: followingSet,
                                  );
                                }).toList();

                            return ListView.builder(
                              shrinkWrap: true,
                              controller: widget.scrollController,
                              itemCount: filteredPosts.length + 1,
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [],
                                  );
                                } else {
                                  final post =
                                      filteredPosts[index - 1].data()
                                          as Map<String, dynamic>;
                                  return Column(
                                    key: ValueKey(post['postId']),
                                    children: [
                                      PostItem(
                                        postId: post['postId'],
                                        fromComments: false,
                                      ),
                                      SizedBox(height: 16.h),
                                    ],
                                  );
                                }
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
  }
}
