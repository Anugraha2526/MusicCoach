import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService { 
  static const String _onboardingKey = 'onboarding_completed';
  static const String _selectedInstrumentKey = 'selected_instrument';
  static const String _showLessonsFirstKey = 'show_lessons_first';

  // -------------------- Registration --------------------
  static Future<bool> register(String email, String password, String username) async {
    final response = await http.post(
      Uri.parse(ApiConfig.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'username': username}),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data['token']['access'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      return true;
    }
    return false;
  }

  // -------------------- Login --------------------
  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(ApiConfig.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token']['access'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
      await prefs.setBool(_onboardingKey, true); // Assume logging in means already onboarded
      return true;
    }
    return false;
  }

  // -------------------- Check login status --------------------
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return token != null;
  }

  // -------------------- Logout --------------------
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove(_onboardingKey); // Reset onboarding on logout
  }

  // Onboarding: check if completed
  static Future<bool> hasCompletedOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  // Onboarding: mark as completed
  static Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  // Onboarding: reset (for testing)
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingKey);
  }

  // Selected Instrument: save
  static Future<void> saveSelectedInstrument(String instrument) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedInstrumentKey, instrument);
  }

  // Selected Instrument: get
  static Future<String?> getSelectedInstrument() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_selectedInstrumentKey);
  }

  // Show Lessons First: set (when coming from onboarding)
  static Future<void> setShowLessonsFirst(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showLessonsFirstKey, value);
  }

  // Show Lessons First: get and clear
  static Future<bool> getAndClearShowLessonsFirst() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_showLessonsFirstKey) ?? false;
    if (value) {
      // Clear the flag after reading it
      await prefs.remove(_showLessonsFirstKey);
    }
    return value;
  }

  // -------------------- Get stored token --------------------
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // -------------------- Profile --------------------
  static Future<Map<String, dynamic>?> fetchProfile() async {
    final token = await getToken();
    if (token == null) return null;

    final response = await http.get(
      Uri.parse(ApiConfig.profile),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }

  static Future<bool> updateProfile(String username, String email) async {
    final token = await getToken();
    if (token == null) return false;

    final response = await http.put(
      Uri.parse(ApiConfig.profile),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'username': username, 'email': email}),
    );

    return response.statusCode == 200;
  }

  // -------------------- Change Password --------------------
  static Future<bool> changePassword(String oldPassword, String newPassword) async {
    final token = await getToken();
    if (token == null) return false;

    final response = await http.post(
      Uri.parse(ApiConfig.changePassword),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'old_password': oldPassword, 'new_password': newPassword}),
    );

    return response.statusCode == 200;
  }

  // -------------------- Password Reset Request (Send OTP) --------------------
  static Future<bool> requestPasswordReset(String email) async {
    final response = await http.post(
      Uri.parse(ApiConfig.passwordReset),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  // -------------------- Password Reset Confirm with OTP --------------------
  static Future<bool> resetPasswordWithOtp(String email, String otp, String newPassword) async {
    final response = await http.post(
      Uri.parse(ApiConfig.passwordResetConfirm),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otp': otp,             // Using OTP sent to email
        'new_password': newPassword,
      }),
    );

    return response.statusCode == 200;
  }
}
