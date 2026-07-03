import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/core/widgets/safe_network_image.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/home/widgets/guest_preview.dart/guest_post_item.dart';
import 'package:ecommerece_app/features/home/widgets/post_item.dart';
import 'package:ecommerece_app/features/auth/domain/auth_controller.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
import 'package:ecommerece_app/features/home/domain/follow_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileTab extends ConsumerStatefulWidget {
  final String userId;

  const ProfileTab({super.key, required this.userId});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  String? selectedCategoryId;
  late PageController _pageController;
  List<String?> _categoryPages = [null];
  Stream<DocumentSnapshot>? _userStream;
  Stream<QuerySnapshot>? _categoriesStream;
  String? _cachedCategoriesUserId;

  Stream<QuerySnapshot> _getCategoriesStream(String userId) {
    if (_categoriesStream == null || _cachedCategoriesUserId != userId) {
      _cachedCategoriesUserId = userId;
      _categoriesStream = ref
          .read(feedControllerProvider.notifier)
          .getUserCategoriesStream(userId);
    }
    return _categoriesStream!;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _userStream = ref
        .read(feedControllerProvider.notifier)
        .getUserStream(widget.userId);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onCategorySelected(String categoryId) {
    final index = _categoryPages.indexOf(
      categoryId.isEmpty ? null : categoryId,
    );
    if (index != -1) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    final categoryId = _categoryPages[index];
    setState(() {
      selectedCategoryId = categoryId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _userStream,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Center(child: Text('사용자 프로필을 찾을 수 없습니다'));
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final profileUser = MyUser.fromDocument(userData);

        return StreamBuilder<QuerySnapshot>(
          stream: _getCategoriesStream(profileUser.userId),
          builder: (context, categorySnapshot) {
            if (categorySnapshot.hasData) {
              _categoryPages = [
                null,
                ...categorySnapshot.data!.docs.map((doc) => doc.id),
              ];
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    // Back button row
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.arrow_back, size: 24.sp),
                        ),
                        const Spacer(),
                      ],
                    ),
                    verticalSpace(10),
                    // Profile Image - no tap for other users
                    ClipOval(
                      child: SafeNetworkImage(
                        url: profileUser.url,
                        width: 64.w,
                        height: 64.h,
                        fit: BoxFit.cover,
                        errorWidget: Icon(Icons.person, size: 64.h),
                        placeholder: const SizedBox.shrink(),
                      ),
                    ),
                    verticalSpace(4),
                    Text(
                      profileUser.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final syncName = ref.watch(
                          contactNicknameProvider(profileUser.userId),
                        );
                        if (syncName == null || syncName.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: EdgeInsets.only(top: 2.h),
                          child: Text(
                            '@$syncName',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        );
                      },
                    ),
                    verticalSpace(10),

                    UserCategoriesBar(
                      categories:
                          categorySnapshot.hasData
                              ? categorySnapshot.data!.docs
                              : const [],
                      selectedCategoryId: selectedCategoryId,
                      onCategorySelected: _onCategorySelected,
                    ),

                    verticalSpace(10),

                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _categoryPages.length,
                        onPageChanged: _onPageChanged,
                        itemBuilder: (context, index) {
                          return _PostsPage(
                            userId: profileUser.userId,
                            categoryId: _categoryPages[index],
                          );
                        },
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
  }
}

// Each page owns its own stable stream + stays alive when swiped away
class _PostsPage extends ConsumerStatefulWidget {
  final String userId;
  final String? categoryId;

  const _PostsPage({required this.userId, this.categoryId});

  @override
  ConsumerState<_PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends ConsumerState<_PostsPage>
    with AutomaticKeepAliveClientMixin {
  late final Stream<QuerySnapshot> _stream;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _stream = ref
        .read(feedControllerProvider.notifier)
        .getUserPostsStream(widget.userId, categoryId: widget.categoryId);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return StreamBuilder<QuerySnapshot>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          return const Center(child: Text('게시물을 불러오지 못했습니다'));
        }

        final posts = snapshot.data!.docs;

        if (posts.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Text(
                widget.categoryId == null
                    ? '아직 작성한 게시물이 없습니다.'
                    : '이 카테고리에 게시물이 없습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
              ),
            ),
          );
        }
        final bool isGuest = ref.watch(currentUserProvider).value == null;
        return ListView.builder(
          itemCount: posts.length,
          cacheExtent: 1200,
          itemBuilder: (context, index) {
            final doc = posts[index];
            final post = doc.data() as Map<String, dynamic>;
            if (post['postId'] == null) {
              post['postId'] = doc.id;
            }
            return RepaintBoundary(
              key: ValueKey(doc.id),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Column(
                  children: [
                    if (index != 0) Divider(color: ColorsManager.primary100),
                    isGuest
                        ? GuestPostItem(
                          post: post,
                          currentProfileUserId: widget.userId,
                        )
                        : PostItem(
                          postId: doc.id,
                          fromComments: false,
                          currentProfileUserId: widget.userId,
                          postData: post,
                        ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class UserCategoriesBar extends ConsumerWidget {
  final List<QueryDocumentSnapshot> categories;
  final String? selectedCategoryId;
  final Function(String) onCategorySelected;

  const UserCategoriesBar({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 50.h,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SizedBox(width: 16.w),
            _pill(
              '뉴스',
              selectedCategoryId == null,
              () => onCategorySelected(''),
            ),
            ...categories.map((cat) {
              final name = (cat.data() as Map<String, dynamic>)['name'] ?? '';
              return Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: _pill(
                  name,
                  selectedCategoryId == cat.id,
                  () => onCategorySelected(cat.id),
                ),
              );
            }),
            SizedBox(width: 16.w),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: selected ? Colors.grey : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13.sp,
            color: selected ? Colors.white : Colors.grey[600],
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
