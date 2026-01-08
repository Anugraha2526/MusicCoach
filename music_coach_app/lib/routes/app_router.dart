import 'package:flutter/material.dart';
import '../screens/landing_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/main_layout.dart';
import '../screens/instrument_select_screen.dart';
import '../screens/forgot_pass_screen.dart';
import '../screens/reset_pass_screen.dart';
import '../screens/change_pass_screen.dart';

// Instrument-specific screens
import '../screens/piano_lesson_screen.dart';
import '../screens/vocal_lesson_screen.dart';
import '../screens/guitar_tuner_screen.dart';
import '../screens/realtime_pitch_graph_screen.dart';


import 'app_routes.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {

      // Auth
      case AppRoutes.landing:
        return MaterialPageRoute(builder: (_) => const LandingScreen());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => RegisterScreen());
      case '/forgot-password':
        return MaterialPageRoute(builder: (_) => ForgotPasswordScreen());
      case '/reset-password':
        final args = settings.arguments as Map<String, String>?;
        return MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(email: args?['email'] ?? ''),
        );
      case '/change-password':
        return MaterialPageRoute(builder: (_) => ChangePasswordScreen());

      // Onboarding
      case AppRoutes.onboarding:
        return MaterialPageRoute(builder: (_) => InstrumentSelectScreen());

      // Main / BottomNav
      case AppRoutes.main:
        return MaterialPageRoute(builder: (_) => MainLayout());
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => HomeScreen());
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => ProfileScreen());

      // Instrument / Lesson Screens
      case AppRoutes.pianoLesson:
        return MaterialPageRoute(builder: (_) => const PianoLessonScreen());
      case AppRoutes.vocalLesson:
        return MaterialPageRoute(builder: (_) => const VocalLessonScreen());
      case AppRoutes.guitarTuner:
        return MaterialPageRoute(builder: (_) => const GuitarTunerScreen());
      case AppRoutes.realtimePitchGraph:
        return MaterialPageRoute(builder: (_) => const RealtimePitchGraphScreen());
      
      // Lesson detail screen (receives lessonId as argument)


      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}
