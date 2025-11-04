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
    await db.delete('products');
    await db.delete('product_categories');
    await db.delete('suppliers');
    await db.delete('customers');
    await db.delete('payment_methods');
  }

  Future<void> saveSyncData(Map<String, dynamic> data) async {
    final db = await database;
    await clearTables();

    for (final table in [
      'products',
      'product_categories',
      'suppliers',
      'customers',
      'payment_methods',
    ]) {
      final list = List<Map<String, dynamic>>.from(data[table] ?? []);
      for (final row in list) {
        await db.insert(
          table,
          row,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database;
    return await db.query('products');
  }

  Future<void> saveOfflineTransaction(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('transactions_pending', {
      'data': data.toString(),
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
}
