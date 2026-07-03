import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecommerece_app/core/widgets/safe_network_image.dart';

class FollowingUsersList extends ConsumerStatefulWidget {
  final List<MyUser> followingUsers;
  final void Function(String userId)? onUserTap;
  final String? selectedUserId;

  const FollowingUsersList({
    super.key,
    required this.followingUsers,
    this.onUserTap,
    this.selectedUserId,
  });

  @override
  ConsumerState<FollowingUsersList> createState() => _FollowingUsersListState();
}

class _FollowingUsersListState extends ConsumerState<FollowingUsersList> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();

    // 1. Find the initial index of the preselected user
    int initialPage = 0;
    if (widget.selectedUserId != null) {
      initialPage = widget.followingUsers.indexWhere(
        (u) => u.userId == widget.selectedUserId!,
      );
      // If not found (index -1), default back to 0
      if (initialPage == -1) initialPage = 0;
    }

    // 2. Initialize controller at that specific page
    _pageController = PageController(
      viewportFraction: 0.15,
      initialPage: initialPage,
    );
  }

  @override
  void didUpdateWidget(FollowingUsersList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedUserId != null) {
      final index = widget.followingUsers.indexWhere(
        (u) => u.userId == widget.selectedUserId!,
      );
      if (index != -1 && _pageController.hasClients) {
        final oldIndex = oldWidget.followingUsers.indexWhere(
          (u) => u.userId == oldWidget.selectedUserId,
        );
        if (index != oldIndex || widget.selectedUserId != oldWidget.selectedUserId) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.followingUsers.length,
      onPageChanged: (index) {
        if (widget.onUserTap != null) {
          final userId = widget.followingUsers[index].userId;
          if (userId != widget.selectedUserId) {
            widget.onUserTap!(userId);
          }
        }
      },
      itemBuilder: (context, index) {
        final user = widget.followingUsers[index];
        final isSelected = widget.selectedUserId == user.userId;

        return GestureDetector(
          onTap: () {
            widget.onUserTap?.call(user.userId);
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
            );
          },
          child: AnimatedScale(
            scale: isSelected ? 1.0 : 0.8,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: AnimatedOpacity(
              opacity: widget.selectedUserId == null || isSelected ? 1 : 0.5,
              duration: const Duration(milliseconds: 200),
              child: SizedBox(
                width: 72.w,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration:
                          isSelected
                              ? BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  width: 2,
                                  color: Colors.black,
                                ),
                              )
                              : null,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: safeNetworkImageProvider(user.url),
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
