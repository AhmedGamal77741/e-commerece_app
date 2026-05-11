import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/theming/styles.dart';
import 'package:ecommerece_app/features/home/widgets/guest_preview.dart/guest_comment_item.dart';
import 'package:ecommerece_app/features/home/widgets/guest_preview.dart/guest_post_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GuestComments extends StatelessWidget {
  final Map<String, dynamic> post;
  const GuestComments({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── FIX: use MediaQuery width instead of relying on
              // LayoutBuilder inside a Column/SingleChildScrollView
              // (which gives unbounded maxWidth).
              // Subtracts all horizontal padding that wraps the image:
              //   • outer right: 10.w  (Padding below)
              //   • GuestPostItem internal left: 10.w + right: 10.w
              Builder(
                builder: (context) {
                  final double imageWidth =
                      MediaQuery.of(context).size.width - 10.w - 10.w - 10.w;
                  return Padding(
                    padding: EdgeInsets.only(right: 10.w),
                    child: GuestPostItem(post: post, imageWidth: imageWidth),
                  );
                },
              ),

              verticalSpace(30),

              // Comments list
              StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('posts')
                        .doc(post['postId'])
                        .collection('comments')
                        .orderBy('createdAt', descending: false)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.h),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('댓글을 불러올 수 없습니다'));
                  }

                  final comments = snapshot.data?.docs ?? [];

                  if (comments.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.h),
                        child: Text(
                          '아직 댓글이 없습니다. 첫 번째 댓글을 남겨보세요!',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14.sp,
                            fontFamily: 'NotoSans',
                          ),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment =
                          comments[index].data() as Map<String, dynamic>;
                      return Column(
                        children: [
                          GuestCommentItem(comment: comment),
                          SizedBox(height: 16.h),
                        ],
                      );
                    },
                  );
                },
              ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
}
