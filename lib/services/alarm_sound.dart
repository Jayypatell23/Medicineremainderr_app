import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AlarmSound {
  static Future<void> ensureAlarmSoundExists() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final alarmSoundFile = File('${directory.path}/alarm.mp3');
      
      if (!await alarmSoundFile.exists()) {
        // Load the default alarm sound from assets
        final ByteData data = await rootBundle.load('assets/alarm.mp3');
        final List<int> bytes = data.buffer.asUint8List();
        await alarmSoundFile.writeAsBytes(bytes);
      }
    } catch (e) {
      print('Error ensuring alarm sound exists: $e');
    }
  }
} 