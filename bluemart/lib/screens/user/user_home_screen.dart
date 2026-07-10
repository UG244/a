import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/product.dart';
import '../../models/cart_item.dart';
import '../../database/db_helper.dart';
import '../../services/product_service.dart';
import '../../services/cart_service.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});
  @override
  State<UserHomeScreen> createState() => UserHomeScreenState();
}

class UserHomeScreenState extends State<UserHomeScreen> {
  final _productService = ProductService();
  final _dbHelper = DbHelper();
  List<Product> _products = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  int _currentBanner = 0;
  bool _promoEnabled = false;
  List<Map<String, dynamic>> _banners = [];
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  final List<Map<String, dynamic>> _defaultBanners = [
    {
      'title': 'Flash Sale Akhir Pekan',
      'subtitle': 'Diskon hingga 50%',
      'badge': 'PROMO HARI INI',
      'color1': const Color(0xFF1E3A8A),
      'color2': const Color(0xFF3B82F6),
      'icon': Icons.flash_on,
    },
    {
      'title': 'Gadget Terbaru 2026',
      'subtitle': 'Teknologi terkini untuk Anda',
      'badge': 'NEW ARRIVAL',
      'color1': const Color(0xFF0EA5E9),
      'color2': const Color(0xFF06B6D4),
      'icon': Icons.devices,
    },
    {
      'title': 'Gratis Ongkir',
      'subtitle': 'Min. belanja Rp200.000',
      'badge': 'FREE SHIPPING',
      'color1': const Color(0xFF8B5CF6),
      'color2': const Color(0xFFA78BFA),
      'icon': Icons.local_shipping,
    },
  ];

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Laptop', 'icon': Icons.laptop, 'color': const Color(0xFF3B82F6)},
    {
      'name': 'Smartphone',
      'icon': Icons.phone_android,
      'color': const Color(0xFF22C55E),
    },
    {
      'name': 'Audio',
      'icon': Icons.headphones,
      'color': const Color(0xFFF97316),
    },
    {
      'name': 'Gaming',
      'icon': Icons.sports_esports,
      'color': const Color(0xFFEF4444),
    },
    {
      'name': 'Aksesoris',
      'icon': Icons.cable,
      'color': const Color(0xFF8B5CF6),
    },
    {
      'name': 'Storage',
      'icon': Icons.storage,
      'color': const Color(0xFFEC4899),
    },
  ];

  List<String> get _productCategories {
    final cats = _products.map((p) => p.category).toSet().toList();
    cats.sort();
    return ['Semua', ...cats];
  }

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadPromoSetting();
    _loadBanners();
    _startBannerAutoScroll();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void reloadPromoState() => _loadPromoSetting();

  void _startBannerAutoScroll() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _banners.isNotEmpty) {
        setState(() => _currentBanner = (_currentBanner + 1) % _banners.length);
        _startBannerAutoScroll();
      }
    });
  }

  Future<void> _loadPromoSetting() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted)
      setState(
        () => _promoEnabled = prefs.getBool('promo_voucher_enabled') ?? false,
      );
  }

  Future<void> _loadBanners() async {
    try {
      final promotions = await _dbHelper.getActivePromotions();
      if (promotions.isNotEmpty) {
        final banners = <Map<String, dynamic>>[];
        for (var p in promotions) {
          IconData icon;
          switch (p['icon'] as String? ?? 'flash_on') {
            case 'devices':
              icon = Icons.devices;
              break;
            case 'local_shipping':
              icon = Icons.local_shipping;
              break;
            default:
              icon = Icons.flash_on;
          }
          banners.add({
            'title': p['title'],
            'subtitle': p['subtitle'] ?? '',
            'badge': p['badge'] ?? '',
            'color1': Color(p['color1'] as int),
            'color2': Color(p['color2'] as int),
            'icon': icon,
          });
        }
        if (mounted) setState(() => _banners = banners);
      }
    } catch (_) {}
    if (_banners.isEmpty && mounted) setState(() => _banners = _defaultBanners);
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final products = await _productService.getActiveProducts();
    if (mounted)
      setState(() {
        _products = products;
        _isLoading = false;
      });
  }

  /// Debounced search with 300ms delay (per spec).
  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _searchQuery = value);
      }
    });
  }

  List<Product> get filteredProducts {
    final query = _searchQuery.toLowerCase();
    var result = _products;
    if (_selectedCategory != 'Semua')
      result = result.where((p) => p.category == _selectedCategory).toList();
    if (query.isNotEmpty)
      result = result
          .where((p) => p.name.toLowerCase().contains(query))
          .toList();
    return result;
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                success
                    ? '${product.name} ditambahkan ke keranjang'
                    : 'Stok tidak mencukupi',
              ),
            ],
          ),
          backgroundColor: success
              ? const Color(0xFF22C55E)
              : const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Row(
              children: [
                Icon(Icons.store_rounded, size: 22),
                SizedBox(width: 8),
                Text('BlueMart', style: TextStyle(fontSize: 18)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () =>
                    Navigator.pushNamed(context, '/user-notifications'),
              ),
              Consumer<CartService>(
                builder: (context, cart, _) => Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined),
                      onPressed: () =>
                          Navigator.pushNamed(context, '/user-cart'),
                    ),
                    if (cart.uniqueItemCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '${cart.uniqueItemCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari laptop, smartphone...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, '/barcode-scanner'),
                          child: Container(
                            margin: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.qr_code_scanner,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF1E3A8A),
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: _onSearchChanged,
                    ),
                  ),
                ),
                if (_promoEnabled) _buildBannerCarousel(),
                _buildCategoriesSection(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.new_releases,
                            color: Color(0xFF1E3A8A),
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Produk Terbaru',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _loadProducts,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: _productCategories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF475569),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF1E3A8A),
                          checkmarkColor: Colors.white,
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: isSelected
                                ? Colors.transparent
                                : const Color(0xFFE2E8F0),
                          ),
                          onSelected: (_) =>
                              setState(() => _selectedCategory = cat),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            sliver: _isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : filteredProducts.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.search_off,
                              size: 40,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Produk tidak ditemukan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildProductCard(filteredProducts[index]),
                      childCount: filteredProducts.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCarousel() {
    if (_banners.isEmpty) return const SizedBox.shrink();
    final banner = _banners[_currentBanner];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [banner['color1'] as Color, banner['color2'] as Color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (banner['color1'] as Color).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(60),
                ),
              ),
            ),
            Positioned(
              left: -20,
              bottom: -40,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            banner['badge'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          banner['title'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          banner['subtitle'] as String,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    banner['icon'] as IconData,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _banners.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentBanner == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentBanner == index
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kategori Pilihan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 85,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (ctx, index) {
                final cat = _categories[index];
                return GestureDetector(
                  onTap: () =>
                      setState(() => _selectedCategory = cat['name'] as String),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: (cat['color'] as Color).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: (cat['color'] as Color).withValues(
                              alpha: 0.2,
                            ),
                          ),
                        ),
                        child: Icon(
                          cat['icon'] as IconData,
                          color: cat['color'] as Color,
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat['name'] as String,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final isOutOfStock = product.stock <= 0;
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () =>
            Navigator.pushNamed(context, '/user-detail', arguments: product.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child:
                        product.photoPath != null &&
                            product.photoPath!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: Image.file(
                              File(product.photoPath!),
                              fit: BoxFit.cover,
                              errorBuilder: (_, err, stack) => Center(
                                child: Icon(
                                  Icons.image,
                                  size: 40,
                                  color: Colors.grey[300],
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.image,
                              size: 40,
                              color: Colors.grey[300],
                            ),
                          ),
                  ),
                  if (product.stock > 0 && product.stock <= 5)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Sisa ${product.stock}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ),
                  if (isOutOfStock)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'HABIS',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              letterSpacing: 1.5,
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
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Rp ${_formatPrice(product.price)}',
                        style: const TextStyle(
                          color: Color(0xFF1E3A8A),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      if (!isOutOfStock)
                        GestureDetector(
                          onTap: () => _addToCart(product),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E3A8A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double price) => price
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (match) => '${match.group(1)}.',
      );
}
