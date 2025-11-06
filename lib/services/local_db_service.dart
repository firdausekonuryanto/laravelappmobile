import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDBService {
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'offline_pos.db');
    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY,
        category_id INTEGER,
        supplier_id INTEGER,
        name TEXT,
        sku TEXT,
        price REAL,
        cost_price REAL,
        stock INTEGER,
        unit TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE product_categories (
        id INTEGER PRIMARY KEY,
        name TEXT,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY,
        name TEXT,
        contact TEXT,
        address TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY,
        name TEXT,
        phone TEXT,
        email TEXT,
        address TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE payment_methods (
        id INTEGER PRIMARY KEY,
        name TEXT,
        description TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions_pending (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data TEXT,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  Future<void> clearTables() async {
    final db = await database;
    for (final table in [
      'products',
      'product_categories',
      'suppliers',
      'customers',
      'payment_methods',
    ]) {
      await db.delete(table);
    }
  }

  Future<void> saveSyncData(Map<String, dynamic> data) async {
    final db = await database;

    await clearTables();

    final tables = {
      'products': List<Map<String, dynamic>>.from(data['products'] ?? []),
      'product_categories': List<Map<String, dynamic>>.from(
        data['product_categories'] ?? [],
      ),
      'suppliers': List<Map<String, dynamic>>.from(data['suppliers'] ?? []),
      'customers': List<Map<String, dynamic>>.from(data['customers'] ?? []),

      'payment_methods': List<Map<String, dynamic>>.from(
        data['paymentMethods'] ?? [],
      ),
    };

    for (final entry in tables.entries) {
      final batch = db.batch();

      for (final row in entry.value) {
        batch.insert(
          entry.key,
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      debugPrint(
        '✅ Tersimpan ${entry.value.length} data ke tabel ${entry.key}',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database;
    return await db.query('products');
  }

  Future<List<Map<String, dynamic>>> getCustomers() async {
    final db = await database;
    return await db.query('customers');
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    return [
      {'id': 1, 'name': 'Administrator Toko'},
    ];
  }

  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    final db = await database;
    return await db.query('payment_methods');
  }

  Future<void> saveOfflineTransaction(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('transactions_pending', {
      'data': jsonEncode(data),
      'synced': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingTransactions() async {
    final db = await database;
    return await db.query('transactions_pending', where: 'synced = 0');
  }

  Future<void> markTransactionSynced(int id) async {
    final db = await database;
    await db.update(
      'transactions_pending',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> printTableCount() async {
    final db = await database;
    for (final table in [
      'products',
      'customers',
      'payment_methods',
      'transactions_pending',
    ]) {
      final count = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM $table'),
      );
      print('[$table] -> $count rows');
    }
  }
}
