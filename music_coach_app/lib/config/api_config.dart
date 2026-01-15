/// API Configuration
/// 
/// Centralized configuration for API base URLs.
/// Update the baseUrl to match your backend server address.
class ApiConfig {
  // TODO: Move this to environment variables or config file for production
  // For development, update this to your local IP address
  static const String baseUrl = "http://192.168.1.72:8000";
  // static const String baseUrl = "http://127.0.0.1:8000";
  
  // API endpoints
  static const String accountsBase = "$baseUrl/api/accounts";
  static const String instrumentsBase = "$baseUrl/api/instruments";
  
  // Account endpoints
  static const String register = "$accountsBase/register/";
  static const String login = "$accountsBase/login/";
  static const String logout = "$accountsBase/logout/";
  static const String profile = "$accountsBase/profile/";
  static const String changePassword = "$accountsBase/change-password/";
  static const String passwordReset = "$accountsBase/password-reset/";
  static const String passwordResetConfirm = "$accountsBase/password-reset-confirm/";
  
  // Instrument endpoints
  static const String instruments = "$instrumentsBase/";
  static String instrumentById(int id) => "$instrumentsBase/$id/";
  
  // Lesson endpoints
  static const String lessonsBase = "$baseUrl/api/lessons";
  static const String lessonUnitsBase = "$baseUrl/api/lesson-units";
  static String lessonUnits(int lessonId) => "$lessonsBase/$lessonId/units/";
  static String lessonSequences(int lessonId) => "$lessonsBase/$lessonId/sequences/";
  static String unitQuiz(int unitId) => "$lessonUnitsBase/$unitId/quiz/";
  static String unitNotation(int unitId) => "$lessonUnitsBase/$unitId/notation/";
}

