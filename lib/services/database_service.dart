import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/palace.dart';
import '../models/station.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'medo_memory_palace.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE palaces (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            videoPath TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE stations (
            id TEXT PRIMARY KEY,
            palaceId TEXT NOT NULL,
            title TEXT NOT NULL,
            note TEXT,
            timestampMs INTEGER NOT NULL,
            xRatio REAL NOT NULL,
            yRatio REAL NOT NULL,
            colorValue INTEGER NOT NULL,
            linkUrl TEXT,
            imageUrl TEXT,
            FOREIGN KEY (palaceId) REFERENCES palaces (id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  // --- دوال القصور (Palaces) ---

  Future<int> insertPalace(Palace palace) async {
    final db = await database;
    return await db.insert('palaces', palace.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Palace>> getPalaces() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('palaces', orderBy: 'createdAt DESC');
    return maps.map((m) => Palace.fromMap(m)).toList();
  }

  Future<void> deletePalace(String id) async {
    final db = await database;
    // جلب مسار الفيديو لحذفه من التخزين لتوفير المساحة
    final List<Map<String, dynamic>> maps =
        await db.query('palaces', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      final videoPath = maps.first['videoPath'] as String;
      final file = File(videoPath);
      if (await file.exists()) {
        await file.delete();
      }
    }

    await db.delete('stations', where: 'palaceId = ?', whereArgs: [id]);
    await db.delete('palaces', where: 'id = ?', whereArgs: [id]);
  }

  // --- دوال المحطات (Stations) ---

  Future<int> insertStation(Station station) async {
    final db = await database;
    return await db.insert('stations', station.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Station>> getStationsForPalace(String palaceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stations',
      where: 'palaceId = ?',
      whereArgs: [palaceId],
      orderBy: 'timestampMs ASC',
    );
    return maps.map((m) => Station.fromMap(m)).toList();
  }

  Future<int> deleteStation(String id) async {
    final db = await database;
    return await db.delete('stations', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateStation(Station station) async {
    final db = await database;
    return await db.update('stations', station.toMap(),
        where: 'id = ?', whereArgs: [station.id]);
  }
}
