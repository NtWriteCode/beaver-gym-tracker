import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class BackupService {
  static const String _version = '1.0.0';

  /// Export all app data to a JSON file
  static Future<String?> exportData(SharedPreferences prefs) async {
    try {
      // Gather all data from SharedPreferences
      final Map<String, dynamic> exportData = {
        'version': _version,
        'exportDate': DateTime.now().toIso8601String(),
        'data': {
          // Workout data
          'workout_history': prefs.getStringList('workout_history'),
          'active_workout': prefs.getString('active_workout'),
          'exercises': prefs.getStringList('exercises'),
          'exercise_names': prefs.getStringList('exercise_names'),
          'workout_templates': prefs.getStringList('workout_templates'),
          
          // Location data
          'saved_locations': prefs.getStringList('saved_locations'),
          
          // Achievements
          'earned_achievements': prefs.getString('earned_achievements'),
          
          // Settings
          'theme_mode': prefs.getInt('theme_mode'),
          'gps_radius': prefs.getDouble('gps_radius'),
          'user_weight': prefs.getDouble('user_weight'),
          'user_age': prefs.getInt('user_age'),
          'user_height': prefs.getDouble('user_height'),
          'user_sex': prefs.getString('user_sex'),
          
          // Metadata
          'weight_update_count': prefs.getInt('weight_update_count'),
          'manual_calorie_count': prefs.getInt('manual_calorie_count'),
        },
      };

      // Convert to JSON string
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // Generate filename with timestamp
      final timestamp = DateFormat('yyyy-MM-dd_HHmmss').format(DateTime.now());
      final filename = 'beaver_gym_backup_$timestamp.json';

      // Get downloads directory or temp directory
      Directory? directory;
      if (Platform.isAndroid) {
        // Try to get downloads directory, fallback to external storage
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getDownloadsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      // Write file
      final file = File('${directory.path}/$filename');
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      rethrow;
    }
  }

  /// Import data from a JSON file
  static Future<void> importData(SharedPreferences prefs) async {
    try {
      // Let user pick a file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('No file selected');
      }

      final filePath = result.files.first.path;
      if (filePath == null) {
        throw Exception('Could not read file path');
      }

      // Read file
      final file = File(filePath);
      final jsonString = await file.readAsString();

      // Parse JSON
      final Map<String, dynamic> importData = jsonDecode(jsonString);

      // Validate version (basic check)
      if (!importData.containsKey('version') || !importData.containsKey('data')) {
        throw Exception('Invalid backup file format');
      }

      final data = importData['data'] as Map<String, dynamic>;

      // Clear existing data
      await prefs.clear();

      // Import all data back to SharedPreferences
      for (final entry in data.entries) {
        final key = entry.key;
        final value = entry.value;

        if (value == null) continue;

        if (value is List) {
          // Handle List<String>
          await prefs.setStringList(key, List<String>.from(value));
        } else if (value is String) {
          await prefs.setString(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is double) {
          await prefs.setDouble(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get a human-readable summary of the backup
  static Map<String, dynamic> getBackupSummary(Map<String, dynamic> backupData) {
    final data = backupData['data'] as Map<String, dynamic>;
    
    final workoutHistory = data['workout_history'] as List?;
    final templates = data['workout_templates'] as List?;
    final locations = data['saved_locations'] as List?;
    final exercises = data['exercises'] as List?;

    return {
      'version': backupData['version'],
      'exportDate': backupData['exportDate'],
      'workoutCount': workoutHistory?.length ?? 0,
      'templateCount': templates?.length ?? 0,
      'locationCount': locations?.length ?? 0,
      'exerciseCount': exercises?.length ?? 0,
    };
  }
}
