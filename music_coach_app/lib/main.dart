import 'package:flutter/material.dart';
import 'package:music_coach/services/auth_service.dart';
import 'package:music_coach/routes/app_routes.dart';
import 'package:music_coach/routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool onboarded = await AuthService.hasCompletedOnboarding();

  // Determine initial route: onboarding for new users, otherwise main layout
  String initialRoute = onboarded ? AppRoutes.main : AppRoutes.onboarding;

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
