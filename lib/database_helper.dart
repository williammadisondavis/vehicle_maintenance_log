
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'vehicle_maintenance.db');

    _database = await openDatabase(
      path,
      version: 2,
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

        await _createServicesTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createServicesTable(db);
        }
      },
    );

    return _database!;
  }

  Future<void> _createServicesTable(Database db) async {
    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicle_id INTEGER NOT NULL,
        service_type TEXT NOT NULL,
        mileage INTEGER NOT NULL,
        cost REAL NOT NULL DEFAULT 0,
        service_date TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (vehicle_id)
          REFERENCES vehicles(id)
          ON DELETE CASCADE
      )
    ''');
  }

  Future<List<Map<String, Object?>>> getVehicles() async {
    final db = await database;
    return db.query('vehicles', orderBy: 'id DESC');
  }

  Future<int> addVehicle({
    required String make,
    required String model,
    required int year,
    required int mileage,
  }) async {
    final db = await database;

    return db.insert('vehicles', {
      'make': make,
      'model': model,
      'year': year,
      'mileage': mileage,
    });
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

  Future<List<Map<String, Object?>>> getServices() async {
    final db = await database;

    return db.rawQuery('''
      SELECT
        s.*,
        v.make,
        v.model,
        v.year
      FROM services s
      INNER JOIN vehicles v
        ON v.id = s.vehicle_id
      ORDER BY s.service_date DESC, s.id DESC
    ''');
  }

  Future<int> addService({
    required int vehicleId,
    required String serviceType,
    required int mileage,
    required double cost,
    required String serviceDate,
    required String notes,
  }) async {
    final db = await database;

    return db.insert('services', {
      'vehicle_id': vehicleId,
      'service_type': serviceType,
      'mileage': mileage,
      'cost': cost,
      'service_date': serviceDate,
      'notes': notes,
    });
  }

  Future<int> updateService({
    required int id,
    required int vehicleId,
    required String serviceType,
    required int mileage,
    required double cost,
    required String serviceDate,
    required String notes,
  }) async {
    final db = await database;

    return db.update(
      'services',
      {
        'vehicle_id': vehicleId,
        'service_type': serviceType,
        'mileage': mileage,
        'cost': cost,
        'service_date': serviceDate,
        'notes': notes,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteService(int id) async {
    final db = await database;

    return db.delete(
      'services',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getServiceCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM services',
    );

    return result.first['total'] as int;
  }

  Future<double> getTotalServiceCost() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(cost), 0) AS total FROM services',
    );

    return (result.first['total'] as num).toDouble();
  }
}
