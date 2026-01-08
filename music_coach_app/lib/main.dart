import 'package:flutter/material.dart';
import 'package:music_coach/services/auth_service.dart';
import 'package:music_coach/routes/app_routes.dart';
import 'package:music_coach/routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool onboarded = await AuthService.hasCompletedOnboarding();
  bool isLoggedIn = await AuthService.isLoggedIn();

  // Determine initial route
  // 1. Not logged in -> Landing
  // 2. Logged in but not onboarded -> Onboarding
  // 3. Logged in and onboarded -> Main
  String initialRoute;
  if (!isLoggedIn) {
    initialRoute = AppRoutes.landing;
  } else if (!onboarded) {
    initialRoute = AppRoutes.onboarding;
  } else {
    initialRoute = AppRoutes.main;
  }

  runApp(MyApp(initialRoute: initialRoute));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Coach',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: initialRoute,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
