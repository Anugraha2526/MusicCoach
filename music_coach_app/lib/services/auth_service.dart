import 'dart:convert'; // Converts Dart ↔ JSON
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = "http://192.168.1.73:8000"; // real phone

  static Future<String?> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/accounts/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['token']['access']; 
    }
    return null;
  }
}
