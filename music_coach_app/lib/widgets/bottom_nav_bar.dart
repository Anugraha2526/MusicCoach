import 'package:flutter/material.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const AppBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF132238), // Slightly lighter dark blue
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFF00B4D8), // Blue for active
        unselectedItemColor: const Color(0xFF94A3B8), // Gray for inactive
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: _buildIcon(Icons.home, 0),
            activeIcon: _buildActiveIcon(Icons.home, 0),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon(Icons.fitness_center, 1), // Dumbbells icon for Lessons
            activeIcon: _buildActiveIcon(Icons.fitness_center, 1),
            label: 'Lessons',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon(Icons.person, 2),
            activeIcon: _buildActiveIcon(Icons.person, 2),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildIcon(IconData icon, int index) {
    final isActive = currentIndex == index;
    if (isActive) {
      return _buildActiveIcon(icon, index);
    }
    return Icon(
      icon,
      color: const Color(0xFF94A3B8),
    );
  }

  Widget _buildActiveIcon(IconData icon, int index) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF00B4D8).withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: const Color(0xFF00B4D8),
      ),
    );
  }
}
