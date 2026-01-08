import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lesson_models.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

/// Service for fetching lesson data from the backend API.
class LessonService {
  /// Fetch practice sequences for interactive piano lesson.
  static Future<List<PracticeSequence>> fetchLessonSequences(int lessonId) async {
    try {
      final token = await AuthService.getToken();
      final response = await http.get(
        // Use the sequences endpoint
        Uri.parse('${ApiConfig.baseUrl}/api/lessons/$lessonId/sequences/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

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
