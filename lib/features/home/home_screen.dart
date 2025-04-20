import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/helpers/extensions.dart';
import 'package:ecommerece_app/core/routing/routes.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/core/widgets/tab_app_bar.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/auth/signup/data/signup_functions.dart';
import 'package:ecommerece_app/features/home/widgets/post_item.dart';
import 'package:ecommerece_app/features/home/widgets/show_post_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    _loadData(); // Call the async function when widget initializes
  }

  // Async function that uses await
  Future<void> _loadData() async {
    try {
      currentUser = await FirebaseUserRepo().user.first;
      print(currentUser!.userId);
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print(e);
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1,
      child: Scaffold(
        appBar: TabAppBar(firstTab: 'Recommendations'),
        body: TabBarView(
          children: [
            Column(
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
                                'How was your day today?',
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

                //POSTS
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
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text('No posts yet'));
                      }

                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final post = snapshot.data!.docs[index];
                          return buildPostItem(post, context);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
