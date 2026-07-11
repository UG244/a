import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/product_service.dart';
import '../../services/transaction_service.dart';
import '../../models/product.dart';
import '../../utils/constants.dart';
import 'admin_coupon_screen.dart';
import 'admin_payment_screen.dart';
import 'admin_qris_screen.dart';
import '../user/user_order_history_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentNavIndex = 0;
  
  Timer? _pollingTimer;
  int _pendingOrdersCount = 0;
  final TransactionService _transactionService = TransactionService();

  @override
  void initState() {
    super.initState();
    _checkInitialPendingOrders();
  }

  Future<void> _checkInitialPendingOrders() async {
    try {
      final transactions = await _transactionService.getAllTransactions();
      final pendingCount = transactions.where((t) {
        final status = t['status']?.toString().toLowerCase() ?? '';
        return status != 'selesai' && status != 'dibatalkan';
      }).length;
      
      if (pendingCount > 0 && mounted) {
        setState(() => _pendingOrdersCount = pendingCount);
        _showNewOrderPopup(pendingCount);
      }
      
      _startPolling();
    } catch (e) {
      // Abaikan error
    }
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!mounted) return;
      try {
        final transactions = await _transactionService.getAllTransactions();
        final currentPendingCount = transactions.where((t) {
          final status = t['status']?.toString().toLowerCase() ?? '';
          return status != 'selesai' && status != 'dibatalkan';
        }).length;
        
        if (currentPendingCount > _pendingOrdersCount) {
          final diff = currentPendingCount - _pendingOrdersCount;
          setState(() => _pendingOrdersCount = currentPendingCount);
          
          _showNewOrderPopup(diff);
        } else if (currentPendingCount != _pendingOrdersCount) {
          setState(() => _pendingOrdersCount = currentPendingCount);
        }
      } catch (e) {
        // Abaikan error
      }
    });
  }

  void _showNewOrderPopup(int count) async {
    if (!mounted) return;
    
    // Cek apakah notifikasi diaktifkan di pengaturan
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('realtime_notifications_enabled') ?? true;
    
    if (!isEnabled || !mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.blue),
            SizedBox(width: 8),
            Text('Pesanan Baru!'),
          ],
        ),
        content: Text('Ada $count pesanan baru yang masuk dan menunggu konfirmasi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _currentNavIndex = 3); // Arahkan ke tab Pesanan
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A)),
            child: const Text('Lihat Pesanan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  final List<Widget> _screens = [
    const _AdminDashboardContent(),
    const AdminCouponScreen(),
    const AdminPaymentScreen(),
    const UserOrderHistoryScreen(),
    const AdminQrisScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentNavIndex, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentNavIndex,
          onTap: (index) => setState(() => _currentNavIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF1E3A8A),
          unselectedItemColor: const Color(0xFF94A3B8),
          backgroundColor: Colors.white,
          elevation: 0,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.discount_outlined),
              activeIcon: Icon(Icons.discount),
              label: 'Kupon',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.payment_outlined),
              activeIcon: Icon(Icons.payment),
              label: 'Pembayaran',
            ),
            BottomNavigationBarItem(
              icon: _pendingOrdersCount > 0 
                  ? Badge(
                      label: Text('$_pendingOrdersCount'),
                      child: const Icon(Icons.receipt_long_outlined),
                    )
                  : const Icon(Icons.receipt_long_outlined),
              activeIcon: _pendingOrdersCount > 0
                  ? Badge(
                      label: Text('$_pendingOrdersCount'),
                      child: const Icon(Icons.receipt_long),
                    )
                  : const Icon(Icons.receipt_long),
              label: 'Pesanan',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_outlined),
              activeIcon: Icon(Icons.qr_code),
              label: 'QRIS',
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminDashboardContent extends StatefulWidget {
  const _AdminDashboardContent();

  @override
  State<_AdminDashboardContent> createState() => _AdminDashboardContentState();
}

class _AdminDashboardContentState extends State<_AdminDashboardContent> {
  final _authService = AuthService();
  final _productService = ProductService();
  final _transactionService = TransactionService();
  int _totalProducts = 0;
  int _totalStock = 0;
  int _lowStockCount = 0;
  double _totalRevenue = 0;
  int _totalTransactions = 0;
  List<Product> _recentProducts = [];
  bool _isLoading = true;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await _checkAccess();
    _loadUsername();
    _loadDashboardData();
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

