import 'package:ecommerece_app/features/chat/ui/direct_chats_screen.dart';
import 'package:ecommerece_app/features/chat/ui/friends_screen.dart';
import 'package:ecommerece_app/features/chat/ui/group_chats_screen.dart';
import 'package:ecommerece_app/features/chat/widgets/expandable_FAB.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatsNavbar extends StatefulWidget {
  const ChatsNavbar({super.key});

  @override
  State<ChatsNavbar> createState() => _ChatsNavbarState();
}

class _ChatsNavbarState extends State<ChatsNavbar> {
  int _selectedIndex = 0;

  final List<Widget> widgetOptions = [
    FriendsScreen(),
    DirectChatsScreen(),
    GroupChatsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: widgetOptions),
      floatingActionButton: ExpandableFAB(),

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black, // Same as unselected color
        unselectedItemColor: Colors.grey[400],
        selectedLabelStyle: TextStyle(fontSize: 10),
        unselectedLabelStyle: TextStyle(fontSize: 10),
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Image.asset(
              height: 35.sp,
              width: 35.sp,
              _selectedIndex == 0 ? 'assets/005 (1).png' : 'assets/006 (1).png',
            ),
            label: '친구톡톡',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 1 ? 'assets/007 (1).png' : 'assets/008 (1).png',
              height: 35.sp,
              width: 35.sp,
            ),
            label: '1:1 채팅',
          ),
          BottomNavigationBarItem(
            icon: Image.asset(
              _selectedIndex == 2 ? 'assets/009 (1).png' : 'assets/010 (1).png',
              height: 35.sp,
              width: 35.sp,
            ),
            label: '그룹채팅',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (_onItemTapped),
      ),
    );
  }
}
