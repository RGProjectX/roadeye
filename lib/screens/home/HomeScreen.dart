import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:roadeye/screens/map/LiveTracking.dart';
import 'package:roadeye/screens/map/MapScreen.dart';
import '../detection/DetectionPage.dart';
import 'HeroSection.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          HeroSectionPage(),
          // MapScreen(),
          LiveTracking(),
          PotholeDetector(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 36, 124, 65).withOpacity(0.8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
          child: GNav(
            rippleColor: const Color(0xff0fff78).withOpacity(0.1),
            hoverColor: const Color(0xff0fff78).withOpacity(0.2),
            haptic: true,
            curve: Curves.easeIn,
            duration: const Duration(milliseconds: 500),
            gap: 8,
            color: Colors.grey[800],
            activeColor: Colors.white,
            iconSize: 24,
            tabBackgroundColor: const Color(0xff0fff78).withOpacity(0.2),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            tabs: const [
              GButton(
                icon: CupertinoIcons.home,
                text: 'Home',
              ),
              GButton(
                icon: CupertinoIcons.location,
                text: 'Maps',
              ),
              GButton(
                icon: CupertinoIcons.camera,
                text: 'Detection',
              ),
            ],
            selectedIndex: _selectedIndex,
            onTabChange: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}
