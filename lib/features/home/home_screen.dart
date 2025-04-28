import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/tab_app_bar.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/auth/signup/data/signup_functions.dart';
import 'package:ecommerece_app/features/home/data/post_provider.dart';
import 'package:ecommerece_app/features/home/widgets/post_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  MyUser? currentUser = MyUser(userId: "", email: "", name: "", url: "");
  bool liked = false;
  bool _isLoading = true;

  void initState() {
    super.initState();
    Provider.of<PostsProvider>(context, listen: false).startListening();

    _loadData();
  }

  // Async function that uses await
  Future<void> _loadData() async {
    try {
      currentUser = await FirebaseUserRepo().user.first;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1,
      child: Scaffold(
        appBar: TabAppBar(firstTab: '추천'),
        body: TabBarView(
          children: [
            _isLoading
                ? Center(child: CircularProgressIndicator(color: Colors.black))
                : Column(
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
                            child: Stack(
                              children: [
                                Container(
                                  width: 56.w,
                                  height: 55.h,
                                  decoration: ShapeDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        currentUser!.url.toString(),
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                    shape: OvalBorder(),
                                  ),
                                ),
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
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: InkWell(
                            onTap: () {
                              context.pushNamed(Routes.addPostScreen);
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
                                    currentUser!.name.toString(),
                                    style: TextStyles.abeezee16px400wPblack,
                                  ),
                                  Text(
                                    '오늘 하루 어땠는지 말해줘',
                                    style: TextStyle(
                                      color: const Color(0xFF5F5F5F),
                                      fontSize: 13.sp,
                                      fontFamily: 'ABeeZee',
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    verticalSpace(5),
                    //POSTS
                    Divider(),
                    Expanded(
                      child: StreamBuilder<DocumentSnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('users')
                                .doc(currentUser!.userId)
                                .snapshots(),
                        builder: (context, userSnapshot) {
                          if (userSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (userSnapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error loading user data: ${userSnapshot.error}',
                              ),
                            );
                          }

                          if (!userSnapshot.hasData ||
                              !userSnapshot.data!.exists) {
                            return Center(
                              child: Text('User profile not found'),
                            );
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
                                return CircularProgressIndicator();
                              }

                              // Get current user information
                              final currentUser =
                                  FirebaseAuth.instance.currentUser;
                              if (currentUser == null) {
                                return Text(
                                  'You need to be logged in to view posts',
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
                                      currentUser.uid,
                                    )) {
                                      return false;
                                    }

                                    return true;
                                  }).toList();

                              return ListView.builder(
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
                      /* Selector<PostsProvider, List<String>>(
                        selector: (_, provider) => provider.postIds,
                        builder: (context, postIds, child) {
                          if (postIds.isEmpty) {
                            return Center(child: CircularProgressIndicator());
                          }
                          return ListView.separated(
                            separatorBuilder: (context, index) {
                              // Don't add a divider after the last item
                              if (index == postIds.length - 1) {
                                return SizedBox.shrink();
                              }
                              return Divider(color: ColorsManager.primary100);
                            },

                            itemCount: postIds.length,
                            itemBuilder: (context, index) {
                              final postId = postIds[index];
                              final postData = Provider.of<PostsProvider>(
                                context,
                                listen: false,
                              ).getPost(postId);
                              final notInterestedBy = List<String>.from(
                                postData!['notInterestedBy'] ?? [],
                              );

                              if (notInterestedBy.contains(
                                currentUser!.userId,
                              )) {
                                return SizedBox.shrink();
                              }
                              return PostItem(
                                postId: postId,
                                fromComments: false,
                              );
                            },
                          );
                        },
                      ), */
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}
