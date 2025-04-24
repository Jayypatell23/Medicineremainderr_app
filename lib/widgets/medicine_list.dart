import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:medicine_remainderrr/services/database_helper.dart';
import 'package:medicine_remainderrr/services/alarm_sound.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/services.dart';
import 'package:app_settings/app_settings.dart';

class MedicineList extends StatefulWidget {
  const MedicineList({super.key});

  @override
  State<MedicineList> createState() => MedicineListState();

  static Future<void> scheduleNotification(String medicineName, DateTime scheduledTime) async {
    debugPrint('Starting to schedule notification for $medicineName at $scheduledTime');
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    try {
      // Request notification permissions
      debugPrint('Requesting notification permissions...');
      final bool? result = await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestPermission();
      
      debugPrint('Notification permission granted: $result');
      
      if (result ?? false) {
        // Initialize timezone
        debugPrint('Initializing timezone...');
        tz.initializeTimeZones();
        
        // Create Android notification details with sound and vibration
        debugPrint('Creating notification details...');
        final AndroidNotificationDetails androidPlatformChannelSpecifics =
            AndroidNotificationDetails(
          'medicine_reminders',
          'Medicine Reminders',
          channelDescription: 'Notifications for medicine reminders',
          importance: Importance.max,
          priority: Priority.high,
          sound: UriAndroidNotificationSound('android.resource://android/raw/alarm'),
          enableVibration: !kIsWeb,
          vibrationPattern: kIsWeb ? null : Int64List.fromList([0, 1000, 500, 1000]),
          playSound: true,
          enableLights: true,
          color: Colors.blue,
          ledColor: Colors.blue,
          ledOnMs: 1000,
          ledOffMs: 500,
          fullScreenIntent: true,
          autoCancel: false,
          ongoing: true,
          channelShowBadge: true,
          showWhen: true,
          when: scheduledTime.millisecondsSinceEpoch,
          category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          timeoutAfter: null,
          showProgress: false,
          onlyAlertOnce: false,
          ticker: 'Time to take your medicine!',
          styleInformation: const DefaultStyleInformation(true, true),
          actions: const [
            AndroidNotificationAction(
              'snooze',
              'Snooze',
              showsUserInterface: true,
            ),
            AndroidNotificationAction(
              'taken',
              'Taken',
              showsUserInterface: true,
            ),
          ],
        );

        final NotificationDetails platformChannelSpecifics =
            NotificationDetails(android: androidPlatformChannelSpecifics);

        // Schedule the notification
        debugPrint('Scheduling notification...');
        final scheduledTimeZone = tz.TZDateTime.from(scheduledTime, tz.local);
        debugPrint('Scheduled time in local timezone: $scheduledTimeZone');
        
        // First, cancel any existing notifications with the same ID
        await flutterLocalNotificationsPlugin.cancel(scheduledTime.millisecondsSinceEpoch ~/ 1000);
        
        // Then schedule the new notification
        await flutterLocalNotificationsPlugin.zonedSchedule(
          scheduledTime.millisecondsSinceEpoch ~/ 1000,
          'Medicine Reminder',
          'Time to take $medicineName',
          scheduledTimeZone,
          platformChannelSpecifics,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: medicineName,
          androidAllowWhileIdle: true,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        debugPrint('Notification scheduled successfully');
      } else {
        debugPrint('Notification permission not granted');
      }
    } catch (e, stackTrace) {
      debugPrint('Error scheduling notification: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }
}

class MedicineListState extends State<MedicineList> {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  List<Map<String, dynamic>> _medicines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    loadMedicines();
  }

  Future<void> _initializeNotifications() async {
    debugPrint('Initializing notifications...');
    try {
      if (kIsWeb) {
        // For web, we'll use a simple alert for now
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Browser Notifications'),
              content: const Text(
                'Please enable notifications in your browser settings to receive medicine reminders. '
                'Click the lock icon in your browser\'s address bar and enable notifications.',
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
      } else {
        // Mobile platform code remains the same
        tz.initializeTimeZones();
        
        final AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');
        
        await _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(
              AndroidNotificationChannel(
                'medicine_reminders',
                'Medicine Reminders',
                description: 'Notifications for medicine reminders',
                importance: Importance.max,
                playSound: true,
                sound: const RawResourceAndroidNotificationSound('alarm'),
                enableVibration: true,
                vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
                showBadge: true,
                enableLights: true,
                ledColor: Colors.blue,
              ),
            );

        const DarwinInitializationSettings initializationSettingsIOS =
            DarwinInitializationSettings();
        final InitializationSettings initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );
        
        await _notifications.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            debugPrint('Notification clicked: ${response.payload}');
          },
        );

        final bool? result = await _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestPermission();
        debugPrint('Mobile notification permission: $result');

        if (result == null || !result) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Notification Permission Required'),
                content: const Text(
                  'This app needs notification permission to remind you about your medicines. '
                  'Please enable notifications in the app settings.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _openAppSettings();
                    },
                    child: const Text('Open Settings'),
                  ),
                ],
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notifications enabled successfully!'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error initializing notifications: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error enabling notifications: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _openAppSettings() async {
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid) {
          const platform = MethodChannel('com.example.medicine_remainderrr/settings');
          await platform.invokeMethod('openAppSettings');
        } else if (Platform.isIOS) {
          await AppSettings.openAppSettings();
        }
      } catch (e) {
        debugPrint('Error opening app settings: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error opening settings: $e'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Browser Settings'),
            content: const Text(
              'Please enable notifications in your browser settings. '
              'Click the lock icon in your browser\'s address bar and enable notifications.',
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
    }
  }

  Future<void> _testNotification() async {
    try {
      debugPrint('Starting test notification...');
      
      // First, show an immediate notification to test basic functionality
      debugPrint('Showing immediate notification...');
      await _notifications.show(
        0,
        'Test Notification',
        'This is a test notification',
        NotificationDetails(
          android: AndroidNotificationDetails(
            'medicine_reminders',
            'Medicine Reminders',
            channelDescription: 'Notifications for medicine reminders',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            sound: const RawResourceAndroidNotificationSound('alarm'),
            enableVibration: !kIsWeb,
            vibrationPattern: kIsWeb ? null : Int64List.fromList([0, 1000, 500, 1000]),
            playSound: true,
            enableLights: true,
            color: Colors.blue,
            ledColor: Colors.blue,
            ledOnMs: 1000,
            ledOffMs: 500,
            fullScreenIntent: true,
            autoCancel: false,
            ongoing: true,
            channelShowBadge: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
          ),
        ),
      );
      
      // Then schedule a notification for 5 seconds from now
      final testTime = DateTime.now().add(const Duration(seconds: 5));
      debugPrint('Scheduling notification for: $testTime');
      
      final scheduledTimeZone = tz.TZDateTime.from(testTime, tz.local);
      
      await _notifications.zonedSchedule(
        1,
        'Medicine Reminder',
        'Time to take Test Medicine',
        scheduledTimeZone,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'medicine_reminders',
            'Medicine Reminders',
            channelDescription: 'Notifications for medicine reminders',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            sound: const RawResourceAndroidNotificationSound('alarm'),
            enableVibration: !kIsWeb,
            vibrationPattern: kIsWeb ? null : Int64List.fromList([0, 1000, 500, 1000]),
            playSound: true,
            enableLights: true,
            color: Colors.blue,
            ledColor: Colors.blue,
            ledOnMs: 1000,
            ledOffMs: 500,
            fullScreenIntent: true,
            autoCancel: false,
            ongoing: true,
            channelShowBadge: true,
            category: AndroidNotificationCategory.alarm,
            visibility: NotificationVisibility.public,
          ),
        ),
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'Test Medicine',
        androidAllowWhileIdle: true,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Test notification scheduled for 5 seconds from now'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error testing notification: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error testing notification: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> loadMedicines() async {
    try {
      final medicines = await DatabaseHelper.instance.getAllMedicines();
      setState(() {
        _medicines = medicines;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteMedicine(String id) async {
    try {
      debugPrint('Deleting medicine with ID: $id');
      final result = await DatabaseHelper.instance.deleteMedicine(id);
      debugPrint('Delete result: $result');
      
      if (result > 0) {
        setState(() {
          _medicines.removeWhere((medicine) => medicine['id'] == id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicine deleted successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to delete medicine')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error deleting medicine: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _testNotification,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Test Notifications'),
          ),
        ),
        if (_medicines.isEmpty)
          const Center(
            child: Text(
              'No medicines added yet.\nTap the + button to add one.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _medicines.length,
              itemBuilder: (context, index) {
                final medicine = _medicines[index];
                final scheduledTime = DateTime.parse(medicine['scheduledTime']);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.medical_services, color: Colors.blue),
                    title: Text(medicine['name']),
                    subtitle: Text(
                      '${medicine['dosage']} - ${_formatTime(scheduledTime)}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteMedicine(medicine['id']),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
} 