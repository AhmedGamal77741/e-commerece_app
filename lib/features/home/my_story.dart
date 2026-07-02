import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecommerece_app/core/helpers/loading_service.dart';
import 'package:ecommerece_app/core/helpers/spacing.dart';
import 'package:ecommerece_app/core/widgets/safe_network_image.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/home/widgets/post_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/features/home/domain/feed_controller.dart';
import 'package:ecommerece_app/features/auth/domain/auth_controller.dart';
import 'package:ecommerece_app/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecommerece_app/core/helpers/image_picker_helper.dart';

class MyStory extends ConsumerStatefulWidget {
  final ScrollController? scrollController;
  const MyStory({super.key, this.scrollController});
  @override
  ConsumerState<MyStory> createState() => _MyStoryState();
}

class _MyStoryState extends ConsumerState<MyStory> {
  String? selectedCategoryId;
  late PageController _pageController;
  List<String?> _categoryPages = [null];
  final ValueNotifier<int> _currentPageIndex = ValueNotifier(0);
  String imgUrl = "";
  Stream<QuerySnapshot>? _categoriesStream;
  String? _cachedCategoriesUserId;

  Stream<QuerySnapshot> _getCategoriesStream(String userId) {
    if (_categoriesStream == null || _cachedCategoriesUserId != userId) {
      _cachedCategoriesUserId = userId;
      _categoriesStream = ref.read(feedControllerProvider.notifier).getUserCategoriesStream(userId);
    }
    return _categoriesStream!;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _currentPageIndex.dispose();
    super.dispose();
  }

  void _onCategorySelected(String categoryId) {
    setState(() {
      selectedCategoryId = categoryId.isEmpty ? null : categoryId;
    });
    
    final index = _categoryPages.indexOf(
      categoryId.isEmpty ? null : categoryId,
    );
    if (index != -1) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _currentPageIndex.value = index;
    }
  }

  void _onPageChanged(int index) {
    final categoryId = _categoryPages[index];
    setState(() {
      selectedCategoryId = categoryId;
    });
    _currentPageIndex.value = index;
  }

  /*   void _onCategorySelected(String categoryId) {
    setState(() {
      if (categoryId.isEmpty || selectedCategoryId == categoryId) {
        selectedCategoryId = null;
      } else {
        selectedCategoryId = categoryId;
      }
    });
  } */

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const Center(child: Text('스토리를 보려면 로그인하세요')),
      data: (currentUser) {
        if (currentUser == null) {
          return const Center(child: Text('스토리를 보려면 로그인하세요'));
        }

        return StreamBuilder<QuerySnapshot>(
          stream: _getCategoriesStream(currentUser.userId),
          builder: (context, categorySnapshot) {
            if (categorySnapshot.hasData) {
              _categoryPages = [
                null,
                ...categorySnapshot.data!.docs.map((doc) => doc.id),
              ];
            }

            return NestedScrollView(
              controller: widget.scrollController,
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        verticalSpace(10),
                        InkWell(
                          onTap: () async {
                            LoadingService().showLoading();
                            final image = await ImagePickerHelper.pickImage();
                            if (image != null) {
                              final newUrl = await ref.read(authRepositoryProvider).uploadProfileImage(image, currentUser.userId);
                              
                              final updatedUser = MyUser(
                                userId: currentUser.userId,
                                email: currentUser.email,
                                name: currentUser.name,
                                url: newUrl,
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
                                phoneNumber: currentUser.phoneNumber,
                              );
                              
                              await ref.read(authNotifierProvider.notifier).updateUser(updatedUser, '');
                            }
                            LoadingService().hideLoading();
                          },
                          child: ClipOval(
                            child: SafeNetworkImage(
                              url: imgUrl.isEmpty ? currentUser.url : imgUrl,
                              width: 64.w,
                              height: 64.h,
                              fit: BoxFit.cover,
                              errorWidget: Icon(Icons.person, size: 64.h),
                              placeholder: SizedBox(
                                width: 64.w,
                                height: 64.h,
                                child: const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          currentUser.name,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                      ],
                    ),
                  ),
                ];
              },
              body: PageView.builder(
                controller: _pageController,
                itemCount: _categoryPages.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return _PostsPage(
                    userId: currentUser.userId,
                    categoryId: _categoryPages[index],
                  );
                },
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
  const _PostsPage({
    required this.userId,
    this.categoryId,
  });

  @override
  ConsumerState<_PostsPage> createState() => _PostsPageState();
}

class _PostsPageState extends ConsumerState<_PostsPage>
    with AutomaticKeepAliveClientMixin {
  late Stream<QuerySnapshot> _stream;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _stream = ref.read(feedControllerProvider.notifier).getUserPostsStream(
      widget.userId,
      categoryId: widget.categoryId,
    );
  }

  @override
  void didUpdateWidget(_PostsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId || oldWidget.categoryId != widget.categoryId) {
      _stream = ref.read(feedControllerProvider.notifier).getUserPostsStream(
        widget.userId,
        categoryId: widget.categoryId,
      );
    }
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
          debugPrint('Error loading posts: ${snapshot.error}');
          return Center(child: Text('Error: ${snapshot.error}'));
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

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return Column(
              children: [
                PostItem(postId: posts[index].id, fromComments: false),
                verticalSpace(10),
              ],
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
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? const Color(0xFF9E9E9E) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14.sp,
            color: selected ? const Color(0xFF424242) : const Color(0xFF9E9E9E),
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
