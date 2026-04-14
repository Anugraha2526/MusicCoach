import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class ProgressService {
  static const String _completedKey = 'completed_lessons';

  static Future<void> markLessonCompleted(
    int lessonId, {
    List<dynamic>? allModules,
    int? targetLevel,
    int? targetLessonIndex,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> completed = prefs.getStringList(_completedKey) ?? [];
    bool changed = false;

    if (!completed.contains(lessonId.toString())) {
      completed.add(lessonId.toString());
      changed = true;
    }

    if (allModules != null && targetLevel != null && targetLessonIndex != null) {
      for (var module in allModules) {
        if (module.order == targetLevel) {
          for (int i = 0; i < module.lessons.length; i++) {
            if (i < targetLessonIndex) {
              final earlierLessonId = module.lessons[i].id.toString();
              if (!completed.contains(earlierLessonId)) {
                completed.add(earlierLessonId);
                changed = true;
              }
            }
          }
          break;
        }
      }
    }

    if (changed) {
      await prefs.setStringList(_completedKey, completed);
      _syncToBackend(completed);
    }
  }

  static Future<void> unlockLessonsUpTo(int targetLevel, int targetLessonIndex, dynamic allModules) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> completed = prefs.getStringList(_completedKey) ?? [];
    bool changed = false;

    for (var module in allModules) {
      if (module.order < targetLevel) {
        for (var lesson in module.lessons) {
          if (!completed.contains(lesson.id.toString())) {
            completed.add(lesson.id.toString());
            changed = true;
          }
        }
      }
    }

    if (changed) {
      await prefs.setStringList(_completedKey, completed);
      _syncToBackend(completed);
    }
  }

  static Future<Set<int>> getCompletedLessons() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> completed = prefs.getStringList(_completedKey) ?? [];
    return completed.map((e) => int.tryParse(e) ?? -1).where((e) => e != -1).toSet();
  }

  static Future<bool> isLessonCompleted(int lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> completed = prefs.getStringList(_completedKey) ?? [];
    return completed.contains(lessonId.toString());
  }

  static Future<void> clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completedKey);
  }

  static Future<String> fetchDynamicFeedback({
    required String lessonName,
    int? accuracy,
    int? stars,
    String instrument = 'piano',
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return "Amazing job finishing the lesson! Keep up the great work!";
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/lessons/progress/feedback/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'lesson_name': lessonName,
          if (accuracy != null) 'accuracy': accuracy,
          if (stars != null) 'stars': stars,
          'instrument': instrument,
        }),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['message'] as String? ?? '';
        if (message.isNotEmpty) return message;
      }
    } catch (e) {}
    return "Amazing job finishing the lesson! Keep up the great work!";
  }

  static Future<void> _syncToBackend(List<String> completed) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      final lessonIds = completed.map((e) => int.tryParse(e)).where((e) => e != null).toList();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/lessons/progress/sync/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'lesson_ids': lessonIds,
        }),
      );

      if (response.statusCode == 200) {
      } else if (response.statusCode == 401) {
         final refreshSuccess = await AuthService.tryRefreshToken();
         if (refreshSuccess) {
            final newToken = await AuthService.getToken();
            await http.post(
              Uri.parse('${ApiConfig.baseUrl}/api/lessons/progress/sync/'),
              headers: {
                'Content-Type': 'application/json',
                if (newToken != null) 'Authorization': 'Bearer $newToken',
              },
              body: jsonEncode({
                'lesson_ids': lessonIds,
              }),
            );
         }
      }
    } catch (e) {}
  }

  static Future<void> fetchFromBackend() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return;

      var response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/lessons/progress/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 401) {
         final refreshSuccess = await AuthService.tryRefreshToken();
         if (refreshSuccess) {
            final newToken = await AuthService.getToken();
            response = await http.get(
              Uri.parse('${ApiConfig.baseUrl}/api/lessons/progress/'),
              headers: {
                'Content-Type': 'application/json',
                if (newToken != null) 'Authorization': 'Bearer $newToken',
              },
            );
         }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> backendIds = data['completed_lesson_ids'] ?? [];
        final prefs = await SharedPreferences.getInstance();
        final List<String> completedStrs = backendIds.map((e) => e.toString()).toList();
        await prefs.setStringList(_completedKey, completedStrs);
      }
    } catch (e) {}
  }
}
