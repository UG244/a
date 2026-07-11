import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../database/db_helper.dart';
import '../models/product.dart';

class ProductService {
  final DbHelper _dbHelper = DbHelper();

  Future<int> createProduct(Product product) async {
    return await _dbHelper.insertProduct(product);
  }

  Future<List<Product>> getAllProducts() async {
    return await _dbHelper.getAllProducts();
  }

  Future<List<Product>> getActiveProducts() async {
    return await _dbHelper.getActiveProducts();
  }

  Future<Product?> getProductById(int id) async {
    return await _dbHelper.getProductById(id);
  }

  Future<int> updateProduct(Product product) async {
    return await _dbHelper.updateProduct(product);
  }

  Future<int> deleteProduct(int id) async {
    return await _dbHelper.deleteProduct(id);
  }

  Future<int> getTotalProducts() async {
    return await _dbHelper.getTotalProducts();
  }

  Future<int> getTotalStock() async {
    return await _dbHelper.getTotalStock();
  }

  Future<int> getLowStockCount({int threshold = 5}) async {
    return await _dbHelper.getLowStockCount(threshold);
  }

  Future<List<Product>> getRecentProducts({int limit = 3}) async {
    return await _dbHelper.getRecentProducts(limit);
  }

  Future<void> toggleProductVisibility(int productId, bool isActive) async {
    final product = await _dbHelper.getProductById(productId);
    if (product != null) {
      await _dbHelper.updateProduct(product.copyWith(isActive: isActive));
    }
  }

  Future<void> seedData() async {
    final products = await getAllProducts();
    if (products.isEmpty) {
      final mockProducts = [
        Product(
          name: 'Laptop ASUS ROG Zephyrus G14',
          description: 'Laptop gaming ringan dengan performa luar biasa, ditenagai AMD Ryzen 9 dan NVIDIA RTX 4060.',
          category: 'Laptop',
          price: 24500000,
          stock: 12,
          isActive: true,
        ),
        Product(
          name: 'iPhone 15 Pro 256GB',
          description: 'Smartphone titanium dengan chipset A17 Pro, kamera 48MP yang menakjubkan.',
          category: 'Smartphone',
          price: 20999000,
          stock: 25,
          isActive: true,
        ),
        Product(
          name: 'Sony WH-1000XM5',
          description: 'Headphone wireless dengan noise cancelling terbaik di kelasnya.',
          category: 'Audio',
          price: 5499000,
          stock: 18,
          isActive: true,
        ),
        Product(
          name: 'Logitech G Pro X Superlight',
          description: 'Mouse gaming ultra-ringan pilihan para pro player esports.',
          category: 'Gaming',
          price: 1950000,
          stock: 30,
          isActive: true,
        ),
        Product(
          name: 'Samsung Galaxy S24 Ultra',
          description: 'Smartphone premium dengan fitur Galaxy AI dan S Pen terintegrasi.',
          category: 'Smartphone',
          price: 21999000,
          stock: 15,
          isActive: true,
        ),
        Product(
          name: 'AirPods Pro Gen 2',
          description: 'TWS premium dari Apple dengan audio spasial dan ANC yang ditingkatkan.',
          category: 'Audio',
          price: 3999000,
          stock: 22,
          isActive: true,
        ),
      ];
      
      for (var product in mockProducts) {
        await createProduct(product);
      }
    }
  }

  Future<void> replaceWithFakeStoreData() async {
    // Delete all existing products first
    final existing = await getAllProducts();
    for (var p in existing) {
      if (p.id != null) {
        await deleteProduct(p.id!);
      }
    }
    
    // Fetch from FakeStoreAPI
    try {
      final response = await http.get(Uri.parse('https://fakestoreapi.com/products?limit=8'));
      if (response.statusCode == 200) {
        final List<dynamic> items = jsonDecode(response.body);
        for (var item in items) {
          String name = item['title'];
          String description = item['description'];
          String category = item['category'];
          // Convert USD to roughly IDR
          double price = (item['price'] as num) * 15000.0;
          String imageUrl = item['image'];
          
          String filename = 'fs_${item['id']}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          String? localPath = await _downloadImage(imageUrl, filename);
          
          Product product = Product(
            name: name,
            description: description,
            category: category.contains('clothing') ? 'Pakaian' : (category == 'electronics' ? 'Elektronik' : category),
            price: price,
            stock: 15,
            isActive: true,
            photoPath: localPath,
          );
          await createProduct(product);
        }
      }
    } catch (e) {
      print('Error fetching from FakeStoreAPI: $e');
    }
  }

  Future<String?> _downloadImage(String url, String filename) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(response.bodyBytes);
        return file.path;
      }
    } catch (e) {
      print('Failed to download image: $e');
    }
    return null;
  }
}