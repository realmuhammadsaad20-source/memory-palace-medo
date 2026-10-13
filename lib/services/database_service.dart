import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/palace.dart';
import '../models/station.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('memory_palace_medo.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
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
        FOREIGN KEY (palaceId) REFERENCES palaces (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<List<Palace>> getPalaces() async {
    final db = await database;
    final result = await db.query('palaces', orderBy: 'createdAt DESC');
    return result.map((json) => Palace.fromMap(json)).toList();
  }

  Future<int> insertPalace(Palace palace) async {
    final db = await database;
    return await db.insert('palaces', palace.toMap());
  }

  Future<int> deletePalace(String id) async {
    final db = await database;
    return await db.delete('palaces', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Station>> getStations(String palaceId) async {
    final db = await database;
    final result = await db.query(
      'stations',
      where: 'palaceId = ?',
      whereArgs: [palaceId],
      orderBy: 'timestampMs ASC',
    );
    return result.map((json) => Station.fromMap(json)).toList();
  }

  Future<int> getStationCount(String palaceId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM stations WHERE palaceId = ?',
      [palaceId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> insertStation(Station station) async {
    final db = await database;
    return await db.insert('stations', station.toMap());
  }

  Future<int> deleteStation(String id) async {
    final db = await database;
    return await db.delete('stations', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateStation(Station station) async {
    final db = await database;
    return await db.update(
      'stations',
      station.toMap(),
      where: 'id = ?',
      whereArgs: [station.id],
    );
  }
}
