import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../services/transaction_service.dart';
import '../../services/cart_service.dart';
import '../../database/db_helper.dart';
import '../../models/app_user.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _authService = AuthService();
  final _transactionService = TransactionService();
  final _dbHelper = DbHelper();

  AppUser? _user;
  bool _isLoading = true;
  bool _isBiometricEnabled = false;
  bool _isPromoVoucherEnabled = false;

  int _orderCount = 0;
  int _cartItemCount = 0;
  int _activeCouponCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserAndStats();
  }

  Future<void> _loadUserAndStats() async {
    setState(() => _isLoading = true);
    final user = await _authService.getCurrentUser();
    final prefs = await SharedPreferences.getInstance();
    final bio = prefs.getBool('biometric_enabled') ?? false;
    final pv = prefs.getBool('promo_voucher_enabled') ?? false;

    int orders = 0;
    int cartItems = 0;
    int coupons = 0;

    if (user != null) {
      final userOrders = await _transactionService.getUserOrders(user.username);
      orders = userOrders.length;

      final activeCoupons = await _dbHelper.getActiveCoupons();
      coupons = activeCoupons.length;
    }

    if (mounted) {
      cartItems = Provider.of<CartService>(context, listen: false).itemCount;
      setState(() {
        _user = user;
        _isBiometricEnabled = bio;
        _isPromoVoucherEnabled = pv;
        _orderCount = orders;
        _cartItemCount = cartItems;
        _activeCouponCount = coupons;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Konfirmasi Logout'),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari akun pembeli?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pengaturan Pembeli',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSettingsSection('Notifikasi & Kupon', [
                  _buildSettingsToggle('Push Notification Pesanan', true),
                  _buildSettingsToggle(
                    'Promo & Voucher Aktif',
                    _isPromoVoucherEnabled,
                    onChanged: (value) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('promo_voucher_enabled', value);
                      setModalState(() => _isPromoVoucherEnabled = value);
                      setState(() => _isPromoVoucherEnabled = value);
                      if (value) {
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        _showActivePromosDialog();
                      }
                    },
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSettingsSection('Keamanan Akun', [
                  _buildSettingsToggle(
                    'Kunci Biometrik (Sidik Jari/Face ID)',
                    _isBiometricEnabled,
                    onChanged: (value) async {
                      final prefs = await SharedPreferences.getInstance();
                      if (value) {
                        if (!context.mounted) return;
                        final confirmed = await BiometricService().authenticate(
                          context: context,
                          localizedReason: 'Sentuh sensor sidik jari Anda untuk mengaktifkan kunci biometrik BlueMart',
                        );
                        if (confirmed) {
                          await prefs.setBool('biometric_enabled', true);
                          setModalState(() => _isBiometricEnabled = true);
                          setState(() => _isBiometricEnabled = true);
                        }
                      } else {
                        await prefs.setBool('biometric_enabled', false);
                        setModalState(() => _isBiometricEnabled = false);
                        setState(() => _isBiometricEnabled = false);
                      }
                    },
                  ),
                ]),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showActivePromosDialog() async {
    final promos = await _dbHelper.getActiveCoupons();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.discount, color: Color(0xFF1E3A8A)),
            SizedBox(width: 8),
            Text('Promo & Voucher Aktif'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: promos.isEmpty
              ? const Text('Saat ini belum ada promo/voucher aktif dari admin.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: promos.length,
                  itemBuilder: (context, index) {
                    final promo = promos[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                promo['code'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  promo['discount'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Min. Belanja: Rp ${_formatPrice((promo['minPurchase'] as num).toDouble())} • Exp: ${promo['expiry']}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '💡 Promo ini otomatis muncul dan dapat dipilih saat Konfirmasi Pembayaran!',
                            style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF3B82F6)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.help, color: Color(0xFF3B82F6)),
            SizedBox(width: 8),
            Text('Pusat Bantuan & FAQ'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cara Menggunakan Aplikasi Pembeli:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('1. Cari produk kesukaan Anda di Beranda atau pencarian.'),
            Text('2. Masukkan ke Keranjang dan klik Konfirmasi Pembayaran.'),
            Text('3. Pilih atau ketik Kode Promo aktif untuk diskon otomatis.'),
            Text('4. Konfirmasi dengan PIN atau Kunci Biometrik yang aktif.'),
            Text('5. Pantau status pengiriman pesanan di menu Riwayat Pesanan.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Header User
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.only(top: 50, bottom: 26, left: 20, right: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6), Color(0xFF0EA5E9)],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10),
                          ],
                        ),
                        child: const Icon(Icons.person, size: 36, color: Color(0xFF3B82F6)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _user?.username ?? 'Pembeli BlueMart',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.stars, size: 14, color: Colors.amber[300]),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'MEMBER PEMBELI • 250 POIN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white, size: 26),
                        onPressed: _showSettingsSheet,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Stats Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.receipt_long,
                      label: 'Pesanan Saya',
                      value: '$_orderCount Pesanan',
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.shopping_cart,
                      label: 'Keranjang',
                      value: '$_cartItemCount Item',
                      color: const Color(0xFFF97316),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.discount,
                      label: 'Promo Aktif',
                      value: '$_activeCouponCount Kupon',
                      color: const Color(0xFF22C55E),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Menu Sections
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Aktivitas Belanja Anda'),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    icon: Icons.receipt_long_outlined,
                    iconColor: const Color(0xFF3B82F6),
                    title: 'Riwayat & Pelacakan Pesanan',
                    subtitle: 'Monitor progres & status pengiriman pesanan',
                    onTap: () => Navigator.pushNamed(context, '/user-orders'),
                  ),
                  _buildMenuItem(
                    icon: Icons.favorite_outline,
                    iconColor: const Color(0xFFEC4899),
                    title: 'Produk Favorit (Wishlist)',
                    subtitle: 'Daftar barang impian & simpanan Anda',
                    onTap: () => Navigator.pushNamed(context, '/user-favorites'),
                  ),
                  _buildMenuItem(
                    icon: Icons.location_on_outlined,
                    iconColor: const Color(0xFFF97316),
                    title: 'Buku Alamat Pengiriman',
                    subtitle: 'Atur alamat utama & koordinat peta pengiriman',
                    onTap: () => Navigator.pushNamed(context, '/user-address'),
                  ),
                  _buildMenuItem(
                    icon: Icons.qr_code_scanner,
                    iconColor: const Color(0xFF8B5CF6),
                    title: 'Metode Pembayaran QRIS',
                    subtitle: 'Lihat info pembayaran digital BlueMart',
                    onTap: () => Navigator.pushNamed(context, '/admin-qris'),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Bantuan & Preferensi'),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    icon: Icons.discount_outlined,
                    iconColor: const Color(0xFF22C55E),
                    title: 'Katalog Kupon & Promo Aktif',
                    subtitle: 'Lihat kupon diskon spesial dari admin',
                    onTap: _showActivePromosDialog,
                  ),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    iconColor: const Color(0xFF64748B),
                    title: 'Pusat Bantuan & FAQ Pembeli',
                    subtitle: 'Panduan belanja & informasi bantuan 24/7',
                    onTap: _showHelpDialog,
                  ),
                  const SizedBox(height: 24),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
                      label: const Text(
                        'Keluar dari Akun Pembeli',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFECACA), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        backgroundColor: const Color(0xFFFEF2F2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsToggle(
    String label,
    bool value, {
    Function(bool)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Switch(
            value: value,
            activeTrackColor: const Color(0xFF1E3A8A),
            onChanged: onChanged != null ? (val) => onChanged(val) : (_) {},
          ),
        ],
      ),
    );
  }
}
