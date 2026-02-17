// screens/friends_screen.dart
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/auth/signup/data/signup_functions.dart';
import 'package:ecommerece_app/features/chat/services/chat_service.dart';
import 'package:ecommerece_app/features/chat/services/contacts_service.dart';
import 'package:ecommerece_app/features/chat/ui/chat_room_screen.dart';
import 'package:ecommerece_app/features/chat/services/friends_service.dart';
import 'package:ecommerece_app/features/chat/services/favorites_service.dart';
import 'package:ecommerece_app/features/home/data/home_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FriendsScreen extends StatefulWidget {
  final String searchQuery;
  const FriendsScreen({super.key, this.searchQuery = ''});
  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with TickerProviderStateMixin {
  final FriendsService _friendsService = FriendsService();
  final ContactService _contactService = ContactService();
  final ChatService _chatService = ChatService();
  final FirebaseUserRepo _userRepo = FirebaseUserRepo();
  final FavoritesService _favoritesService = FavoritesService();

  bool _isSyncing = false;
  bool editMode = false;
  Set<String> selectedChatIds = {};

  MyUser? _currentUser;
  bool _isLoadingUser = true;

  // ── Expansion state ──────────────────────────────────────────────────────
  bool _favoritesExpanded = true;
  bool _subscribedExpanded = true;
  bool _friendsExpanded = true;
  bool _brandsExpanded = true;

  // ── Computed search query ────────────────────────────────────────────────
  String get _effectiveQuery => widget.searchQuery;
  bool get _isSearchActive => _effectiveQuery.isNotEmpty;

  // ─── Favorites order stream ───────────────────────────────────────────────
  Stream<Map<String, int>> _getFavoritesOrderStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value({});
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) {
          if (!snap.exists) return <String, int>{};
          final data = snap.data();
          final raw = data?['favoritesOrder'];
          if (raw == null) return <String, int>{};
          return Map<String, int>.from(raw as Map);
        });
  }

  // ─── FIX 1: Added missing _getFollowingIdsStream() ───────────────────────
  Stream<Set<String>> _getFollowingIdsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value({});
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) {
          if (!snap.exists) return <String>{};
          final data = snap.data();
          final raw = data?['following'];
          if (raw == null) return <String>{};
          return Set<String>.from(raw as List);
        });
  }

  void toggleEditMode() {
    setState(() {
      editMode = !editMode;
      if (!editMode) selectedChatIds.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _syncContactsOnEnter();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _userRepo.user.first;
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingUser = false);
      debugPrint('Error loading current user: $e');
    }
  }

  Future<void> _syncContactsOnEnter() async {
    setState(() => _isSyncing = true);
    try {
      _contactService.syncAndAddFriendsFromContacts();
    } catch (e) {
      debugPrint('Contact sync error: $e');
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  // ─── Multi-field user search ──────────────────────────────────────────────

  Future<List<MyUser>> _searchUsersByAny(String query) async {
    if (query.trim().isEmpty) return [];
    final q = query.trim();
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final fs = FirebaseFirestore.instance;
    final currentDoc = await fs.collection('users').doc(currentUid).get();
    final currentUser = MyUser.fromDocument(currentDoc.data()!);
    final friendIds = currentUser.friends;

    Future<List<MyUser>> runQuery(String field, String value) async {
      final snap =
          await fs
              .collection('users')
              .where(field, isGreaterThanOrEqualTo: value)
              .where(field, isLessThan: '${value}z')
              .limit(20)
              .get();
      return snap.docs
          .map((d) => MyUser.fromDocument(d.data()))
          .where((u) => u.userId != currentUid && !friendIds.contains(u.userId))
          .toList();
    }

    final results = await Future.wait([
      runQuery('name', q),
      runQuery('email', q.toLowerCase()),
      runQuery('phoneNumber', q),
    ]);

    final seen = <String>{};
    final merged = <MyUser>[];
    for (final list in results) {
      for (final user in list) {
        if (seen.add(user.userId)) merged.add(user);
      }
    }
    return merged;
  }

  // ─── Bio edit dialog ─────────────────────────────────────────────────────

  void _showBioEditDialog() {
    final bioController = TextEditingController(text: _currentUser?.bio ?? '');
    showDialog(
      context: context,
      builder:
          (dialogContext) => Dialog(
            backgroundColor: Colors.white,
            insetPadding: EdgeInsets.symmetric(
              horizontal: 20.w,
              vertical: 80.h,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 20.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '상태 메시지',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  TextField(
                    controller: bioController,
                    maxLength: 60,
                    autofocus: true,
                    style: TextStyle(fontSize: 14.sp, color: Colors.black),
                    decoration: InputDecoration(
                      hintText: '소개를 입력하세요',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14.sp,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      counterStyle: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(
                          '취소',
                          style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 8.h,
                          ),
                        ),
                        onPressed: () async {
                          final newBio = bioController.text.trim();
                          Navigator.pop(dialogContext);
                          if (_currentUser == null) return;
                          final updatedUser = MyUser(
                            userId: _currentUser!.userId,
                            email: _currentUser!.email,
                            name: _currentUser!.name,
                            url: _currentUser!.url,
                            isSub: _currentUser!.isSub,
                            defaultAddressId: _currentUser!.defaultAddressId,
                            blocked: _currentUser!.blocked,
                            payerId: _currentUser!.payerId,
                            isOnline: _currentUser!.isOnline,
                            lastSeen: _currentUser!.lastSeen,
                            chatRooms: _currentUser!.chatRooms,
                            friends: _currentUser!.friends,
                            friendRequestsSent:
                                _currentUser!.friendRequestsSent,
                            friendRequestsReceived:
                                _currentUser!.friendRequestsReceived,
                            bio: newBio,
                            phoneNumber: _currentUser!.phoneNumber,
                          );
                          try {
                            await _userRepo.updateUser(updatedUser, "");
                            if (mounted)
                              setState(() => _currentUser = updatedUser);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('업데이트 실패: ${e.toString()}'),
                                ),
                              );
                            }
                          }
                        },
                        child: Text(
                          '변경',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // ─── Add friend dialog ────────────────────────────────────────────────────

  void _showAddFriendDialog() {
    final controller = TextEditingController();
    List<MyUser> results = [];
    bool isSearching = false;
    String? feedbackMessage;
    bool feedbackIsError = false;

    showDialog(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder: (ctx, setDialogState) {
              Future<void> runSearch(String query) async {
                if (query.trim().isEmpty) {
                  setDialogState(() {
                    results = [];
                    isSearching = false;
                  });
                  return;
                }
                setDialogState(() => isSearching = true);
                final found = await _searchUsersByAny(query.trim());
                setDialogState(() {
                  results = found;
                  isSearching = false;
                });
              }

              Future<void> addFriend(MyUser user) async {
                setDialogState(() => feedbackMessage = null);
                final success = await _friendsService.addFriend(user.name);
                setDialogState(() {
                  if (success) {
                    feedbackMessage = '${user.name}님과 친구가 되었습니다!';
                    feedbackIsError = false;
                    results.removeWhere((u) => u.userId == user.userId);
                  } else {
                    feedbackMessage = '친구 추가에 실패했습니다.';
                    feedbackIsError = true;
                  }
                });
              }

              return Dialog(
                backgroundColor: Colors.white,
                insetPadding: EdgeInsets.only(
                  left: 16.w,
                  right: 16.w,
                  top: 60.h,
                  bottom: 20.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '친구 추가',
                            style: TextStyle(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 14.h),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.r),
                              color: Colors.grey[300],
                            ),
                            child: TextField(
                              controller: controller,
                              autofocus: true,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.black,
                              ),
                              decoration: InputDecoration(
                                hintText: '이름, 전화번호, 이메일',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14.sp,
                                ),
                                suffixIcon:
                                    isSearching
                                        ? Padding(
                                          padding: EdgeInsets.all(12.r),
                                          child: SizedBox(
                                            width: 16.w,
                                            height: 16.w,
                                            child:
                                                const CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.black,
                                                ),
                                          ),
                                        )
                                        : Icon(
                                          Icons.search,
                                          size: 22.sp,
                                          color: Colors.black,
                                        ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 14.w,
                                  vertical: 12.h,
                                ),
                              ),
                              onChanged: runSearch,
                            ),
                          ),
                          if (feedbackMessage != null) ...[
                            SizedBox(height: 10.h),
                            Row(
                              children: [
                                Icon(
                                  feedbackIsError
                                      ? Icons.error_outline
                                      : Icons.check_circle_outline,
                                  size: 14.sp,
                                  color:
                                      feedbackIsError
                                          ? Colors.red
                                          : Colors.green[700],
                                ),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: Text(
                                    feedbackMessage!,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color:
                                          feedbackIsError
                                              ? Colors.red
                                              : Colors.green[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          SizedBox(height: 10.h),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: 260.h),
                          child:
                              results.isNotEmpty
                                  ? Column(
                                    children: List.generate(results.length, (
                                      index,
                                    ) {
                                      final user = results[index];
                                      return Column(
                                        children: [
                                          InkWell(
                                            borderRadius: BorderRadius.circular(
                                              8.r,
                                            ),
                                            onTap: () => addFriend(user),
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                vertical: 12.h,
                                                horizontal: 4.w,
                                              ),
                                              child: Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 22.r,
                                                    // FIX 3: Guard empty URL
                                                    backgroundImage:
                                                        user.url.isNotEmpty
                                                            ? NetworkImage(
                                                              user.url,
                                                            )
                                                            : null,
                                                    backgroundColor:
                                                        Colors.grey[200],
                                                    child:
                                                        user.url.isEmpty
                                                            ? Icon(
                                                              Icons.person,
                                                              size: 22.sp,
                                                              color:
                                                                  Colors.grey,
                                                            )
                                                            : null,
                                                  ),
                                                  SizedBox(width: 12.w),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          user.name,
                                                          style: TextStyle(
                                                            fontSize: 14.sp,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                        if (user.bio != null &&
                                                            user
                                                                .bio!
                                                                .isNotEmpty)
                                                          Text(
                                                            user.bio!,
                                                            style: TextStyle(
                                                              fontSize: 12.sp,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.person_add_outlined,
                                                    size: 20.sp,
                                                    color: Colors.grey[400],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (index < results.length - 1)
                                            Divider(
                                              height: 1,
                                              color: Colors.grey[100],
                                            ),
                                        ],
                                      );
                                    }),
                                  )
                                  : SizedBox(
                                    height: 260.h,
                                    child: Center(
                                      child: Text(
                                        controller.text.isNotEmpty &&
                                                !isSearching
                                            ? '검색 결과가 없습니다'
                                            : '이름, 전화번호 또는 이메일로\n친구를 검색해보세요',
                                        style: TextStyle(
                                          fontSize: 13.sp,
                                          color: Colors.grey,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 16.h),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(
                            '닫기',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  // ─── Create group dialog ──────────────────────────────────────────────────

  Future<void> _showCreateGroupDialog() async {
    final nameController = TextEditingController();
    final searchCtrl = TextEditingController();
    List<String> selectedUserIds = [];
    String? groupImagePath;
    String groupSearch = '';
    final friends = await _friendsService.getFriendsStream().first;

    await showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setDialogState) {
              final filteredFriends =
                  groupSearch.isEmpty
                      ? friends
                      : friends
                          .where(
                            (u) => u.name.toLowerCase().contains(
                              groupSearch.toLowerCase(),
                            ),
                          )
                          .toList();
              final selectedFriends =
                  friends
                      .where((u) => selectedUserIds.contains(u.userId))
                      .toList();

              return Dialog(
                backgroundColor: Colors.white,
                insetPadding: EdgeInsets.only(
                  left: 16.w,
                  right: 16.w,
                  top: 60.h,
                  bottom: 20.h,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 24.h, bottom: 12.h),
                      child: Text(
                        '채팅방 만들기',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () async {
                                groupImagePath =
                                    await uploadImageToFirebaseStorageHome();
                                setDialogState(() {});
                              },
                              child: CircleAvatar(
                                radius: 40.r,
                                backgroundColor: Colors.grey[200],
                                backgroundImage:
                                    groupImagePath != null
                                        ? NetworkImage(groupImagePath!)
                                        : null,
                                child:
                                    groupImagePath == null
                                        ? Icon(
                                          Icons.image_outlined,
                                          size: 32.sp,
                                          color: Colors.grey[400],
                                        )
                                        : null,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 40.w),
                              child: TextField(
                                controller: nameController,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  hintText: '채팅방 이름',
                                  hintStyle: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 14.sp,
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  focusedBorder: const UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black),
                                  ),
                                  isDense: true,
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            if (selectedFriends.isNotEmpty) ...[
                              SizedBox(
                                height: 72.h,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  physics: const ClampingScrollPhysics(),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                  ),
                                  itemCount: selectedFriends.length,
                                  itemBuilder: (context, idx) {
                                    final user = selectedFriends[idx];
                                    return Padding(
                                      padding: EdgeInsets.only(right: 12.w),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              CircleAvatar(
                                                radius: 22.r,
                                                // FIX 3: Guard empty URL
                                                backgroundImage:
                                                    user.url.isNotEmpty
                                                        ? NetworkImage(user.url)
                                                        : null,
                                                backgroundColor:
                                                    Colors.grey[200],
                                                child:
                                                    user.url.isEmpty
                                                        ? Text(
                                                          user.name.isNotEmpty
                                                              ? user.name[0]
                                                              : '?',
                                                          style: TextStyle(
                                                            fontSize: 14.sp,
                                                            color: Colors.black,
                                                          ),
                                                        )
                                                        : null,
                                              ),
                                              Positioned(
                                                top: -4,
                                                right: -4,
                                                child: GestureDetector(
                                                  onTap:
                                                      () => setDialogState(
                                                        () => selectedUserIds
                                                            .remove(
                                                              user.userId,
                                                            ),
                                                      ),
                                                  child: Container(
                                                    width: 16.w,
                                                    height: 16.w,
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Colors.black,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    child: Icon(
                                                      Icons.close,
                                                      size: 10.sp,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            user.name,
                                            style: TextStyle(
                                              fontSize: 10.sp,
                                              color: Colors.black,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 8.h),
                            ],
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Container(
                                height: 40.h,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: TextField(
                                  controller: searchCtrl,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.black,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 10.h,
                                    ),
                                    suffixIcon: Icon(
                                      Icons.search,
                                      size: 20.sp,
                                      color: Colors.black,
                                    ),
                                    isDense: true,
                                  ),
                                  onChanged:
                                      (val) => setDialogState(
                                        () => groupSearch = val,
                                      ),
                                ),
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Padding(
                              padding: EdgeInsets.only(left: 16.w, bottom: 6.h),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '즐겨찾기',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            if (filteredFriends.isEmpty)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.h),
                                child: Center(
                                  child: Text(
                                    '친구가 없습니다',
                                    style: TextStyle(
                                      fontSize: 13.sp,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Column(
                                children:
                                    filteredFriends.map((user) {
                                      final isSelected = selectedUserIds
                                          .contains(user.userId);
                                      return InkWell(
                                        onTap:
                                            () => setDialogState(() {
                                              if (isSelected)
                                                selectedUserIds.remove(
                                                  user.userId,
                                                );
                                              else
                                                selectedUserIds.add(
                                                  user.userId,
                                                );
                                            }),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16.w,
                                            vertical: 8.h,
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color:
                                                        isSelected
                                                            ? Colors.black
                                                            : Colors
                                                                .transparent,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: CircleAvatar(
                                                  radius: 22.r,
                                                  // FIX 3: Guard empty URL
                                                  backgroundImage:
                                                      user.url.isNotEmpty
                                                          ? NetworkImage(
                                                            user.url,
                                                          )
                                                          : null,
                                                  backgroundColor:
                                                      Colors.grey[200],
                                                  child:
                                                      user.url.isEmpty
                                                          ? Text(
                                                            user.name.isNotEmpty
                                                                ? user.name[0]
                                                                : '?',
                                                            style: TextStyle(
                                                              fontSize: 14.sp,
                                                              color:
                                                                  Colors.black,
                                                            ),
                                                          )
                                                          : null,
                                                ),
                                              ),
                                              SizedBox(width: 12.w),
                                              Expanded(
                                                child: Text(
                                                  user.name,
                                                  style: TextStyle(
                                                    fontSize: 15.sp,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ),
                                              AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 150,
                                                ),
                                                width: 22.w,
                                                height: 22.w,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color:
                                                      isSelected
                                                          ? Colors.black
                                                          : Colors.transparent,
                                                  border: Border.all(
                                                    color:
                                                        isSelected
                                                            ? Colors.black
                                                            : Colors.grey[400]!,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child:
                                                    isSelected
                                                        ? Icon(
                                                          Icons.check,
                                                          size: 13.sp,
                                                          color: Colors.white,
                                                        )
                                                        : null,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            SizedBox(height: 8.h),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.grey[100]!, width: 1),
                        ),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(
                              '취소',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: 8.w),
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.w,
                                vertical: 10.h,
                              ),
                            ),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await _chatService.createGroupChatRoom(
                                name: nameController.text,
                                participantIds: selectedUserIds,
                                groupImage: groupImagePath,
                              );
                            },
                            child: Text(
                              '생성',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  // ─── Current user card ────────────────────────────────────────────────────

  Widget _buildCurrentUserCard() {
    if (_isLoadingUser) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_currentUser == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _showBioEditDialog,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28.r,
                  // FIX 3: Guard empty URL
                  backgroundImage:
                      _currentUser!.url.isNotEmpty
                          ? NetworkImage(_currentUser!.url)
                          : null,
                  backgroundColor: Colors.grey[200],
                  child:
                      _currentUser!.url.isEmpty
                          ? Icon(Icons.person, color: Colors.grey, size: 28.sp)
                          : null,
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentUser!.name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        (_currentUser!.bio != null &&
                                _currentUser!.bio!.isNotEmpty)
                            ? _currentUser!.bio!
                            : '상태 메시지',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color:
                              (_currentUser!.bio != null &&
                                      _currentUser!.bio!.isNotEmpty)
                                  ? Colors.grey[600]
                                  : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.chat_bubble_outline,
                label: '채팅방 만들기',
                onTap: _showCreateGroupDialog,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _buildActionButton(
                icon: Icons.person_add_outlined,
                label: '친구 추가',
                onTap: _showAddFriendDialog,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        color: Colors.transparent,
        child: Row(
          children: [
            Icon(icon, size: 28.sp, color: Colors.black87),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section header ───────────────────────────────────────────────────────

  Widget _buildSectionHeader({
    required String label,
    required int count,
    required bool expanded,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Row(
          children: [
            Text(
              '$label $count',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            AnimatedRotation(
              turns: expanded ? 0 : -0.25,
              duration: const Duration(milliseconds: 200),
              child: const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Search results view ──────────────────────────────────────────────────

  Widget _buildSearchResults(
    List<MyUser> allFriends,
    List<MyUser> allBrands,
    List<String> favoriteIds,
  ) {
    final query = _effectiveQuery.toLowerCase();
    final matchingFriends =
        allFriends.where((u) => u.name.toLowerCase().contains(query)).toList();
    final matchingBrands =
        allBrands.where((u) => u.name.toLowerCase().contains(query)).toList();

    if (matchingFriends.isEmpty && matchingBrands.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.only(top: 60.h),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 48.sp, color: Colors.grey[300]),
              SizedBox(height: 12.h),
              Text(
                '검색 결과가 없습니다',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (matchingFriends.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
            child: Text(
              '친구 ${matchingFriends.length}',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ...matchingFriends.map(
            (f) => _buildFriendItem(friend: f, favoriteIds: favoriteIds),
          ),
        ],
        if (matchingBrands.isNotEmpty) ...[
          Padding(
            padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
            child: Text(
              '브랜드 ${matchingBrands.length}',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ...matchingBrands.map(
            (b) => _buildFriendItem(
              friend: b,
              isBrand: true,
              favoriteIds: favoriteIds,
            ),
          ),
        ],
        SizedBox(height: 40.h),
      ],
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // FIX 2: Corrected StreamBuilder nesting and bracket structure
    return SafeArea(
      top: false,
      child: StreamBuilder<List<String>>(
        // Stream 1: favorite IDs
        stream: _favoritesService.getFavoriteIdsStream(),
        builder: (context, favSnapshot) {
          final favoriteIds = favSnapshot.data ?? [];

          return StreamBuilder<Map<String, int>>(
            // Stream 2: favorites order map
            stream: _getFavoritesOrderStream(),
            builder: (context, orderSnapshot) {
              final orderMap = orderSnapshot.data ?? {};

              return StreamBuilder<Set<String>>(
                // Stream 3: following IDs
                stream: _getFollowingIdsStream(),
                builder: (context, followingSnapshot) {
                  final followingIds = followingSnapshot.data ?? {};

                  return StreamBuilder<List<MyUser>>(
                    // Stream 4: friends list
                    stream: _friendsService.getFriendsStream(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || _isSyncing) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final allUsers = snapshot.data ?? [];
                      final allFriends =
                          allUsers.where((u) => u.type == 'user').toList();

                      // Favorites: friends that are starred, sorted by order
                      final favorites =
                          allFriends
                              .where((u) => favoriteIds.contains(u.userId))
                              .toList();
                      favorites.sort((a, b) {
                        final aOrder = orderMap[a.userId] ?? 999999;
                        final bOrder = orderMap[b.userId] ?? 999999;
                        return aOrder.compareTo(bOrder);
                      });

                      // Subscribed: friends that the current user follows
                      final subscribed =
                          allFriends
                              .where((u) => followingIds.contains(u.userId))
                              .toList();

                      // Friends: all friends
                      final friends = allFriends;

                      return StreamBuilder(
                        // Stream 5: brands
                        stream: _friendsService.getBrandsStream(),
                        builder: (context, brandSnapshot) {
                          final brands =
                              (brandSnapshot.data ?? []) as List<MyUser>;

                          if (_isSearchActive) {
                            return _buildSearchResults(
                              allFriends,
                              brands,
                              favoriteIds,
                            );
                          }

                          return ListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            children: [
                              _buildCurrentUserCard(),

                              // ── 즐겨찾기 ──────────────────────────────
                              _buildSectionHeader(
                                label: '즐겨찾기',
                                count: favorites.length,
                                expanded: _favoritesExpanded,
                                onTap:
                                    () => setState(
                                      () =>
                                          _favoritesExpanded =
                                              !_favoritesExpanded,
                                    ),
                              ),
                              AnimatedCrossFade(
                                duration: const Duration(milliseconds: 200),
                                crossFadeState:
                                    _favoritesExpanded
                                        ? CrossFadeState.showFirst
                                        : CrossFadeState.showSecond,
                                firstChild:
                                    favorites.isEmpty
                                        ? Padding(
                                          padding: EdgeInsets.only(
                                            bottom: 12.h,
                                            left: 4.w,
                                          ),
                                          child: Text(
                                            '즐겨찾기한 친구가 없습니다',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        )
                                        : Column(
                                          children:
                                              favorites
                                                  .map(
                                                    (f) => _buildFriendItem(
                                                      friend: f,
                                                      favoriteIds: favoriteIds,
                                                    ),
                                                  )
                                                  .toList(),
                                        ),
                                secondChild: const SizedBox.shrink(),
                              ),

                              // ── 내가 구독한 친구 ───────────────────────
                              _buildSectionHeader(
                                label: '내가 구독한 친구',
                                count: subscribed.length,
                                expanded: _subscribedExpanded,
                                onTap:
                                    () => setState(
                                      () =>
                                          _subscribedExpanded =
                                              !_subscribedExpanded,
                                    ),
                              ),
                              AnimatedCrossFade(
                                duration: const Duration(milliseconds: 200),
                                crossFadeState:
                                    _subscribedExpanded
                                        ? CrossFadeState.showFirst
                                        : CrossFadeState.showSecond,
                                firstChild:
                                    subscribed.isEmpty
                                        ? Padding(
                                          padding: EdgeInsets.only(
                                            bottom: 12.h,
                                            left: 4.w,
                                          ),
                                          child: Text(
                                            '구독한 친구가 없습니다',
                                            style: TextStyle(
                                              fontSize: 12.sp,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        )
                                        : Column(
                                          children:
                                              subscribed
                                                  .map(
                                                    (f) => _buildFriendItem(
                                                      friend: f,
                                                      favoriteIds: favoriteIds,
                                                    ),
                                                  )
                                                  .toList(),
                                        ),
                                secondChild: const SizedBox.shrink(),
                              ),

                              // ── 친구 ──────────────────────────────────
                              _buildSectionHeader(
                                label: '친구',
                                count: friends.length,
                                expanded: _friendsExpanded,
                                onTap:
                                    () => setState(
                                      () =>
                                          _friendsExpanded = !_friendsExpanded,
                                    ),
                              ),
                              AnimatedCrossFade(
                                duration: const Duration(milliseconds: 200),
                                crossFadeState:
                                    _friendsExpanded
                                        ? CrossFadeState.showFirst
                                        : CrossFadeState.showSecond,
                                firstChild: Column(
                                  children:
                                      friends
                                          .map(
                                            (friend) => _buildFriendItem(
                                              friend: friend,
                                              showCheckbox: editMode,
                                              favoriteIds: favoriteIds,
                                            ),
                                          )
                                          .toList(),
                                ),
                                secondChild: const SizedBox.shrink(),
                              ),

                              // ── 브랜드 ────────────────────────────────
                              _buildSectionHeader(
                                label: '브랜드',
                                count: brands.length,
                                expanded: _brandsExpanded,
                                onTap:
                                    () => setState(
                                      () => _brandsExpanded = !_brandsExpanded,
                                    ),
                              ),
                              AnimatedCrossFade(
                                duration: const Duration(milliseconds: 200),
                                crossFadeState:
                                    _brandsExpanded
                                        ? CrossFadeState.showFirst
                                        : CrossFadeState.showSecond,
                                firstChild: Column(
                                  children:
                                      brands
                                          .map(
                                            (b) => _buildFriendItem(
                                              friend: b,
                                              isBrand: true,
                                              showCheckbox: editMode,
                                              favoriteIds: favoriteIds,
                                            ),
                                          )
                                          .toList(),
                                ),
                                secondChild: const SizedBox.shrink(),
                              ),

                              SizedBox(height: 40.h),
                            ],
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
      ),
    );
  }

  // ─── Friend item ──────────────────────────────────────────────────────────

  Widget _buildFriendItem({
    required MyUser friend,
    required List<String> favoriteIds,
    bool showCheckbox = false,
    bool isBrand = false,
  }) {
    final GlobalKey itemKey = GlobalKey();
    final bool isFav = favoriteIds.contains(friend.userId);

    void showFriendMenu() {
      if (isBrand) return;
      final RenderBox box =
          itemKey.currentContext!.findRenderObject() as RenderBox;
      final Offset offset = box.localToGlobal(Offset.zero);
      final screenWidth = MediaQuery.of(context).size.width;
      const double popupWidth = 220;
      const double popupHeight = 360;

      double left = offset.dx + 55;
      double top = offset.dy - 60;
      final screenHeight = MediaQuery.of(context).size.height;

      if (left + popupWidth > screenWidth - 12) {
        left = screenWidth - popupWidth - 12;
      }
      if (top + popupHeight > screenHeight - 20) {
        top = offset.dy - popupHeight + 20;
      }
      if (top < 8) top = 8;

      showDialog(
        context: context,
        barrierColor: Colors.transparent,
        barrierDismissible: false,
        builder:
            (_) => Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(color: Colors.transparent),
                  ),
                ),
                Positioned(
                  left: left,
                  top: top,
                  width: popupWidth,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 20.h),
                          Text(
                            friend.name,
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Divider(
                            color: Colors.grey[200],
                            thickness: 1,
                            height: 1,
                          ),
                          _buildMenuOption(
                            label: isFav ? '즐겨찾기 해제' : '즐겨찾기 추가',
                            labelColor:
                                isFav ? Colors.amber[800] : Colors.black,
                            onTap: () async {
                              Navigator.pop(context);
                              if (isFav) {
                                await _favoritesService.removeFavorite(
                                  friend.userId,
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${friend.name}님을 즐겨찾기에서 제거했습니다',
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } else {
                                await _favoritesService.addFavorite(
                                  friend.userId,
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${friend.name}님을 즐겨찾기에 추가했습니다',
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            },
                          ),
                          _buildMenuOption(
                            label: '이름 변경',
                            onTap: () => Navigator.pop(context),
                          ),
                          _buildMenuOption(
                            label: '숨김',
                            onTap: () => Navigator.pop(context),
                          ),
                          _buildMenuOption(
                            label: '삭제',
                            onTap: () => Navigator.pop(context),
                          ),
                          _buildMenuOption(
                            label: '차단',
                            onTap: () => Navigator.pop(context),
                            isLast: true,
                          ),
                          SizedBox(height: 12.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      );
    }

    return Container(
      key: itemKey,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          try {
            final chatRoomId = await _chatService.createDirectChatRoom(
              friend.userId,
              isBrand,
            );
            if (chatRoomId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ChatScreen(
                        chatRoomId: chatRoomId,
                        chatRoomName: friend.name,
                      ),
                ),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        },
        onLongPress: showFriendMenu,
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // FIX 3: Guard empty URL in friend list items
                CircleAvatar(
                  radius: 25,
                  backgroundImage:
                      friend.url.isNotEmpty ? NetworkImage(friend.url) : null,
                  backgroundColor: Colors.grey[200],
                  child:
                      friend.url.isEmpty
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                ),
                if (isFav)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: Colors.amber,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _isSearchActive
                      ? _buildHighlightedName(friend.name, _effectiveQuery)
                      : Text(
                        friend.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                  if (friend.bio != null && friend.bio!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      friend.bio ?? '',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
            if (showCheckbox)
              StatefulBuilder(
                builder: (context, checkboxState) {
                  return Checkbox(
                    value: selectedChatIds.contains(friend.userId),
                    onChanged:
                        (checked) => checkboxState(() {
                          if (checked ?? false)
                            selectedChatIds.add(friend.userId);
                          else
                            selectedChatIds.remove(friend.userId);
                        }),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // ─── Highlighted name text (for search) ──────────────────────────────────

  Widget _buildHighlightedName(String name, String query) {
    final lowerName = name.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matchIndex = lowerName.indexOf(lowerQuery);

    if (matchIndex == -1) {
      return Text(
        name,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
        children: [
          if (matchIndex > 0) TextSpan(text: name.substring(0, matchIndex)),
          TextSpan(
            text: name.substring(matchIndex, matchIndex + query.length),
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (matchIndex + query.length < name.length)
            TextSpan(text: name.substring(matchIndex + query.length)),
        ],
      ),
    );
  }

  // ─── Menu option ──────────────────────────────────────────────────────────

  Widget _buildMenuOption({
    required String label,
    required VoidCallback onTap,
    Color? labelColor,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 14.h),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w400,
                  color: labelColor ?? Colors.black,
                ),
              ),
            ),
          ),
          if (!isLast)
            Divider(color: Colors.grey[200], thickness: 1, height: 1),
        ],
      ),
    );
  }
}
