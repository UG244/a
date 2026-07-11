import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../models/cart_item.dart';
import '../../services/product_service.dart';
import '../../services/cart_service.dart';

class UserFavoriteScreen extends StatefulWidget {
  const UserFavoriteScreen({super.key});

  @override
  State<UserFavoriteScreen> createState() => _UserFavoriteScreenState();
}

class _UserFavoriteScreenState extends State<UserFavoriteScreen> {
  final _productService = ProductService();
  List<Product> _favoriteProducts = [];
  bool _isLoading = true;

  void _addToCart(Product product) {
    final cart = context.read<CartService>();
    final success = cart.addItem(
      CartItem(
        productId: product.id!,
        productName: product.name,
        unitPrice: product.price,
        quantity: 1,
        photoPath: product.photoPath,
      ),
      product.stock,
    );
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('${product.name} added to cart'),
              ],
            ),
            backgroundColor: const Color(0xFF22C55E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock not available'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _directCheckout(Product product) {
    final cart = context.read<CartService>();
    final success = cart.addItem(
      CartItem(
        productId: product.id!,
        productName: product.name,
        unitPrice: product.price,
        quantity: 1,
        photoPath: product.photoPath,
      ),
      product.stock,
    );
    if (mounted) {
      if (success) {
        Navigator.pushNamed(context, '/user-checkout');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock not available'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    final allProducts = await _productService.getActiveProducts();
    if (mounted) {
      setState(() {
        _favoriteProducts = allProducts.take(3).toList();
        _isLoading = false;
      });
    }
  }

  void _removeFavorite(Product product) {
    setState(() {
      _favoriteProducts.remove(product);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} dihapus dari favorit'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Batal',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              _favoriteProducts.insert(0, product);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorit'),
        actions: [
          if (_favoriteProducts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.favorite_border),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Hapus Semua'),
                    content: const Text('Hapus semua produk dari favorit?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() => _favoriteProducts.clear());
                          Navigator.pop(ctx);
                        },
                        child: const Text(
                          'Hapus Semua',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoriteProducts.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadFavorites,
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _favoriteProducts.length,
                itemBuilder: (context, index) {
                  return _buildFavoriteCard(_favoriteProducts[index]);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFCE7F3), Color(0xFFFBCFE8)],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.favorite_border,
              size: 50,
              color: Color(0xFFEC4899),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Belum Ada Favorit',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tambahkan produk favorit Anda\ndengan menekan ikon ❤️',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/user-home'),
            icon: const Icon(Icons.shopping_bag),
            label: const Text('Mulai Belanja'),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(Product product) {
    final isOutOfStock = product.stock <= 0;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  color: const Color(0xFFF1F5F9),
                  child:
                      product.photoPath != null && product.photoPath!.isNotEmpty
                      ? Image.file(
                          File(product.photoPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, err, stack) => const Icon(
                            Icons.image,
                            size: 48,
                            color: Color(0xFF94A3B8),
                          ),
                        )
                      : const Icon(
                          Icons.image,
                          size: 48,
                          color: Color(0xFF94A3B8),
                        ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.favorite,
                        color: Color(0xFFEC4899),
                      ),
                      onPressed: () => _removeFavorite(product),
                      iconSize: 20,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ),
                ),
                if (isOutOfStock)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.4),
                      child: const Center(
                        child: Text(
                          'HABIS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rp ${_formatPrice(product.price)}',
                  style: const TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                if (!isOutOfStock) ...[
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 32,
                          child: ElevatedButton.icon(
                            onPressed: () => _addToCart(product),
                            icon: const Icon(
                              Icons.shopping_cart_outlined,
                              size: 14,
                            ),
                            label: const Text(
                              'Add to cart',
                              style: TextStyle(fontSize: 10),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        height: 32,
                        child: ElevatedButton.icon(
                          onPressed: () => _directCheckout(product),
                          icon: const Icon(Icons.flash_on, size: 12),
                          label: const Text(
                            'Checkout',
                            style: TextStyle(fontSize: 10),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match.group(1)}.',
        );
  }
}
