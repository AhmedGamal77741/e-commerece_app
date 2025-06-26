import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/chat/ui/friends_screen.dart';
import 'package:ecommerece_app/features/home/data/post_provider.dart';
import 'package:ecommerece_app/features/home/follow_feed_screen.dart';
import 'package:ecommerece_app/features/home/widgets/guest_preview.dart/guest_post_item.dart';
import 'package:ecommerece_app/features/home/widgets/post_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 130.h,
          backgroundColor: ColorsManager.white,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => FriendsScreen()),
                  );
                },
                child: ImageIcon(AssetImage('assets/005 3.png'), size: 21),
              ),
              TabBar(
                labelStyle: TextStyle(
                  fontSize: 16.sp,
                  decoration: TextDecoration.none,
                  fontFamily: 'NotoSans',
                  fontStyle: FontStyle.normal,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0,
                  color: ColorsManager.primaryblack,
                ),
                unselectedLabelColor: ColorsManager.primary600,
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorColor: ColorsManager.primaryblack,
                tabs: [Tab(text: '추천'), Tab(text: '구독')],
              ),
            ],
          ),
        ),
        body: TabBarView(children: [_HomeFeedTab(), FollowingTab()]),
      ),
    );
  }
}

class _HomeFeedTab extends StatefulWidget {
  @override
  State<_HomeFeedTab> createState() => _HomeFeedTabState();
}

