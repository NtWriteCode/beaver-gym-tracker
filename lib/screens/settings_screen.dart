// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/settings_provider.dart';
import '../providers/workout_provider.dart';
import '../utils/backup_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return Column(
              children: AppThemeMode.values.map((mode) {
                String title;
                String subtitle;
                switch (mode) {
                  case AppThemeMode.light:
                    title = 'Light';
                    subtitle = 'Standard light theme';
                    break;
                  case AppThemeMode.dark:
                    title = 'Dark';
                    subtitle = 'Standard dark theme';
                    break;
                  case AppThemeMode.amoled:
                    title = 'Pure Black (AMOLED)';
                    subtitle = 'Battery saver for OLED screens';
                    break;
                  case AppThemeMode.dynamic:
                    title = 'Dynamic Material You';
                    subtitle = 'Adapts to system wallpaper & mode';
                    break;
                }
                return RadioListTile<AppThemeMode>(
                  title: Text(title),
                  subtitle: Text(subtitle),
                  value: mode,
                  groupValue: settings.currentTheme,
                  onChanged: (AppThemeMode? value) {
                    if (value != null) {
                      settings.setTheme(value);
                    }
                  },
                );
              }).toList(),
            );
          },
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Workout Settings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Consumer<SettingsProvider>(
          builder: (context, settings, _) {
            return Column(
              children: [
                ListTile(
                  title: const Text('GPS Match Radius'),
                  subtitle: Text('Distance to detect a gym: ${settings.gpsRadius.round()} meters'),
                  trailing: Text(
                    '${settings.gpsRadius.round()} m',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Slider(
                    value: settings.gpsRadius,
                    min: 10,
                    max: 500,
                    divisions: 49,
                    label: '${settings.gpsRadius.round()} m',
                    onChanged: (double value) {
                      settings.setGpsRadius(value);
                    },
                  ),
                ),
              ],
            );
          },
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Backup & Restore',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.upload_file),
          title: const Text('Export Data'),
          subtitle: const Text('Save all your data to a JSON file'),
          onTap: () => _exportData(context),
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Import Data'),
          subtitle: const Text('Restore data from a backup file'),
          onTap: () => _importData(context),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'Debug & Data',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Consumer<WorkoutProvider>(
          builder: (context, provider, _) {
            return Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.auto_awesome),
                  title: const Text('Generate Realistic Data'),
                  subtitle: const Text('25 workouts spread over 6 months with streaks'),
                  onTap: () async {
                     await provider.clearAllHistory();
                     await provider.debugGenerateRandomHistory();
                     if (context.mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Realistic data generated!')),
                       );
                     }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
                  title: Text(
                    'Nuclear Reset',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  subtitle: const Text('Wipes ALL workouts, exercises and achievements'),
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Nuclear Reset?'),
                        content: const Text('This will permanently delete everything. History, exercises, achievements... gone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Reset', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await provider.clearAllHistory();
                    }
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      // Show loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Exporting data...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      final prefs = await SharedPreferences.getInstance();
      final filePath = await BackupService.exportData(prefs);

      scaffoldMessenger.hideCurrentSnackBar();

      if (filePath != null && context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Successful! 🦫'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your data has been exported to:'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    filePath,
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.hideCurrentSnackBar();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Show warning dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data?'),
        content: const Text(
          'This will REPLACE all your current data with the data from the backup file. '
          'Your current workouts, templates, and settings will be overwritten.\n\n'
          'Consider exporting your current data first as a safety backup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Show loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Importing data...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await BackupService.importData(prefs);

      scaffoldMessenger.hideCurrentSnackBar();

      if (context.mounted) {
        // Show success and tell user to restart
        // (Providers will reload data when app restarts)
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Import Successful! 🦫'),
            content: const Text(
              'Your data has been imported successfully.\n\n'
              'Please restart the app to see all changes.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.hideCurrentSnackBar();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
