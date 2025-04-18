import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

    int _selectedIndex = 0;

  final List<Widget> widgetOptions = const [
    HomeScreen(),

  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
  selectedItemColor: Colors.black, // Same as unselected color
  unselectedItemColor: Colors.grey[400],
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage(
             _selectedIndex == 0 ?  'assets/001m.png' :'assets/grey_001m.png' 
            ), size: 21,),
            label: 'Home',
          ),
           BottomNavigationBarItem(
            icon: ImageIcon(AssetImage(
             _selectedIndex == 1 ?  'assets/002m.png' :'assets/grey_002m.png' 
            ), size: 21,),
            label: 'Shop',
          ),
           BottomNavigationBarItem(
            icon: ImageIcon(AssetImage(
             _selectedIndex == 2 ?  'assets/003m.png' :'assets/grey_003m.png' 
            ), size: 21,),
            label: 'Cart',
          ),
                     BottomNavigationBarItem(
            icon: ImageIcon(AssetImage(
             _selectedIndex == 3 ?  'assets/004m.png' :'assets/grey_004m.png' 
            ), size: 21,),
            label: 'Orders',
          ),
             BottomNavigationBarItem(
            icon: ImageIcon(AssetImage(
             _selectedIndex == 4 ?  'assets/005m.png' :'assets/grey_005m.png' 
            ), size: 21,),
            label: 'My Page',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (_onItemTapped),
      ),
    );
  }
}
