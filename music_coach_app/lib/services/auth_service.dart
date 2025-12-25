import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = "http://192.168.1.73:8000";

  // -------------------- Registration --------------------
  static Future<bool> register(String email, String password, String username) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/accounts/register/'),
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
      Uri.parse('$baseUrl/api/accounts/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token']['access'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token);
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
      Uri.parse('$baseUrl/api/accounts/profile/'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }

  static Future<bool> updateProfile(String username, String email) async {
    final token = await getToken();
    if (token == null) return false;

    final response = await http.put(
      Uri.parse('$baseUrl/api/accounts/profile/'),
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
      Uri.parse('$baseUrl/api/accounts/change-password/'),
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
      Uri.parse('$baseUrl/api/accounts/password-reset/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    return response.statusCode == 200 || response.statusCode == 201;
  }

  // -------------------- Password Reset Confirm with OTP --------------------
  static Future<bool> resetPasswordWithOtp(String email, String otp, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/accounts/password-reset-confirm/'),
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
