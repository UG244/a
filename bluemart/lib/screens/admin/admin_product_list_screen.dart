import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/product_card.dart';

class AdminProductListScreen extends StatefulWidget {
  const AdminProductListScreen({super.key});

  @override
  State<AdminProductListScreen> createState() => _AdminProductListScreenState();
}

class _AdminProductListScreenState extends State<AdminProductListScreen> {
  final _productService = ProductService();
  final _authService = AuthService();
  final _searchController = TextEditingController();
  List<Product> _products = [];
  bool _isLoading = true;
  String _filter = 'all'; // 'all', 'active', 'draft'
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _checkAccess();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _checkAccess() async {
    final isAdmin = await _authService.isAdmin();
    if (!isAdmin && mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/user-home',
        (route) => false,
      );
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final products = await _productService.getAllProducts();
    if (mounted) {
      setState(() {
        _products = products;
        _isLoading = false;
      });
    }
  }

  List<Product> get _filteredProducts {
    var result = _products;
    if (_filter == 'active') {
      result = result.where((p) => p.isActive).toList();
    } else if (_filter == 'draft') {
      result = result.where((p) => !p.isActive).toList();
    }
    if (_searchQuery.isNotEmpty) {
      result = result
          .where(
            (p) =>
                p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                p.category.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
    return result;
  }

  Future<void> _deleteProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Apakah Anda yakin ingin menghapus "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && product.id != null) {
      await _productService.deleteProduct(product.id!);
      // Sync delete ke Firestore
      try {
        final firestore = FirestoreService();
        await firestore.init();
        await firestore.deleteProduct(product.id!);
      } catch (_) {}
      _loadProducts();
    }
  }

  Future<void> _toggleVisibility(Product product) async {
    if (product.id != null) {
      final newStatus = !product.isActive;
      await _productService.toggleProductVisibility(product.id!, newStatus);
      // Sync toggle ke Firestore
      try {
        final firestore = FirestoreService();
        await firestore.init();
        await firestore.pushProduct(product.copyWith(isActive: newStatus));
      } catch (_) {}
      _loadProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Produk')),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildFilterChip('Semua', 'all'),
                const SizedBox(width: 8),
                _buildFilterChip('Aktif', 'active'),
                const SizedBox(width: 8),
                _buildFilterChip('Nonaktif', 'draft'),
                const Spacer(),
                Text(
                  '${_filteredProducts.length} produk',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),

          // Product list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadProducts,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        return Dismissible(
                          key: Key(product.id.toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.red,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          confirmDismiss: (_) async {
                            await _deleteProduct(product);
                            return false;
                          },
                          child: ProductCard(
                            product: product,
                            showActiveToggle: true,
                            onTap: () async {
                              final result = await Navigator.pushNamed(
                                context,
                                '/admin-product-form',
                                arguments: product,
                              );
                              if (result == true) _loadProducts();
                            },
                            onActiveToggle: (_) => _toggleVisibility(product),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            '/admin-product-form',
            arguments: null,
          );
          if (result == true) _loadProducts();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF0F172A),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: const Color(0xFF1E3A8A),
      checkmarkColor: Colors.white,
      onSelected: (selected) {
        setState(() => _filter = value);
      },
    );
  }

  Widget _buildEmptyState() {
    final hasFilter = _filter != 'all' || _searchQuery.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilter ? Icons.search_off : Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            hasFilter ? 'Produk tidak ditemukan' : 'Belum ada produk',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hasFilter
                ? 'Coba ubah filter atau kata kunci pencarian'
                : 'Tambahkan produk pertama Anda',
            style: TextStyle(color: Colors.grey[500]),
          ),
          if (!hasFilter) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  '/admin-product-form',
                  arguments: null,
                );
                if (result == true) _loadProducts();
              },
              icon: const Icon(Icons.add),
              label: const Text('Tambah Produk'),
            ),
          ],
        ],
      ),
    );
  }
}
