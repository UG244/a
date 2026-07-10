import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';

class DbHelper {
  static final DbHelper _instance = DbHelper._internal();
  factory DbHelper() => _instance;
  DbHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bluemart.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT DEFAULT '',
        category TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER NOT NULL,
        photoPath TEXT,
        supplierId INTEGER,
        isActive INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE promotions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        subtitle TEXT DEFAULT '',
        badge TEXT DEFAULT '',
        icon TEXT DEFAULT 'flash_on',
        color1 INTEGER DEFAULT 0xFF1E3A8A,
        color2 INTEGER DEFAULT 0xFF3B82F6,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE promo_codes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        discountPercent REAL DEFAULT 0,
        minPurchase REAL DEFAULT 0,
        freeShipping INTEGER NOT NULL DEFAULT 0,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        buyerUsername TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        status TEXT NOT NULL DEFAULT 'completed',
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transactionId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        productName TEXT NOT NULL,
        unitPrice REAL NOT NULL,
        quantity INTEGER NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (transactionId) REFERENCES transactions(id),
        FOREIGN KEY (productId) REFERENCES products(id)
      )
    ''');

    await _seedDefaults(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute(
          'ALTER TABLE products ADD COLUMN description TEXT DEFAULT ""',
        );
      } catch (_) {}
    }
    if (oldVersion < 3) {
      // Create tables that didn't exist before v3
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS promotions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            subtitle TEXT DEFAULT '',
            badge TEXT DEFAULT '',
            icon TEXT DEFAULT 'flash_on',
            color1 INTEGER DEFAULT 0xFF1E3A8A,
            color2 INTEGER DEFAULT 0xFF3B82F6,
            isActive INTEGER NOT NULL DEFAULT 1,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');
      } catch (_) {}
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS promo_codes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT NOT NULL UNIQUE,
            discountPercent REAL DEFAULT 0,
            minPurchase REAL DEFAULT 0,
            freeShipping INTEGER NOT NULL DEFAULT 0,
            isActive INTEGER NOT NULL DEFAULT 1,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');
      } catch (_) {}
      await _seedDefaults(db);
    }
  }

  Future<void> _seedDefaults(Database db) async {
    final promoCount =
        (await db.rawQuery('SELECT COUNT(*) as c FROM promotions')).first['c']
            as int;
    if (promoCount == 0) {
      final now = DateTime.now().toIso8601String();
      await db.insert('promotions', {
        'title': 'Flash Sale Akhir Pekan',
        'subtitle': 'Diskon hingga 50%',
        'badge': 'PROMO HARI INI',
        'icon': 'flash_on',
        'color1': 0xFF1E3A8A,
        'color2': 0xFF3B82F6,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
      });
      await db.insert('promotions', {
        'title': 'Gadget Terbaru 2026',
        'subtitle': 'Teknologi terkini untuk Anda',
        'badge': 'NEW ARRIVAL',
        'icon': 'devices',
        'color1': 0xFF0EA5E9,
        'color2': 0xFF06B6D4,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
      });
      await db.insert('promotions', {
        'title': 'Gratis Ongkir',
        'subtitle': 'Min. belanja Rp200.000',
        'badge': 'FREE SHIPPING',
        'icon': 'local_shipping',
        'color1': 0xFF8B5CF6,
        'color2': 0xFFA78BFA,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
      });
    }

    final codeCount =
        (await db.rawQuery('SELECT COUNT(*) as c FROM promo_codes')).first['c']
            as int;
    if (codeCount == 0) {
      final now = DateTime.now().toIso8601String();
      await db.insert('promo_codes', {
        'code': 'FLASH50',
        'discountPercent': 0.50,
        'minPurchase': 500000,
        'freeShipping': 0,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
      });
      await db.insert('promo_codes', {
        'code': 'FREESHIP',
        'discountPercent': 0,
        'minPurchase': 200000,
        'freeShipping': 1,
        'isActive': 1,
        'createdAt': now,
        'updatedAt': now,
      });
    }
  }

  // ==================== PRODUCT CRUD ====================

  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getAllProducts() async {
    final db = await database;
    final maps = await db.query('products', orderBy: 'createdAt DESC');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> getActiveProducts() async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final db = await database;
    final maps = await db.query('products', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteProductCascade(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(
        'transaction_items',
        where: 'productId = ?',
        whereArgs: [id],
      );
      await txn.delete('products', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'name LIKE ? OR category LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<int> getTotalProducts() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM products');
    return result.first['count'] as int;
  }

  Future<int> getTotalStock() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(stock), 0) as total FROM products',
    );
    return (result.first['total'] as num).toInt();
  }

  Future<int> getLowStockCount(int threshold) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM products WHERE stock < ? AND stock > 0',
      [threshold],
    );
    return result.first['count'] as int;
  }

  Future<List<Product>> getRecentProducts(int limit) async {
    final db = await database;
    final maps = await db.query(
      'products',
      orderBy: 'createdAt DESC',
      limit: limit,
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  // ==================== TRANSACTION METHODS ====================

  Future<int> insertTransaction(Map<String, dynamic> transactionData) async {
    final db = await database;
    return await db.insert('transactions', transactionData);
  }

  Future<void> insertTransactionItem(Map<String, dynamic> itemData) async {
    final db = await database;
    await db.insert('transaction_items', itemData);
  }

  Future<List<Map<String, dynamic>>> getUserTransactions(
    String username,
  ) async {
    final db = await database;
    return await db.query(
      'transactions',
      where: 'buyerUsername = ?',
      whereArgs: [username],
      orderBy: 'createdAt DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await database;
    return await db.query('transactions', orderBy: 'createdAt DESC');
  }

  Future<List<Map<String, dynamic>>> getTransactionItems(
    int transactionId,
  ) async {
    final db = await database;
    return await db.query(
      'transaction_items',
      where: 'transactionId = ?',
      whereArgs: [transactionId],
    );
  }

  Future<double> getTotalRevenue() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(totalAmount), 0) as total FROM transactions',
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<List<Product>> getLowStockProducts({int threshold = 5}) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'stock > 0 AND stock < ?',
      whereArgs: [threshold],
      orderBy: 'stock ASC',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  // ==================== PROMOTIONS CRUD ====================

  Future<List<Map<String, dynamic>>> getActivePromotions() async {
    final db = await database;
    return await db.query(
      'promotions',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'createdAt DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllPromotions() async {
    final db = await database;
    return await db.query('promotions', orderBy: 'createdAt DESC');
  }

  Future<int> insertPromotion(Map<String, dynamic> data) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    data['createdAt'] = now;
    data['updatedAt'] = now;
    if (!data.containsKey('isActive')) {
      data['isActive'] = 1;
    }
    return await db.insert('promotions', data);
  }

  Future<int> updatePromotion(int id, Map<String, dynamic> data) async {
    final db = await database;
    data['updatedAt'] = DateTime.now().toIso8601String();
    return await db.update(
      'promotions',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePromotion(int id) async {
    final db = await database;
    return await db.delete('promotions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> togglePromotion(int id, int isActive) async {
    final db = await database;
    return await db.update(
      'promotions',
      {'isActive': isActive, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== PROMO CODES CRUD ====================

  Future<List<Map<String, dynamic>>> getActivePromoCodes() async {
    final db = await database;
    return await db.query(
      'promo_codes',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'createdAt DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllPromoCodes() async {
    final db = await database;
    return await db.query('promo_codes', orderBy: 'createdAt DESC');
  }

  Future<Map<String, dynamic>?> getPromoCodeByCode(String code) async {
    final db = await database;
    final results = await db.query(
      'promo_codes',
      where: 'code = ? AND isActive = ?',
      whereArgs: [code.toUpperCase(), 1],
    );
    if (results.isEmpty) return null;
    return results.first;
  }

  Future<int> insertPromoCode(Map<String, dynamic> data) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    data['createdAt'] = now;
    data['updatedAt'] = now;
    if (data['code'] != null) {
      data['code'] = (data['code'] as String).toUpperCase();
    }
    if (!data.containsKey('isActive')) {
      data['isActive'] = 1;
    }
    return await db.insert('promo_codes', data);
  }

  Future<int> updatePromoCode(int id, Map<String, dynamic> data) async {
    final db = await database;
    data['updatedAt'] = DateTime.now().toIso8601String();
    if (data['code'] != null) {
      data['code'] = (data['code'] as String).toUpperCase();
    }
    return await db.update(
      'promo_codes',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePromoCode(int id) async {
    final db = await database;
    return await db.delete('promo_codes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> togglePromoCode(int id, int isActive) async {
    final db = await database;
    return await db.update(
      'promo_codes',
      {'isActive': isActive, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<Database> get db => database;
}
