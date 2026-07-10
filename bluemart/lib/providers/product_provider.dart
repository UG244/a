import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../services/product_service.dart';

/// Centralized product state with ChangeNotifier for Provider pattern.
/// Used across Home, Favorites, and Detail screens for consistent state.
class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = false;
  String? _error;

  List<Product> get products => List.unmodifiable(_products);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all active products from local DB.
  Future<void> loadProducts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _products = await _productService.getActiveProducts();
    } catch (e) {
      _error = 'Gagal memuat produk: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  /// Load a single product by ID.
  Future<Product?> getProductById(int id) async {
    try {
      return await _productService.getProductById(id);
    } catch (_) {
      return null;
    }
  }

  /// Search products locally with debounce handled by caller.
  Future<List<Product>> searchProducts(String query) async {
    try {
      final db = await _productService.getAllProducts();
      if (query.isEmpty) return _products;
      final lower = query.toLowerCase();
      return db.where((p) {
        return p.name.toLowerCase().contains(lower) ||
            p.category.toLowerCase().contains(lower);
      }).toList();
    } catch (_) {
      return [];
    }
  }

  /// Re-fetch products (e.g., after admin changes).
  Future<void> refresh() => loadProducts();

  /// Clear cached data (on logout).
  void clear() {
    _products = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}
