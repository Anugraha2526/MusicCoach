import 'package:flutter/material.dart';
import 'package:music_coach/services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if user is logged in for auto-login
  bool loggedIn = await AuthService.isLoggedIn();

  runApp(MyApp(startOnHome: loggedIn));
}

class MyApp extends StatelessWidget {
  final bool startOnHome;

  const MyApp({super.key, this.startOnHome = false}); // default false

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Coach',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: startOnHome ? '/home' : '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
      },
    );
  }
}