  Future<void> _loadUsername() async {
    final user = await _authService.getCurrentUser();
    if (mounted && user != null) {
      setState(() => _username = user.username);
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _productService.getTotalProducts(),
        _productService.getTotalStock(),
        _productService.getLowStockCount(
          threshold: AppConstants.lowStockThreshold,
        ),
        _transactionService.getTotalRevenue(),
        _transactionService.getAllTransactions(),
        _productService.getRecentProducts(limit: 3),
      ]);

      if (mounted) {
        setState(() {
          _totalProducts = results[0] as int;
          _totalStock = results[1] as int;
          _lowStockCount = results[2] as int;
          _totalRevenue = results[3] as double;
        
          final allTransactions = results[4] as List<dynamic>;
          _totalTransactions = allTransactions.length;
          
          _recentProducts = results[5] as List<Product>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Welcome header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E3A8A).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.store_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'BlueMart Admin',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Halo, $_username',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.85,
                                      ),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.refresh,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                  onPressed: _loadDashboardData,
                                  tooltip: 'Muat Ulang Data',
                                ),
                                IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.manage_accounts,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  onPressed: () => Navigator.pushNamed(context, '/admin-profile'),
                                  tooltip: 'Profil & Pengaturan Admin',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Summary cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          icon: Icons.inventory_2,
                          title: 'Total Produk',
                          value: '$_totalProducts',
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          icon: Icons.inventory,
                          title: 'Total Stok',
                          value: '$_totalStock',
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          icon: Icons.warning_amber,
                          title: 'Stok Menipis',
                          value: '$_lowStockCount',
                          color: _lowStockCount > 0
                              ? Colors.orange
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          icon: Icons.receipt_long,
                          title: 'Transaksi',
                          value: '$_totalTransactions',
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryCard(
                    icon: Icons.monetization_on,
                    title: 'Total Pendapatan',
                    value: 'Rp ${_formatPrice(_totalRevenue)}',
                    color: Colors.teal,
                  ),
                  const SizedBox(height: 24),

                  // Quick actions - redesigned
                  Text(
                    'Aksi Cepat',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.8,
                    children: [
                      _buildQuickAction(
                        icon: Icons.add_box,
                        label: 'Tambah\nProduk',
                        color: const Color(0xFF3B82F6),
                        onTap: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            '/admin-product-form',
                            arguments: null,
                          );
                          if (result == true) _loadDashboardData();
                        },
                      ),
                      _buildQuickAction(
                        icon: Icons.list_alt,
                        label: 'Lihat\nProduk',
                        color: const Color(0xFF22C55E),
                        onTap: () async {
                          await Navigator.pushNamed(
                            context,
                            '/admin-products',
                          );
                          _loadDashboardData();
                        },
                      ),
                      _buildQuickAction(
                        icon: Icons.receipt,
                        label: 'Laporan\nPenjualan',
                        color: const Color(0xFF8B5CF6),
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/admin-sales-report',
                        ),
                      ),
                      _buildQuickAction(
                        icon: Icons.discount,
                        label: 'Kupon\nDiskon',
                        color: const Color(0xFFF97316),
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/admin-coupon',
                        ),
                      ),
                      _buildQuickAction(
                        icon: Icons.payment,
                        label: 'Metode\nPembayaran',
                        color: const Color(0xFFEC4899),
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/admin-payment',
                        ),
                      ),
                      _buildQuickAction(
                        icon: Icons.qr_code,
                        label: 'Set\nQRIS',
                        color: const Color(0xFF06B6D4),
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/admin-qris',
                        ),
                      ),
                      _buildQuickAction(
                        icon: Icons.history,
                        label: 'Riwayat\nPesanan',
                        color: const Color(0xFF6366F1),
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/user-orders',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Recent Products
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Produk Terbaru',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          await Navigator.pushNamed(context, '/admin-products');
                          _loadDashboardData();
                        },
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('Lihat Semua'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_recentProducts.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Belum ada produk',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._recentProducts.map(
                      (product) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.shopping_bag,
                              color: Colors.grey,
                            ),
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            'Stok: ${product.stock} | ${product.category}',
                          ),
                          trailing: Text(
                            'Rp ${_formatPrice(product.price)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
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


  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
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