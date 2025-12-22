import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = "http://192.168.1.73:8000"; // Replace with your backend IP

  // Registration
  static Future<bool> register(String email, String password, String username) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/accounts/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'username': username,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final token = data['token']['access'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', token); // Save token for auto-login
      return true;
    }
    return false;
  }

  // Login
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
      await prefs.setString('access_token', token); // Save token for auto-login
      return true;
    }
    return false;
  }

  // Check if user is already logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return token != null;
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }
}
