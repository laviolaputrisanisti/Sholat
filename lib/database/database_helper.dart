
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance =
      DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('sholatku.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE prayers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            time TEXT NOT NULL,
            date TEXT NOT NULL,
            isCompleted INTEGER NOT NULL,
            status TEXT NOT NULL DEFAULT 'Tidak Hadir',
            note TEXT NOT NULL DEFAULT ''
          )
        ''');
        await db.execute('''
          CREATE TABLE schedules (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            time TEXT NOT NULL,
            date TEXT NOT NULL,
            UNIQUE(name, date)
          )
        ''');
        await db.execute('''
          CREATE TABLE accounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            passwordHash TEXT NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE prayers ADD COLUMN date TEXT NOT NULL DEFAULT ''"
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            "ALTER TABLE prayers ADD COLUMN status TEXT NOT NULL DEFAULT 'Tidak Hadir'",
          );
          await db.execute(
            "ALTER TABLE prayers ADD COLUMN note TEXT NOT NULL DEFAULT ''",
          );
          await db.execute('''
            CREATE TABLE schedules (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              time TEXT NOT NULL,
              date TEXT NOT NULL,
              UNIQUE(name, date)
            )
          ''');
          await db.execute(
            "UPDATE prayers SET status = 'Tepat Waktu' WHERE isCompleted = 1",
          );
        }
        if (oldVersion < 4) {
          await db.execute('''
            CREATE TABLE accounts (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              email TEXT NOT NULL UNIQUE,
              passwordHash TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  Future<Map<String, Object?>?> getAccountByEmail(String email) async {
    final db = await database;
    final results = await db.query(
      'accounts',
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );
    return results.firstOrNull;
  }

  Future<void> insertAccount({
    required String name,
    required String email,
    required String passwordHash,
  }) async {
    final db = await database;
    await db.insert(
      'accounts',
      {
        'name': name,
        'email': email,
        'passwordHash': passwordHash,
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> insertPrayer(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('prayers', data);
  }

  Future<List<Map<String, dynamic>>> getPrayers() async {
    final db = await database;
    return db.query('prayers', orderBy: 'date DESC, id DESC');
  }

  Future<int> updatePrayer(
    int id,
    Map<String, dynamic> data,
  ) async {
    final db = await database;

    return db.update(
      'prayers',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePrayer(int id) async {
    final db = await database;

    return db.delete(
      'prayers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getSchedules(String date) async {
    final db = await database;
    return db.query(
      'schedules',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'time ASC',
    );
  }

  Future<int> insertSchedule(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert('schedules', data);
  }

  Future<int> updateSchedule(int id, Map<String, dynamic> data) async {
    final db = await database;
    return db.update(
      'schedules',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSchedule(int id) async {
    final db = await database;
    return db.delete(
      'schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
