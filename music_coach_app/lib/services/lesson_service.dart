import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lesson_models.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

/// Service for fetching lesson data from the backend API.
class LessonService {
  /// Fetch all lesson modules and their nested lessons.
  /// Fetch all lesson modules and their nested lessons.
  static Future<List<LessonModule>> fetchModules({String? instrumentType}) async {
    try {
      final token = await AuthService.getToken();
      
      String url = '${ApiConfig.baseUrl}/api/lessons/';
      if (instrumentType != null) {
        url += '?instrument=$instrumentType';
      }
      
      var response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
        final refreshSuccess = await AuthService.tryRefreshToken();
        if (refreshSuccess) {
          final newToken = await AuthService.getToken();
          response = await http.get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              if (newToken != null) 'Authorization': 'Bearer $newToken',
            },
          );
        }
      }

      if (response.statusCode == 200) {
        final List<dynamic> modulesJson = jsonDecode(response.body);
        return modulesJson.map((json) => LessonModule.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load modules: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching modules: $e');
    }
  }

  /// Fetch practice sequences for interactive piano lesson.
  static Future<List<PracticeSequence>> fetchLessonSequences(int lessonId) async {
    try {
      final token = await AuthService.getToken();
      var response = await http.get(
        // Use the sequences endpoint
        Uri.parse('${ApiConfig.baseUrl}/api/lessons/$lessonId/sequences/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
         // Try refresh
         final refreshSuccess = await AuthService.tryRefreshToken();
         if (refreshSuccess) {
            final newToken = await AuthService.getToken();
            response = await http.get(
              Uri.parse('${ApiConfig.baseUrl}/api/lessons/$lessonId/sequences/'),
              headers: {
                'Content-Type': 'application/json',
                if (newToken != null) 'Authorization': 'Bearer $newToken',
              },
            );
         } else {
            // Force logout or throw specific error?
            throw Exception('Session expired. Please login again.');
         }
      }

      if (response.statusCode == 200) {
        // Backend returns a List directly, not an object with 'sequences' key
        final List<dynamic> sequencesJson = jsonDecode(response.body);
        return sequencesJson.map((json) => PracticeSequence.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load sequences: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching sequences: $e');
    }
  }
}
