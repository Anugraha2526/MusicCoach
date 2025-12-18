import 'package:flutter/material.dart';
// import 'screens/piano_lesson_play/piano_lesson_play.dart'; 
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Coach',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true, // optional, for modern Material3 style
      ),
      // home: const PianoLessonPlay(
      //   lessonId: 1,
      // ),
      home: HomeScreen(),
       routes: {
        '/login': (context) => LoginScreen(),
        // '/signup': (context) => SignUpScreen(),
      },
    );
  }
}
