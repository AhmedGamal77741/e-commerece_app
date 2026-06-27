import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ecommerece_app/features/auth/signup/data/models/user_model.dart';
import 'friends_list_item.dart';

class FriendsSearchResults extends StatelessWidget {
  final List<MyUser> allFriends;
  final Map<String, String> aliases;
  final String effectiveQuery;
  final Map<String, String> contactNicknameMap;

  const FriendsSearchResults({
    super.key,
    required this.allFriends,
    required this.aliases,
    required this.effectiveQuery,
    required this.contactNicknameMap,
  });

  @override
  Widget build(BuildContext context) {
    final query = effectiveQuery.toLowerCase();
    final matchingFriends = allFriends.where((u) {
      return u.name.toLowerCase().contains(query) ||
          (aliases[u.userId]?.toLowerCase().contains(query) ?? false);
    }).toList();

    if (matchingFriends.isEmpty) {
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
            (f) => FriendsListItem(
              friend: f,
              aliases: aliases,
              isSearchActive: true,
              effectiveQuery: effectiveQuery,
              contactName: contactNicknameMap[f.userId],
              selectedChatIds: const {},
              onCheckboxChanged: (id, checked) {},
            ),
          ),
        ],
        SizedBox(height: 40.h),
      ],
    );
  }
}
