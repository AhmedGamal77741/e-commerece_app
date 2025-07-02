import 'dart:io';

import 'package:ecommerece_app/features/chat/services/chat_service.dart';
import 'package:ecommerece_app/features/chat/services/friends_service.dart';
import 'package:ecommerece_app/features/home/data/home_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

class ExpandableFAB extends StatefulWidget {
  const ExpandableFAB({Key? key}) : super(key: key);

  @override
  State<ExpandableFAB> createState() => _ExpandableFABState();
}

class _ExpandableFABState extends State<ExpandableFAB>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animation);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250.w,
      height: 250.h,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, 40 - _animation.value * 70),
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  alignment: Alignment.bottomRight,
                  child: Opacity(
                    opacity: _animation.value,
                    child: Container(
                      width: 200.w,
                      height: 200.h,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(40),
                          bottomLeft: Radius.circular(40),
                        ),

                        border: Border.all(color: Colors.grey[300]!, width: 1),
                        color: Colors.grey[200],
                        boxShadow: [],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildMenuItem(
                              icon: "assets/group_active_1.png",

                              label: '그룹 만들기',
                              onTap: () async {
                                await showCreateGroupDialog(context, (
                                  name,
                                  userIds,
                                  groupImage,
                                ) async {
                                  // Call your ChatService.createGroupChatRoom here
                                  await ChatService().createGroupChatRoom(
                                    name: name,
                                    participantIds: userIds,
                                    groupImage: groupImage,
                                  );
                                  // Show success/failure message if needed
                                });
                                _toggle();
                              },
                              showDivider: true,
                            ),
                          ),
                          Expanded(
                            child: _buildMenuItem(
                              icon: "assets/add friend.png",
                              label: '친구 추가',
                              onTap: () async {
                                await showAddFriendDialog(context, (
                                  userId,
                                ) async {
                                  // Call your FriendsService.addFriend here
                                  await FriendsService().addFriend(userId);
                                  // Show success/failure message if needed
                                });
                                _toggle();
                              },
                              showDivider: true,
                            ),
                          ),
                          Expanded(
                            child: _buildMenuItem(
                              icon: "assets/block user.png",
                              label: '차단 친구',
                              onTap: () async {
                                await showBlockUserDialog(context, (
                                  userId,
                                ) async {
                                  // Implement your block logic here
                                  await FriendsService().blockFriend(userId);
                                  // Show success/failure message if needed
                                });
                                _toggle();
                              },
                              showDivider: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          // Main FAB
          FloatingActionButton(
            onPressed: _toggle,
            backgroundColor: Colors.black,
            shape: const CircleBorder(),
            child: AnimatedRotation(
              turns: _isExpanded ? 0.125 : 0,
              duration: const Duration(milliseconds: 300),
              child: ImageIcon(
                AssetImage("assets/imageedit_2_3487749186.png"),
                size: 60.sp,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Show dialog to block a user by user ID or name
  Future<void> showBlockUserDialog(
    BuildContext context,
    void Function(String userId) onBlock,
  ) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('차단 친구'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: '유저 ID 또는 이름'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  onBlock(controller.text.trim());
                  Navigator.pop(context);
                },
                child: const Text('차단'),
              ),
            ],
          ),
    );
  }

  // Show dialog to add a friend by user ID or name
  Future<void> showAddFriendDialog(
    BuildContext context,
    void Function(String userId) onAdd,
  ) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('친구 추가'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: '유저 ID 또는 이름'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () {
                  onAdd(controller.text.trim());
                  Navigator.pop(context);
                },
                child: const Text('추가'),
              ),
            ],
          ),
    );
  }

  Future<void> showCreateGroupDialog(
    BuildContext context,
    void Function(String name, List<String> userIds, String? groupImageUrl)
    onCreate,
  ) async {
    final nameController = TextEditingController();
    List<String> selectedUserIds = [];
    String? groupImagePath;

    final friends = await FriendsService().getFriendsStream().first;

    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text('그룹 만들기'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Group image picker
                        Flexible(
                          child: GestureDetector(
                            onTap: () async {
                              groupImagePath =
                                  await uploadImageToFirebaseStorage();
                              setState(() {});
                            },
                            child: CircleAvatar(
                              radius: 36,
                              backgroundColor: Colors.grey[300],
                              backgroundImage:
                                  groupImagePath != null
                                      ? NetworkImage(groupImagePath!)
                                      : null,
                              child:
                                  groupImagePath == null
                                      ? const Icon(
                                        Icons.camera_alt,
                                        size: 32,
                                        color: Colors.black54,
                                      )
                                      : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Flexible(
                          child: TextField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: '그룹 이름',
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text('친구 선택'),
                        Flexible(
                          child: SizedBox(
                            height: 180,
                            child: ListView(
                              children:
                                  friends.map((user) {
                                    return CheckboxListTile(
                                      value: selectedUserIds.contains(
                                        user.userId,
                                      ),
                                      title: Row(
                                        children: [
                                          Flexible(
                                            child: CircleAvatar(
                                              backgroundImage:
                                                  user.url != null &&
                                                          user.url.isNotEmpty
                                                      ? NetworkImage(user.url)
                                                      : null,
                                              child:
                                                  (user.url.isEmpty)
                                                      ? Text(
                                                        user.name.isNotEmpty
                                                            ? user.name[0]
                                                            : '?',
                                                      )
                                                      : null,
                                            ),
                                          ),
                                          SizedBox(width: 10.w),
                                          Flexible(child: Text(user.name)),
                                        ],
                                      ),
                                      onChanged: (checked) {
                                        setState(() {
                                          if (checked == true) {
                                            selectedUserIds.add(user.userId);
                                          } else {
                                            selectedUserIds.remove(user.userId);
                                          }
                                        });
                                      },
                                    );
                                  }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('취소'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        onCreate(
                          nameController.text,
                          selectedUserIds,
                          groupImagePath,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('생성'),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _buildMenuItem({
    required String icon,
    required String label,
    required VoidCallback onTap,
    required bool showDivider,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Image.asset(
                    icon,
                    width: 30.sp,
                    height: 30.sp,
                    cacheWidth: 40, // Limits memory usage (2x display size)
                    cacheHeight: 40,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 16), // Extra padding on the right
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.white,
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}
