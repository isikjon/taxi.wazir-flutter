import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'taxi_admin.db';
  static const int _databaseVersion = 1;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String path;
    
    if (kIsWeb) {
      path = _databaseName;
    } else {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      path = join(documentsDirectory.path, _databaseName);
    }
    
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE drivers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        first_name TEXT NOT NULL,
        last_name TEXT NOT NULL,
        phone TEXT UNIQUE NOT NULL,
        car_model TEXT NOT NULL,
        car_number TEXT UNIQUE NOT NULL,
        balance REAL DEFAULT 0.0,
        tariff TEXT DEFAULT 'Эконом',
        taxipark_id INTEGER NOT NULL,
        is_active BOOLEAN DEFAULT 1,
        is_online BOOLEAN DEFAULT 0,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        from_address TEXT NOT NULL,
        to_address TEXT NOT NULL,
        from_lat REAL NOT NULL,
        from_lng REAL NOT NULL,
        to_lat REAL NOT NULL,
        to_lng REAL NOT NULL,
        status TEXT NOT NULL,
        price REAL NOT NULL,
        client_phone TEXT,
        client_name TEXT,
        driver_id INTEGER,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
        accepted_at DATETIME,
        completed_at DATETIME,
        FOREIGN KEY (driver_id) REFERENCES drivers (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE taxiparks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        address TEXT,
        phone TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await _insertSampleData(db);
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < newVersion) {
    }
  }

  static Future<void> _insertSampleData(Database db) async {
    await db.insert('taxiparks', {
      'id': 1,
      'name': 'Такси Парк 1',
      'address': 'Бишкек, ул. Чуй 1',
      'phone': '+996 555 123 456',
    });

    await db.insert('drivers', {
      'id': 1,
      'first_name': 'Иван',
      'last_name': 'Иванов',
      'phone': '0700123456',
      'car_model': 'Toyota Camry',
      'car_number': 'А123БВ777',
      'balance': 2500.0,
      'tariff': 'Комфорт',
      'taxipark_id': 1,
      'is_active': 1,
      'is_online': 0,
    });

    await db.insert('orders', {
      'id': 1,
      'from_address': 'Бишкек, ул. Чуй 1',
      'to_address': 'Бишкек, ул. Манаса 10',
      'from_lat': 42.8746,
      'from_lng': 74.5698,
      'to_lat': 42.8756,
      'to_lng': 74.5708,
      'status': 'pending',
      'price': 150.0,
      'client_phone': '+996 555 111 222',
      'client_name': 'Айбек',
      'driver_id': 1,
    });
  }

  static Future<List<Map<String, dynamic>>> getDrivers() async {
    final db = await database;
    return await db.query('drivers');
  }

  static Future<Map<String, dynamic>?> getDriverByPhone(String phone) async {
    final db = await database;
    final results = await db.query(
      'drivers',
      where: 'phone = ?',
      whereArgs: [phone],
    );
    return results.isNotEmpty ? results.first : null;
  }

  static Future<List<Map<String, dynamic>>> getOrders() async {
    final db = await database;
    return await db.query('orders', orderBy: 'created_at DESC');
  }

  static Future<int> updateDriverStatus(int driverId, bool isOnline) async {
    final db = await database;
    return await db.update(
      'drivers',
      {'is_online': isOnline ? 1 : 0},
      where: 'id = ?',
      whereArgs: [driverId],
    );
  }

  static Future<int> updateOrderStatus(int orderId, String status) async {
    final db = await database;
    Map<String, dynamic> data = {'status': status};
    
    if (status == 'accepted') {
      data['accepted_at'] = DateTime.now().toIso8601String();
    } else if (status == 'completed') {
      data['completed_at'] = DateTime.now().toIso8601String();
    }
    
    return await db.update(
      'orders',
      data,
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // Очистить все данные из базы данных
  static Future<void> clearAllData() async {
    try {
      final db = await database;
      
      // Очищаем все таблицы
      await db.delete('orders');
      await db.delete('drivers');
      await db.delete('taxiparks');
      
      print('✅ Database cleared successfully');
    } catch (e) {
      print('❌ Error clearing database: $e');
    }
  }

  // Закрыть соединение с базой данных
  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      print('✅ Database connection closed');
    }
  }
}
