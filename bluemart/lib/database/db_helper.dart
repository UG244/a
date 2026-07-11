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

    await db.execute('''
      CREATE TABLE IF NOT EXISTS coupons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        discount TEXT NOT NULL,
        discountPercent REAL DEFAULT 0,
        minPurchase REAL NOT NULL,
        freeShipping INTEGER NOT NULL DEFAULT 0,
        expiry TEXT NOT NULL,
        uses INTEGER DEFAULT 0,
        maxUses INTEGER DEFAULT 100,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add description column if upgrading from v1
      try {
        await db.execute(
          'ALTER TABLE products ADD COLUMN description TEXT DEFAULT ""',
        );
      } catch (_) {
        // Column might already exist
      }
    }
    if (oldVersion < 3) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS coupons (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            code TEXT NOT NULL UNIQUE,
            discount TEXT NOT NULL,
            discountPercent REAL DEFAULT 0,
            minPurchase REAL NOT NULL,
            freeShipping INTEGER NOT NULL DEFAULT 0,
            expiry TEXT NOT NULL,
            uses INTEGER DEFAULT 0,
            maxUses INTEGER DEFAULT 100,
            isActive INTEGER NOT NULL DEFAULT 1,
            createdAt TEXT NOT NULL
          )
        ''');
      } catch (_) {}
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

  // Hapus produk beserta item transaksi terkait
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

  // Cari produk berdasarkan nama atau kategori
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

  Future<int> updateTransactionStatus(int transactionId, String status) async {
    final db = await database;
    return await db.update(
      'transactions',
      {'status': status},
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  // Mendapatkan produk dengan stok paling sedikit
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

  // ==================== COUPON METHODS ====================

  Future<void> _ensureCouponsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS coupons (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        discount TEXT NOT NULL,
        discountPercent REAL DEFAULT 0,
        minPurchase REAL NOT NULL,
        freeShipping INTEGER NOT NULL DEFAULT 0,
        expiry TEXT NOT NULL,
        uses INTEGER DEFAULT 0,
        maxUses INTEGER DEFAULT 100,
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<void> _insertDefaultCoupons(Database db) async {
    final now = DateTime.now().toIso8601String();
    final defaults = [
      {
        'code': 'HEMAT10',
        'discount': '10%',
        'discountPercent': 0.10,
        'minPurchase': 100000.0,
        'freeShipping': 0,
        'expiry': '31 Des 2026',
        'uses': 45,
        'maxUses': 100,
        'isActive': 1,
        'createdAt': now,
      },
      {
        'code': 'BARU20',
        'discount': '20%',
        'discountPercent': 0.20,
        'minPurchase': 200000.0,
        'freeShipping': 0,
        'expiry': '30 Nov 2026',
        'uses': 12,
        'maxUses': 50,
        'isActive': 1,
        'createdAt': now,
      },
      {
        'code': 'GRATISONGKIR',
        'discount': 'Gratis Ongkir',
        'discountPercent': 0.0,
        'minPurchase': 150000.0,
        'freeShipping': 1,
        'expiry': '31 Des 2026',
        'uses': 78,
        'maxUses': 200,
        'isActive': 1,
        'createdAt': now,
      },
      {
        'code': 'FLASH50',
        'discount': '50%',
        'discountPercent': 0.50,
        'minPurchase': 500000.0,
        'freeShipping': 0,
        'expiry': '31 Des 2026',
        'uses': 30,
        'maxUses': 50,
        'isActive': 1,
        'createdAt': now,
      },
      {
        'code': 'FREESHIP',
        'discount': 'Gratis Ongkir',
        'discountPercent': 0.0,
        'minPurchase': 200000.0,
        'freeShipping': 1,
        'expiry': '31 Des 2026',
        'uses': 10,
        'maxUses': 100,
        'isActive': 1,
        'createdAt': now,
      },
    ];
    for (var coupon in defaults) {
      await db.insert('coupons', coupon, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<List<Map<String, dynamic>>> getAllCoupons() async {
    final db = await database;
    await _ensureCouponsTable(db);
    final maps = await db.query('coupons', orderBy: 'id ASC');
    if (maps.isEmpty) {
      await _insertDefaultCoupons(db);
      return await db.query('coupons', orderBy: 'id ASC');
    }
    return maps;
  }

  Future<List<Map<String, dynamic>>> getActiveCoupons() async {
    final db = await database;
    await _ensureCouponsTable(db);
    final maps = await db.query(
      'coupons',
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'id ASC',
    );
    if (maps.isEmpty) {
      final all = await db.query('coupons');
      if (all.isEmpty) {
        await _insertDefaultCoupons(db);
        return await db.query(
          'coupons',
          where: 'isActive = ?',
          whereArgs: [1],
          orderBy: 'id ASC',
        );
      }
    }
    return maps;
  }

  Future<int> insertCoupon(Map<String, dynamic> couponData) async {
    final db = await database;
    await _ensureCouponsTable(db);
    return await db.insert(
      'coupons',
      couponData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateCouponStatus(String code, bool isActive) async {
    final db = await database;
    await _ensureCouponsTable(db);
    return await db.update(
      'coupons',
      {'isActive': isActive ? 1 : 0},
      where: 'code = ?',
      whereArgs: [code],
    );
  }

  Future<int> deleteCoupon(String code) async {
    final db = await database;
    await _ensureCouponsTable(db);
    return await db.delete('coupons', where: 'code = ?', whereArgs: [code]);
  }

  Future<Database> get db => database;
}
