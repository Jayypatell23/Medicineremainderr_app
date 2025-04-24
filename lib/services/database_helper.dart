import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static SharedPreferences? _prefs;

  DatabaseHelper._init();

  Future<void> initialize() async {
    if (kIsWeb) {
      _prefs = await SharedPreferences.getInstance();
    } else {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _database = await _initDB('medicines.db');
    }
  }

  Future<Database> get database async {
    if (!kIsWeb) {
      if (_database != null) return _database!;
      _database = await _initDB('medicines.db');
      return _database!;
    } else {
      if (_prefs == null) {
        await initialize();
      }
      return _createWebDB();
    }
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE medicines(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        dosage TEXT NOT NULL,
        scheduledTime TEXT NOT NULL
      )
    ''');
  }

  Future<Database> _createWebDB() async {
    return await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {},
    );
  }

  Future<String> insertMedicine(Map<String, dynamic> medicine) async {
    if (!kIsWeb) {
      final db = await instance.database;
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      medicine['id'] = id;
      await db.insert('medicines', medicine);
      return id;
    } else {
      if (_prefs == null) {
        await initialize();
      }
      final medicines = await getAllMedicines();
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      medicine['id'] = id;
      medicines.add(medicine);
      await _prefs!.setString('medicines', jsonEncode(medicines));
      return id;
    }
  }

  Future<List<Map<String, dynamic>>> getAllMedicines() async {
    if (!kIsWeb) {
      final db = await instance.database;
      return await db.query('medicines');
    } else {
      if (_prefs == null) {
        await initialize();
      }
      final medicinesJson = _prefs!.getString('medicines') ?? '[]';
      return List<Map<String, dynamic>>.from(jsonDecode(medicinesJson));
    }
  }

  Future<int> deleteMedicine(String id) async {
    print('Attempting to delete medicine with ID: $id'); // Debug log
    if (!kIsWeb) {
      final db = await instance.database;
      final result = await db.delete(
        'medicines',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('SQLite delete result: $result'); // Debug log
      return result;
    } else {
      if (_prefs == null) {
        await initialize();
      }
      final medicines = await getAllMedicines();
      final initialLength = medicines.length;
      medicines.removeWhere((medicine) => medicine['id'] == id);
      final finalLength = medicines.length;
      await _prefs!.setString('medicines', jsonEncode(medicines));
      print('Web delete result: ${initialLength - finalLength}'); // Debug log
      return initialLength - finalLength;
    }
  }
} 