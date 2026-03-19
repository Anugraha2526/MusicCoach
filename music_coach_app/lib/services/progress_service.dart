import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class ProgressService {
  static const String _completedKey = 'completed_lessons';

  /// Mark a specific lesson ID as completed.
  /// If [allModules], [targetLevel], and [targetLessonIndex] are provided (even for non-jumps),
  /// this will also mark all EARLIER lessons IN THE SAME LEVEL as completed.
  /// This ensures within-level catchup (e.g. playing Lesson 4 directly marks 1-3 as complete).
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

    // Within-level catchup: mark earlier lessons in the **same level** as complete
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
          break; // Found the target level, no need to keep searching modules
        }
      }
    }

    if (changed) {
      await prefs.setStringList(_completedKey, completed);
      print('DEBUG: Lesson $lessonId (and potentially earlier in level) marked as completed.');
      
      // Async sync to backend
      _syncToBackend(completed);
    }
  }

  /// Mass unlock all lessons in previous (skipped) levels when a user jumps to a higher level.
  /// Only marks levels BELOW targetLevel as completed — the target level is unlocked on the
  /// map automatically because Level(N-1)'s last lesson is now in the completed set.
  /// This keeps the home screen progress bar honest: only actually-played lessons count.
  static Future<void> unlockLessonsUpTo(int targetLevel, int targetLessonIndex, dynamic allModules) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> completed = prefs.getStringList(_completedKey) ?? [];
    bool changed = false;

    // allModules should be a List<LessonModule>
    for (var module in allModules) {
      if (module.order < targetLevel) {
        // Mark ALL lessons in every skipped/previous level as completed
        for (var lesson in module.lessons) {
          if (!completed.contains(lesson.id.toString())) {
            completed.add(lesson.id.toString());
            changed = true;
          }
        }
      }
      // targetLevel lessons are intentionally NOT bulk-completed here.
      // Level (targetLevel-1)'s last lesson being complete is sufficient to
      // unlock targetLevel on the map.  Individual lesson completions within
      // targetLevel are tracked normally via markLessonCompleted.
    }

    if (changed) {
      await prefs.setStringList(_completedKey, completed);
      print('DEBUG: Mass unlocked lessons up to Level $targetLevel, Index $targetLessonIndex.');
      
      // Async sync to backend
      _syncToBackend(completed);
    }
  }

  /// Get a set of all completed lesson IDs for easy lookup.
  static Future<Set<int>> getCompletedLessons() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> completed = prefs.getStringList(_completedKey) ?? [];
    return completed.map((e) => int.tryParse(e) ?? -1).where((e) => e != -1).toSet();
  }

  /// Check if a specific lesson ID is completed.
  static Future<bool> isLessonCompleted(int lessonId) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> completed = prefs.getStringList(_completedKey) ?? [];
    return completed.contains(lessonId.toString());
  }

  /// Optional: Clear all progress (for debugging or logging out)
  static Future<void> clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_completedKey);
    print('DEBUG: Lesson progress cleared.');
  }

  // --- Backend Sync Methods ---

  /// Push local progress to the backend
  static Future<void> _syncToBackend(List<String> completed) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) return; // Not logged in

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
        print('DEBUG: Progress synced to backend successfully.');
      } else if (response.statusCode == 401) {
         // Token expired, try refresh
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
      } else {
        print('DEBUG: Failed to sync progress to backend: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error syncing progress to backend: $e');
    }
  }

  /// Pull progress from the backend and overwrite local storage.
  /// Should be called immediately after successful login.
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
        
        // Overwrite local SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final List<String> completedStrs = backendIds.map((e) => e.toString()).toList();
        await prefs.setStringList(_completedKey, completedStrs);
        
        print('DEBUG: Progress fetched from backend: ${completedStrs.length} lessons.');
      } else {
        print('DEBUG: Failed to fetch progress from backend: ${response.statusCode}');
      }
    } catch (e) {
      print('DEBUG: Error fetching progress from backend: $e');
    }
  }
}