class _HomeFeedTabState extends State<_HomeFeedTab>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Colors.black));
        }

        final firebaseUser = authSnapshot.data;
        final postsProvider = Provider.of<PostsProvider>(
          context,
          listen: false,
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (firebaseUser == null) {
            postsProvider.resetListening();
          } else {
            postsProvider.startListening();
          }
        });

        // If no user, show the guest version of the UI
        if (firebaseUser == null) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Flexible(
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("내 페이지 탭에서 회원가입 후 이용가능합니다"),
                          ),
                        );
                      },
                      child: Container(
                        width: 56.w,
                        height: 55.h,
                        decoration: ShapeDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/mypage_icon.png'),
                            fit: BoxFit.cover,
                          ),
                          shape: OvalBorder(),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("내 페이지 탭에서 회원가입 후 이용가능합니다"),
                          ),
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.only(right: 10.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          spacing: 10.h,
                          children: [
                            Text(
                              '게스트 사용자',
                              style: TextStyles.abeezee16px400wPblack,
                            ),
                            FutureBuilder(
                              future:
                                  FirebaseFirestore.instance
                                      .collection('widgets')
                                      .doc('placeholders')
                                      .get(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                    ),
                                  );
                                }
                                if (snapshot.hasError) {
                                  return const Center(child: Text('Error'));
                                }
                                return Text(
                                  snapshot.data!
                                      .data()!['outerPlaceholderText'],
                                  style: TextStyle(
                                    color: const Color(0xFF5F5F5F),
                                    fontSize: 13.sp,
                                    fontFamily: 'NotoSans',
                                    fontWeight: FontWeight.w400,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              verticalSpace(5),
              Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('posts')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(color: Colors.black),
                      );
                    }
                    final posts = snapshot.data!.docs;
                    if (posts.isEmpty) {
                      return Center(child: Text('게시물이 없습니다.'));
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post =
                            posts[index].data() as Map<String, dynamic>;
                        if (post['postId'] == null) {
                          post['postId'] = posts[index].id;
                        }
                        return GuestPostItem(post: post);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        }

        // User is logged in, listen to user doc in real time
        return StreamBuilder<DocumentSnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .doc(firebaseUser.uid)
                  .snapshots(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(color: Colors.black),
              );
            }
            final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
            if (userData == null) {
              return Center(child: Text('User profile not found'));
            }
            final currentUser = MyUser.fromDocument(userData);

            // --- Non-premium user: can only view posts, but sees their own info ---
            if (!currentUser.isSub) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Flexible(
                        child: InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("프리미엄 가입 후 이용가능합니다"),
                              ),
                            );
                          },
                          child: Container(
                            width: 56.w,
                            height: 55.h,
                            decoration: ShapeDecoration(
                              image: DecorationImage(
                                image: NetworkImage(currentUser.url),
                                fit: BoxFit.cover,
                              ),
                              shape: OvalBorder(),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("프리미엄 가입 후 이용가능합니다"),
                              ),
                            );
                          },
                          child: Padding(
                            padding: EdgeInsets.only(right: 10.w),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentUser.name,
                                  style: TextStyles.abeezee16px400wPblack,
                                ),
                                FutureBuilder(
                                  future:
                                      FirebaseFirestore.instance
                                          .collection('widgets')
                                          .doc('placeholders')
                                          .get(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.black,
                                        ),
                                      );
                                    }
                                    if (snapshot.hasError) {
                                      return const Center(child: Text('Error'));
                                    }
                                    return Text(
                                      snapshot.data!
                                          .data()!['outerPlaceholderText'],
                                      style: TextStyle(
                                        color: const Color(0xFF5F5F5F),
                                        fontSize: 13.sp,
                                        fontFamily: 'NotoSans',
                                        fontWeight: FontWeight.w400,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  verticalSpace(5),
                  Divider(),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('posts')
                              .orderBy('createdAt', descending: true)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: Colors.black,
                            ),
                          );
                        }
                        final posts = snapshot.data!.docs;
                        if (posts.isEmpty) {
                          return Center(child: Text('게시물이 없습니다.'));
                        }
                        return ListView.builder(
                          controller: _scrollController,
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final post =
                                posts[index].data() as Map<String, dynamic>;
                            if (post['postId'] == null) {
                              post['postId'] = posts[index].id;
                            }
                            return GuestPostItem(post: post);
                            // Or, if you want to use PostItem:
                            // return PostItem(postId: post['postId'], fromComments: false, canInteract: false);
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            }

            // --- Premium user: full interaction ---
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Flexible(
                      child: InkWell(
                        onTap: () {
                          context.pushNamed(Routes.notificationsScreen);
                        },
                        child: StreamBuilder<QuerySnapshot>(
                          stream:
                              FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(currentUser.userId)
                                  .collection('notifications')
                                  .where('isRead', isEqualTo: false)
                                  .limit(1)
                                  .snapshots(),
                          builder: (context, notifSnapshot) {
                            final hasUnread =
                                notifSnapshot.hasData &&
                                notifSnapshot.data!.docs.isNotEmpty;
                            return Stack(
                              children: [
                                Container(
                                  width: 56.w,
                                  height: 55.h,
                                  decoration: ShapeDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        currentUser.url.toString(),
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                    shape: OvalBorder(),
                                  ),
                                ),
                                if (hasUnread)
                                  Positioned(
                                    right: 0.w,
                                    top: 0.h,
                                    child: Container(
                                      width: 18.w,
                                      height: 18.h,
                                      decoration: ShapeDecoration(
                                        color: const Color(0xFFDA3A48),
                                        shape: OvalBorder(),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: InkWell(
                        onTap: () {
                          context.go(Routes.addPostScreen);
                        },
                        child: Padding(
                          padding: EdgeInsets.only(right: 10.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 10.h,
                            children: [
                              Text(
                                currentUser.name.toString(),
                                style: TextStyles.abeezee16px400wPblack,
                              ),
                              FutureBuilder(
                                future:
                                    FirebaseFirestore.instance
                                        .collection('widgets')
                                        .doc('placeholders')
                                        .get(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.black,
                                      ),
                                    );
                                  }
                                  if (snapshot.hasError) {
                                    return const Center(child: Text('Error'));
                                  }
                                  return Text(
                                    snapshot.data!
                                        .data()!['outerPlaceholderText'],
                                    style: TextStyle(
                                      color: const Color(0xFF5F5F5F),
                                      fontSize: 13.sp,
                                      fontFamily: 'NotoSans',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                verticalSpace(5),
                Divider(),
                Expanded(
                  child: StreamBuilder<DocumentSnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUser.userId)
                            .snapshots(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(color: Colors.black),
                        );
                      }

                      if (userSnapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error loading user data: ${userSnapshot.error}',
                          ),
                        );
                      }

                      if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                        return Center(child: Text('User profile not found'));
                      }

                      List<String> blockedUsers = List<String>.from(
                        userSnapshot.data!.get('blocked') ?? [],
                      );

                      return StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('posts')
                                .orderBy('createdAt', descending: true)
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator(
                              color: Colors.black,
                            );
                          }

                          // Filter posts
                          final List<DocumentSnapshot> filteredPosts =
                              snapshot.data!.docs.where((doc) {
                                Map<String, dynamic> data =
                                    doc.data() as Map<String, dynamic>;

                                // Check if post is from a blocked user
                                if (blockedUsers.contains(data['userId'])) {
                                  return false;
                                }

                                // Check if user marked post as not interested
                                List<dynamic> notInterestedBy =
                                    List<dynamic>.from(
                                      data['notInterestedBy'] ?? [],
                                    );
                                if (notInterestedBy.contains(
                                  currentUser.userId,
                                )) {
                                  return false;
                                }

                                return true;
                              }).toList();

                          return ListView.builder(
                            controller: _scrollController,
                            itemCount: filteredPosts.length,
                            itemBuilder: (context, index) {
                              final post =
                                  filteredPosts[index].data()
                                      as Map<String, dynamic>;
                              return PostItem(
                                postId: post['postId'],
                                fromComments: false,
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
