// screens/friends_screen.dart
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'package:ecommerece_app/features/chat/services/chat_service.dart';
import 'package:ecommerece_app/features/chat/services/contacts_service.dart';
import 'package:ecommerece_app/features/friends/services/friends_service.dart';
import 'package:flutter/material.dart';

class FriendsScreen extends StatefulWidget {
  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with TickerProviderStateMixin {
  final FriendsService _friendsService = FriendsService();
  final ContactService _contactService = ContactService();
  final ChatService _chatService = ChatService();

  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    // Sync contacts when screen loads
    _syncContactsOnEnter();
  }

  Future<void> _syncContactsOnEnter() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final addedCount = await _contactService.syncAndAddFriendsFromContacts();
      if (addedCount > 0) {
        // Show a subtle notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$addedCount명의 친구가 연락처에서 자동으로 추가되었습니다'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Contact sync error: $e');
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: () {
              // Handle edit action
            },
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              /*               Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddFriendScreen()),
              ); */
            },
          ),
        ],
      ),
      body: StreamBuilder<List<MyUser>>(
        stream: _friendsService.getFriendsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              _isSyncing) {
            return const Center(child: CircularProgressIndicator());
          }

          final friends = snapshot.data ?? [];

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFavoriteSection(friends),
                    _buildBrandSection(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          /*           Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddFriendScreen()),
          ); */
        },
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildFavoriteSection(List<MyUser> friends) {
    // Take first few friends as favorites for demo
    final favoriteFriends = friends.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            '친구 ${friends.length}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ...favoriteFriends
            .map(
              (friend) => _buildFriendItem(friend: friend, showSubtitle: true),
            )
            .toList(),
        if (friends.length > 4) ...[
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE5E5E5)),
          const SizedBox(height: 16),
          ...friends
              .skip(4)
              .map(
                (friend) =>
                    _buildFriendItem(friend: friend, showSubtitle: true),
              )
              .toList(),
        ],
      ],
    );
  }

  Widget _buildBrandSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            '브랜드 152',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        _buildBrandItem(
          name: '팽이초콜릿',
          profileImage: null,
          backgroundColor: Colors.black,
          textColor: Colors.white,
        ),

        const SizedBox(height: 100), // Space for bottom navigation
      ],
    );
  }

  Widget _buildFriendItem({required MyUser friend, bool showSubtitle = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          try {
            final chatRoomId = await _chatService.createDirectChatRoom(
              friend.userId,
            );
            if (chatRoomId != null) {
              // Navigate to chat
              // You'll need to get the ChatRoomModel first
            }
          } catch (e) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        },
        child: Row(
          children: [
            CircleAvatar(radius: 25, backgroundImage: NetworkImage(friend.url)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  if (showSubtitle) ...[
                    const SizedBox(height: 2),
                    Text(
                      friend.isOnline ? '온라인' : '오프라인',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
            if (friend.isOnline)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandItem({
    required String name,
    String? subtitle,
    String? profileImage,
    Color backgroundColor = Colors.grey,
    Color textColor = Colors.white,
    bool hasGradient = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          // Handle brand tap
        },
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasGradient ? null : backgroundColor,
                gradient:
                    hasGradient
                        ? LinearGradient(
                          colors: [Colors.orange, Colors.pink],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                        : null,
              ),
              child:
                  profileImage != null
                      ? ClipOval(
                        child: Image.asset(
                          profileImage,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.business,
                              color: textColor,
                              size: 24,
                            );
                          },
                        ),
                      )
                      : Icon(Icons.business, color: textColor, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E5E5), width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildBottomNavItem(
            icon: Icons.chat_bubble_outline,
            label: '친구톡톡',
            isSelected: true,
          ),
          _buildBottomNavItem(
            icon: Icons.person_outline,
            label: '1:1 채팅',
            isSelected: false,
          ),
          _buildBottomNavItem(
            icon: Icons.group_outlined,
            label: '그룹채팅',
            isSelected: false,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 24, color: isSelected ? Colors.black : Colors.grey),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isSelected ? Colors.black : Colors.grey,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
