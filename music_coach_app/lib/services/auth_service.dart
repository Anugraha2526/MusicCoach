import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'progress_service.dart';

class AuthService { 
  static const String _onboardingKey = 'onboarding_completed';
  static const String _selectedInstrumentKey = 'selected_instrument';
  static const String _showLessonsFirstKey = 'show_lessons_first';

  // -------------------- Registration --------------------
  static Future<bool> register(String email, String password, String username, String firstName, String lastName) async {
    final response = await http.post(
      Uri.parse(ApiConfig.register),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email, 
        'password': password, 
        'username': username,
        'first_name': firstName,
        'last_name': lastName
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final accessToken = data['token']['access'];
      final refreshToken = data['token']['refresh'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', accessToken);
      await prefs.setString('refresh_token', refreshToken);
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
      final accessToken = data['token']['access'];
      final refreshToken = data['token']['refresh'];
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', accessToken);
      await prefs.setString('refresh_token', refreshToken);
      await prefs.setBool(_onboardingKey, true); // Assume logging in means already onboarded
      
      // Fetch progress from backend immediately
      await ProgressService.fetchFromBackend();
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
    final refreshToken = prefs.getString('refresh_token');
    final accessToken = prefs.getString('access_token');

    // Blacklist refresh token server-side (best effort)
    if (refreshToken != null && accessToken != null) {
      try {
        await http.post(
          Uri.parse(ApiConfig.logout),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
          body: jsonEncode({'refresh': refreshToken}),
        );
      } catch (_) {
        // Best effort — continue with local cleanup even if server call fails
      }
    }

    // Clear ALL auth-related local data
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove(_onboardingKey); // Reset onboarding on logout
    await ProgressService.clearProgress(); // Clear local lesson progress
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

  // -------------------- Get stored token & Refresh if needed --------------------
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }
  
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  static Future<bool> tryRefreshToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) return false;

    // Construct URL manually or add to ApiConfig if possible. 
    // Assuming structure: ApiConfig.baseUrl + '/accounts/token/refresh/'
    // But since I don't want to edit ApiConfig right now if I can avoid it, I'll infer from another URL
    // e.g. ApiConfig.login is BASE/accounts/login/
    // So refresh is BASE/accounts/token/refresh/
    
    // Safer to just use the base if known, or relative to login.
    // Hack: replacing 'login/' with 'token/refresh/' in login URL
    final refreshUrl = ApiConfig.login.replaceFirst('login/', 'token/refresh/');

    try {
      final response = await http.post(
        Uri.parse(refreshUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', newAccessToken);
        // Sometimes refresh endpoint returns a new refresh token too (depending on setting 'ROTATE_REFRESH_TOKENS')
        if (data.containsKey('refresh')) {
           await prefs.setString('refresh_token', data['refresh']);
        }
        return true;
      } else {
        // Refresh failed (expired refresh token?), logout
        await logout();
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  // -------------------- Profile --------------------
  static Future<Map<String, dynamic>?> fetchProfile() async {
    final token = await getToken();
    if (token == null) return null;

    var response = await http.get(
      Uri.parse(ApiConfig.profile),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 401) {
      // Token might be expired, try refresh
      final refreshSuccess = await tryRefreshToken();
      if (refreshSuccess) {
        final newToken = await getToken();
        response = await http.get(
          Uri.parse(ApiConfig.profile),
          headers: {'Authorization': 'Bearer $newToken'},
        );
      } else {
        return null;
      }
    }

    if (response.statusCode == 200) return jsonDecode(response.body);
    return null;
  }

  // -------------------- Update Streak --------------------
  static Future<bool> updateStreak() async {
    final token = await getToken();
    if (token == null) return false;

    var response = await http.post(
      Uri.parse(ApiConfig.updateStreak),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 401) {
      final refreshSuccess = await tryRefreshToken();
      if (refreshSuccess) {
        final newToken = await getToken();
        response = await http.post(
          Uri.parse(ApiConfig.updateStreak),
          headers: {'Authorization': 'Bearer $newToken'},
        );
      }
    }

    return response.statusCode == 200;
  }

  static Future<bool> updateProfile(String username, String email, String firstName, String lastName, {double? naturalPitch}) async {
    final token = await getToken();
    if (token == null) return false;

    final Map<String, dynamic> bodyData = {
      'username': username, 
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
    };
    if (naturalPitch != null) {
      bodyData['natural_pitch'] = naturalPitch;
    }

    var response = await http.put(
      Uri.parse(ApiConfig.profile),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(bodyData),
    );

    if (response.statusCode == 401) {
      final refreshSuccess = await tryRefreshToken();
      if (refreshSuccess) {
        final newToken = await getToken();
        response = await http.put(
          Uri.parse(ApiConfig.profile),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
          body: jsonEncode(bodyData),
        );
      }
    }

    return response.statusCode == 200;
  }

  // -------------------- Change Password --------------------
  static Future<bool> changePassword(String oldPassword, String newPassword) async {
    final token = await getToken();
    if (token == null) return false;

    var response = await http.post(
      Uri.parse(ApiConfig.changePassword),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'old_password': oldPassword, 'new_password': newPassword}),
    );

    if (response.statusCode == 401) {
      final refreshSuccess = await tryRefreshToken();
      if (refreshSuccess) {
        final newToken = await getToken();
        response = await http.post(
          Uri.parse(ApiConfig.changePassword),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
          body: jsonEncode({'old_password': oldPassword, 'new_password': newPassword}),
        );
      }
    }

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
  static Future<Map<String, dynamic>> resetPasswordWithOtp(String email, String otp, String newPassword) async {
    final response = await http.post(
      Uri.parse(ApiConfig.passwordResetConfirm),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otp': otp,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode == 200) {
      return {'success': true};
    } else {
      // Try to parse the error message from the backend
      try {
        final data = jsonDecode(response.body);
        // Backend may return {'error': '...'} or {'new_password': ['...']} etc.
        String errorMsg = 'OTP invalid or expired.';
        if (data is Map) {
          if (data.containsKey('error')) {
            errorMsg = data['error'];
          } else if (data.containsKey('new_password')) {
            final pwErrors = data['new_password'];
            errorMsg = pwErrors is List ? pwErrors.join(', ') : pwErrors.toString();
          } else {
            // Collect all error messages
            final errors = <String>[];
            data.forEach((key, value) {
              if (value is List) {
                errors.addAll(value.map((e) => e.toString()));
              } else {
                errors.add(value.toString());
              }
            });
            if (errors.isNotEmpty) errorMsg = errors.join(', ');
          }
        }
        return {'success': false, 'error': errorMsg};
      } catch (_) {
        return {'success': false, 'error': 'OTP invalid or expired.'};
      }
    }
  }
}
