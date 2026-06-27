// features/chat/ui/chats_navbar.dart
import 'package:ecommerece_app/core/theming/colors.dart';
import 'package:ecommerece_app/features/chat/ui/chat_room_screen.dart';
import 'package:ecommerece_app/features/chat/ui/direct_chats_screen.dart';
import 'package:ecommerece_app/features/chat/ui/edit_screen.dart';
import 'package:ecommerece_app/features/chat/ui/friends_screen.dart';
import 'package:ecommerece_app/features/chat/ui/group_chats_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/chat_controller.dart';

class ChatsNavbar extends ConsumerStatefulWidget {
  const ChatsNavbar({super.key});
  @override
  ConsumerState<ChatsNavbar> createState() => _ChatsNavbarState();
}

class _ChatsNavbarState extends ConsumerState<ChatsNavbar>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  int _selectedIndex = 1;
  bool _searchMode = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final PageController _pageController = PageController(initialPage: 1);

  final String supportUserId = 'JuxEfED9YSc2XyHRFgkPcNCFUSJ3';

  final List<Map<String, dynamic>> _tabs = [
    {'label': '친구'},
    {'label': '1:1 채팅'},
    {'label': '그룹채팅'},
  ];

  late final _directChatsScreen = DirectChatsScreen();
  late final _groupChatsScreen = GroupChatsScreen();

  Widget get _friendsScreen => FriendsScreen(searchQuery: _searchQuery);

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _enterSearchMode() {
    setState(() {
      _searchMode = true;
      _searchQuery = '';
      _searchController.clear();
    });
    Future.microtask(() => _searchFocus.requestFocus());
  }

  void _exitSearchMode() {
    setState(() {
      _searchMode = false;
      _searchQuery = '';
      _searchController.clear();
    });
    _searchFocus.unfocus();
  }

  List<Widget> get _widgetOptions => [
    _friendsScreen,
    _directChatsScreen,
    _groupChatsScreen,
  ];
  void _onPageChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  void _onSettingsTapped() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EditScreen(initialTab: _selectedIndex)),
    );
  }

  Future<void> _contactAdmin() async {
    try {
      final chatRoomId =
          await ref
              .read(chatControllerProvider.notifier)
              .createDirectChatRoomWithAdmin();
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  ChatScreen(chatRoomId: chatRoomId, chatRoomName: "Admin"),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
    }
  }

  /// Shown when no user is signed in
  Widget _buildSignInPrompt() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 72.sp,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 24.h),
                Text(
                  '채팅을 이용하려면\n로그인이 필요합니다',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  '로그인 후 친구들과 자유롭게 채팅하세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPill(int index) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          _tabs[index]['label'],
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildNormalPillRow() {
    final bool onFriendsTab = _selectedIndex == 0;
    final bool onDirectChatsTab = _selectedIndex == 1;

    return Row(
      key: const ValueKey('pills'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (int i = 0; i < _tabs.length; i++) ...[
                  _buildPill(i),
                  if (i < _tabs.length - 1) SizedBox(width: 8.w),
                ],
              ],
            ),
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child:
              onFriendsTab
                  ? IconButton(
                    onPressed: _enterSearchMode,
                    icon: CircleAvatar(
                      radius: 15.r,
                      backgroundColor: Colors.transparent,
                      backgroundImage: const AssetImage(
                        'assets/search_icon.png',
                      ),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 28.w,
                      minHeight: 28.h,
                    ),
                  )
                  : const SizedBox(width: 0),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child:
              onDirectChatsTab
                  ? IconButton(
                    onPressed: _contactAdmin,
                    icon: Icon(
                      Icons.contact_support_outlined,
                      color: const Color.fromARGB(255, 172, 171, 171),
                      size: 30.sp,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(
                      minWidth: 28.w,
                      minHeight: 28.h,
                    ),
                  )
                  : const SizedBox(width: 0),
        ),
        IconButton(
          onPressed: _onSettingsTapped,
          icon: CircleAvatar(
            radius: 15.r,
            backgroundColor: Colors.transparent,
            backgroundImage: const AssetImage('assets/settings.png'),
          ),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(minWidth: 28.w, minHeight: 28.h),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      key: const ValueKey('searchbar'),
      children: [
        GestureDetector(
          onTap: _exitSearchMode,
          child: Padding(
            padding: EdgeInsets.only(right: 10.w),
            child: Icon(Icons.arrow_back, size: 22.sp, color: Colors.black87),
          ),
        ),
        Expanded(
          child: Container(
            height: 36.h,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              style: TextStyle(fontSize: 14.sp, color: Colors.black),
              decoration: InputDecoration(
                hintText: '이름으로 검색',
                hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey[400]),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 14.w,
                  vertical: 8.h,
                ),
                isDense: true,
              ),
              onChanged:
                  (val) =>
                      setState(() => _searchQuery = val.toLowerCase().trim()),
            ),
          ),
        ),
        if (_searchQuery.isNotEmpty)
          GestureDetector(
            onTap: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
            child: Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: Icon(Icons.close, size: 20.sp, color: Colors.grey[600]),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(left: 8.w),
          child: Icon(Icons.search, size: 22.sp, color: Colors.grey[600]),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = FirebaseAuth.instance.currentUser;

    // ✅ No user signed in — show Korean sign-in prompt
    if (user == null) {
      return _buildSignInPrompt();
    }

    // Support/admin user — show direct chats only
    if (user.uid == supportUserId) {
      return Scaffold(body: DirectChatsScreen());
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              color: ColorsManager.primary,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder:
                    (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                child: _searchMode ? _buildSearchBar() : _buildNormalPillRow(),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: _widgetOptions,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
