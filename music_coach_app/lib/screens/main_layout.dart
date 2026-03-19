import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'piano_lesson_screen.dart';
import 'vocal_lesson_screen.dart';
import 'guitar_tuner_screen.dart';
import 'realtime_pitch_graph_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0; // Default to home tab
  Widget? _lessonsScreen; // Cache the instrument screen to avoid flash

  @override
  void initState() {
    super.initState();
    _checkInitialTab();
    _loadInstrumentScreen();
  }

  Future<void> _checkInitialTab() async {
    // Check if we should show lessons first (coming from onboarding)
    final showLessonsFirst = await AuthService.getAndClearShowLessonsFirst();
    if (showLessonsFirst && mounted) {
      setState(() {
        _currentIndex = 1; // Start with lessons tab
      });
    }
  }

  Future<void> _loadInstrumentScreen() async {
    final instrument = await AuthService.getSelectedInstrument();
    Widget screen;
    
    switch (instrument?.toLowerCase()) {
      case 'piano':
        screen = const PianoLessonScreen();
        break;
      case 'vocals':
        screen = VocalLessonScreen(
          onBackPressed: () {
            setState(() {
              _currentIndex = 0; // Go back to Home
            });
          },
        );
        break;
      case 'guitar':
        screen = GuitarTunerScreen(
          onBackPressed: () {
            setState(() {
              _currentIndex = 0; // Go back to Home
            });
          },
        );
        break;
      case 'pitch':
        screen = RealtimePitchGraphScreen(
          onBackPressed: () {
            setState(() {
              _currentIndex = 0; // Go back to Home
            });
          },
        );
        break;
      default:
        // Fallback to piano if no instrument selected
        screen = const PianoLessonScreen();
    }
    
    if (mounted) {
      setState(() {
        _lessonsScreen = screen;
      });
    }
  }

  // Method to switch to a specific lesson screen and show lessons tab
  void switchToLessonScreen(String instrumentType) {
    Widget screen;
    
    switch (instrumentType.toLowerCase()) {
      case 'piano':
        screen = const PianoLessonScreen();
        break;
      case 'vocals':
      case 'vocal':
        screen = VocalLessonScreen(
          onBackPressed: () {
            setState(() {
              _currentIndex = 0; // Go back to Home
            });
          },
        );
        break;
      default:
        return; // Don't switch for other types
    }
    
    setState(() {
      _lessonsScreen = screen;
      _currentIndex = 1; // Switch to lessons tab
    });
  }

  List<Widget> get _screens {
    return [
      HomeScreen(onLessonTap: switchToLessonScreen),
      _lessonsScreen ?? const Center(child: CircularProgressIndicator()),
      ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent back button from going to landing/login
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A), // Matches dark theme to hide white edges behind nav bar radii
        body: _screens[_currentIndex],
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}
