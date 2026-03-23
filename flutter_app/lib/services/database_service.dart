import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'db_init_stub.dart' if (dart.library.io) 'db_init_io.dart';
import 'mock_database.dart';
import '../models/user_model.dart';
import '../models/vital_model.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (kIsWeb) return MockDatabase();
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    await initDesktopDatabase();
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vitalsense.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            uid TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            dateOfBirth TEXT NOT NULL,
            bloodGroup TEXT NOT NULL,
            heightCm REAL NOT NULL,
            weightKg REAL NOT NULL,
            isGymPerson INTEGER DEFAULT 0,
            isAthletic INTEGER DEFAULT 0,
            isFemale INTEGER DEFAULT 0,
            role TEXT NOT NULL DEFAULT 'patient',
            doctorId TEXT,
            emergencyContacts TEXT,
            familyMemberIds TEXT,
            profileImageUrl TEXT,
            createdAt TEXT NOT NULL,
            lastPeriodDate TEXT,
            periodCycleDays INTEGER
          )
        ''');

        await db.execute('''
          CREATE TABLE vitals (
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            heartRate REAL NOT NULL,
            spo2 REAL NOT NULL,
            temperature REAL NOT NULL,
            ecgValue REAL,
            systolicBP REAL,
            diastolicBP REAL,
            phiScore REAL NOT NULL,
            stressLevel REAL,
            hrv REAL,
            source TEXT,
            periodPhase TEXT,
            daysUntilPeriod INTEGER,
            isSynced INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE alerts (
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            title TEXT NOT NULL,
            message TEXT NOT NULL,
            severity TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            isRead INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE water_intake (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            amountMl INTEGER NOT NULL DEFAULT 250
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE vitals ADD COLUMN periodPhase TEXT');
            await db.execute('ALTER TABLE vitals ADD COLUMN daysUntilPeriod INTEGER');
          } catch (e) {
            // Column may already exist if user previously ran version 1 with updated schema
          }
        }
      },
    );
  }

  // ── User CRUD ─────────────────────────────────────────────────────
  Future<void> insertUser(UserModel user) async {
    final db = await database;
    await db.insert('users', user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<UserModel?> getUser(String uid) async {
    final db = await database;
    final maps = await db.query('users', where: 'uid = ?', whereArgs: [uid]);
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  Future<List<UserModel>> getAllUsers() async {
    final db = await database;
    final maps = await db.query('users');
    return maps.map((m) => UserModel.fromMap(m)).toList();
  }

  Future<void> deleteUser(String uid) async {
    final db = await database;
    await db.delete('users', where: 'uid = ?', whereArgs: [uid]);
  }

  // ── Vitals CRUD ───────────────────────────────────────────────────
  Future<void> insertVital(VitalReading reading) async {
    final db = await database;
    await db.insert('vitals', reading.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<VitalReading>> getVitals(String userId, {int limit = 50}) async {
    final db = await database;
    final maps = await db.query('vitals',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'timestamp DESC',
        limit: limit);
    return maps.map((m) => VitalReading.fromMap(m)).toList();
  }

  // ── Alert CRUD ────────────────────────────────────────────────────
  Future<void> insertAlert(HealthAlert alert) async {
    final db = await database;
    await db.insert('alerts', alert.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<HealthAlert>> getAlerts(String userId) async {
    final db = await database;
    final maps = await db.query('alerts',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'timestamp DESC');
    return maps.map((m) => HealthAlert.fromMap(m)).toList();
  }

  Future<void> markAlertRead(String alertId) async {
    final db = await database;
    await db.update('alerts', {'isRead': 1},
        where: 'id = ?', whereArgs: [alertId]);
  }

  // ── Water Intake ──────────────────────────────────────────────────
  Future<void> addWaterIntake(String userId, int ml) async {
    final db = await database;
    await db.insert('water_intake', {
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
      'amountMl': ml,
    });
  }

  Future<int> getTodayWaterIntake(String userId) async {
    final db = await database;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day).toIso8601String();
    final end = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();
    final result = await db.rawQuery(
      'SELECT SUM(amountMl) as total FROM water_intake WHERE userId = ? AND timestamp BETWEEN ? AND ?',
      [userId, start, end],
    );
    return (result.first['total'] as int?) ?? 0;
  }
}

final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());
