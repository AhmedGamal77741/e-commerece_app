// screens/friends_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecommerece_app/features/auth/domain/auth_controller.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/chat/domain/friends_controller.dart';
import 'package:ecommerece_app/features/chat/services/contacts_service.dart';
import '../widgets/friends/friends_my_profile.dart';
import '../widgets/friends/friends_section_header.dart';
import '../widgets/friends/friends_search_results.dart';
import '../widgets/friends/friends_list_item.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  final String searchQuery;
  const FriendsScreen({super.key, this.searchQuery = ''});
  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final ContactService _contactService = ContactService();

  bool editMode = false;
  Set<String> selectedChatIds = {};

  MyUser? _currentUser;
  bool _isLoadingUser = true;
  Map<String, String> _latestAliases = {};
  Map<String, String> _contactNicknameMap = {};

  // ── Expansion state ──────────────────────────────────────────────────────
  bool _subscribedExpanded = true;
  bool _friendsExpanded = true;

  // ── Computed search query ────────────────────────────────────────────────
  String get _effectiveQuery => widget.searchQuery;
  bool get _isSearchActive => _effectiveQuery.isNotEmpty;

  // ─── Hidden user IDs stream ───────────────────────────────────────────────
  Stream<Set<String>> _getHiddenIdsStream() {
    return ref.read(friendsControllerProvider.notifier).getHiddenIdsStream();
  }

  // ─── Alias map stream ─────────────────────────────────────────────────────
  Stream<Map<String, String>> _getAliasesStream() {
    return ref.read(friendsControllerProvider.notifier).getAliasesStream();
  }

  // ─── Following IDs stream ─────────────────────────────────────────────────
  Stream<Set<String>> _getFollowingIdsStream() {
    return ref.read(friendsControllerProvider.notifier).getFollowingIdsStream();
  }

  late final Stream<Set<String>> _followingIdsStreamInstance;
  late final Stream<Set<String>> _hiddenIdsStreamInstance;
  late final Stream<Map<String, String>> _aliasesStreamInstance;
  late final Stream<List<MyUser>> _friendsStreamInstance;

  void toggleEditMode() {
    setState(() {
      editMode = !editMode;
      if (!editMode) selectedChatIds.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    _followingIdsStreamInstance = _getFollowingIdsStream();
    _hiddenIdsStreamInstance = _getHiddenIdsStream();
    _aliasesStreamInstance = _getAliasesStream();
    _friendsStreamInstance = ref.read(friendsControllerProvider.notifier).getFriendsStream();
    _loadCurrentUser();
    _loadContactNicknameMap();
    _syncContactsOnEnter();
  }

  Future<void> _loadContactNicknameMap() async {
    final map = await _contactService.loadContactNameMap();
    if (mounted) {
      setState(() {
        _contactNicknameMap = map;
      });
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userStream = ref.read(currentUserProvider.future);
      final user = await userStream;
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

  static DateTime? _lastSyncTime;

  Future<void> _syncContactsOnEnter() async {
    final now = DateTime.now();
    if (_lastSyncTime != null &&
        now.difference(_lastSyncTime!) < const Duration(minutes: 5)) {
      return;
    }
    _lastSyncTime = now;

    try {
      await _contactService.syncAndAddFriendsFromContacts();
      await _loadContactNicknameMap();
    } catch (e) {
      debugPrint('Contact sync error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      top: false,
      child: StreamBuilder<Set<String>>(
        stream: _followingIdsStreamInstance,
        builder: (context, followingSnapshot) {
          final followingIds = followingSnapshot.data ?? {};

          return StreamBuilder<Set<String>>(
            stream: _hiddenIdsStreamInstance,
            builder: (context, hiddenSnapshot) {
              final hiddenIds = hiddenSnapshot.data ?? {};

              return StreamBuilder<Map<String, String>>(
                stream: _aliasesStreamInstance,
                builder: (context, aliasSnapshot) {
                  final aliases = aliasSnapshot.data ?? {};
                  _latestAliases = aliases;

                  return StreamBuilder<List<MyUser>>(
                    stream: _friendsStreamInstance,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox.shrink();
                      }

                      final allUsers = snapshot.data ?? [];
                      final allFriends =
                          allUsers
                              .where(
                                (u) =>
                                    u.type == 'user' &&
                                    !hiddenIds.contains(u.userId),
                              )
                              .toList();

                      final subscribed =
                          allFriends
                              .where((u) => followingIds.contains(u.userId))
                              .toList();

                      final friends = allFriends;

                      if (_isSearchActive) {
                        return FriendsSearchResults(
                          allFriends: allFriends,
                          aliases: aliases,
                          effectiveQuery: _effectiveQuery,
                          contactNicknameMap: _contactNicknameMap,
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          FriendsMyProfile(
                            isLoadingUser: _isLoadingUser,
                            currentUser: _currentUser,
                            aliases: _latestAliases,
                            onUpdateUser: (u) {
                              if (mounted) setState(() => _currentUser = u);
                            },
                          ),

                          // ── 내가 구독한 친구 ──────────────────
                          FriendsSectionHeader(
                            label: '서로 구독 친구',
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
                                                (f) => FriendsListItem(
                                                  friend: f,
                                                  aliases: aliases,
                                                  contactName:
                                                      _contactNicknameMap[f
                                                          .userId],
                                                  selectedChatIds:
                                                      selectedChatIds,
                                                  onCheckboxChanged: (
                                                    id,
                                                    checked,
                                                  ) {
                                                    setState(() {
                                                      if (checked) {
                                                        selectedChatIds.add(id);
                                                      } else {
                                                        selectedChatIds.remove(
                                                          id,
                                                        );
                                                      }
                                                    });
                                                  },
                                                ),
                                              )
                                              .toList(),
                                    ),
                            secondChild: const SizedBox.shrink(),
                          ),

                          // ── 친구 ──────────────────────────────
                          FriendsSectionHeader(
                            label: '친구',
                            count: friends.length,
                            expanded: _friendsExpanded,
                            onTap:
                                () => setState(
                                  () => _friendsExpanded = !_friendsExpanded,
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
                                        (friend) => FriendsListItem(
                                          friend: friend,
                                          showCheckbox: editMode,
                                          aliases: aliases,
                                          contactName:
                                              _contactNicknameMap[friend
                                                  .userId],
                                          selectedChatIds: selectedChatIds,
                                          onCheckboxChanged: (id, checked) {
                                            setState(() {
                                              if (checked) {
                                                selectedChatIds.add(id);
                                              } else {
                                                selectedChatIds.remove(id);
                                              }
                                            });
                                          },
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
      ),
    );
  }
}
