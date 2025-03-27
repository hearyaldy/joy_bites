import 'package:flutter/material.dart';
import 'entry_screen.dart';
import 'package:joy_bites/widgets/app_drawer.dart'; // Updated import

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const EntryScreen(),  // Your main content page
    // Add additional pages if needed.
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JoyBites'),
      ),
      drawer: const AppDrawer(),  // Uses the newly created AppDrawer widget
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          // Add more navigation items here.
        ],
      ),
    );
  }
}
