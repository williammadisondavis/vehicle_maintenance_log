
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'vehicle_maintenance.db');

    _database = await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE vehicles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            make TEXT NOT NULL,
            model TEXT NOT NULL,
            year INTEGER NOT NULL,
            mileage INTEGER NOT NULL
          )
        ''');
      },
    );

    return _database!;
  }

  Future<List<Map<String, Object?>>> getVehicles() async {
    final db = await database;

    return db.query(
      'vehicles',
      orderBy: 'id DESC',
    );
  }

  Future<int> addVehicle({
    required String make,
    required String model,
    required int year,
    required int mileage,
  }) async {
    final db = await database;

    return db.insert(
      'vehicles',
      {
        'make': make,
        'model': model,
        'year': year,
        'mileage': mileage,
      },
    );
  }

  Future<int> updateVehicle({
    required int id,
    required String make,
    required String model,
    required int year,
    required int mileage,
  }) async {
    final db = await database;

    return db.update(
      'vehicles',
      {
        'make': make,
        'model': model,
        'year': year,
        'mileage': mileage,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteVehicle(int id) async {
    final db = await database;

    return db.delete(
      'vehicles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
