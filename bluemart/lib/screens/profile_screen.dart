import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../services/auth_service.dart';
import '../services/cart_service.dart';
import '../services/transaction_service.dart';
import '../models/app_user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _dbHelper = DbHelper();
  final _transactionService = TransactionService();
  AppUser? _user;
  bool _isLoading = true;
  bool _promoVoucherEnabled = false;
  int _orderCount = 0;
  int _couponCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _user = user;
        _isLoading = false;
      });
    }
    _loadPromoPref();
    _loadStats();
  }

  Future<void> _loadPromoPref() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('promo_voucher_enabled') ?? false;
    if (mounted) {
      setState(() => _promoVoucherEnabled = enabled);
    }
  }

  Future<void> _loadStats() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user == null) return;
      final orders = await _transactionService.getUserOrders(user.username);
      final promos = await _dbHelper.getActivePromoCodes();
      if (mounted) {
        setState(() {
          _orderCount = orders.length;
          _couponCount = promos.length;
        });
      }
    } catch (_) {}
  }

  Future<void> _togglePromoVoucher(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('promo_voucher_enabled', value);
    if (mounted) {
      setState(() => _promoVoucherEnabled = value);
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
        content: const Text('Apakah Anda yakin ingin keluar?'),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isAdmin = _user?.role == 'admin';
    final cart = context.watch<CartService>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1E3A8A),
                      Color(0xFF3B82F6),
                      Color(0xFF0EA5E9),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(60),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      left: -20,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: 40,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Icon(
                              isAdmin
                                  ? Icons.admin_panel_settings
                                  : Icons.person,
                              size: 32,
                              color: isAdmin
                                  ? const Color(0xFF1E3A8A)
                                  : const Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _user?.username ?? 'Unknown',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 12,
                                        color: Colors.amber[300],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isAdmin
                                            ? 'ADMINISTRATOR'
                                            : 'PENGGUNA BIASA',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.settings,
                              color: Colors.white,
                            ),
                            onPressed: () => _showSettingsSheet(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.receipt_long,
                      label: 'Pesanan',
                      value: '$_orderCount Aktif',
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.shopping_cart,
                      label: 'Keranjang',
                      value: '${cart.uniqueItemCount} Item',
                      color: const Color(0xFFF97316),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.discount,
                      label: 'Kupon',
                      value: '$_couponCount Tersedia',
                      color: const Color(0xFF22C55E),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Aktivitas Belanja'),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    icon: Icons.receipt_long_outlined,
                    iconColor: const Color(0xFF3B82F6),
                    title: 'Riwayat Pesanan',
                    subtitle: 'Monitor pengiriman Anda',
                    onTap: () => Navigator.pushNamed(context, '/user-orders'),
                  ),
                  _buildMenuItem(
                    icon: Icons.location_on_outlined,
                    iconColor: const Color(0xFFF97316),
                    title: 'Buku Alamat Pengiriman',
                    subtitle: 'Atur alamat utama',
                    onTap: () => _showAddressDialog(),
                  ),
                  _buildMenuItem(
                    icon: Icons.qr_code_scanner,
                    iconColor: const Color(0xFF8B5CF6),
                    title: 'Metode Pembayaran QRIS',
                    subtitle: 'Scan QR saat checkout',
                    onTap: () => _showQrisInfo(),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Pengelola & Sistem'),
                  const SizedBox(height: 8),
                  if (isAdmin)
                    _buildMenuItem(
                      icon: Icons.admin_panel_settings,
                      iconColor: const Color(0xFF1E3A8A),
                      title: 'Admin Panel',
                      subtitle: 'Kelola toko & produk',
                      onTap: () =>
                          Navigator.pushNamed(context, '/admin-dashboard'),
                    ),
                  _buildMenuItem(
                    icon: Icons.help_outline,
                    iconColor: const Color(0xFF94A3B8),
                    title: 'Pusat Bantuan & FAQ',
                    subtitle: 'Butuh bantuan?',
                    onTap: () => _showFaqSheet(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFECACA)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddressDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Buku Alamat',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildAddressTile(
                    'Rumah',
                    'Jl. Sudirman No. 123, Denpasar',
                    'John Doe',
                    '+62 812-3456-7890',
                    true,
                  ),
                  const SizedBox(height: 12),
                  _buildAddressTile(
                    'Kantor',
                    'Jl. Imam Bonjol No. 456, Denpasar',
                    'John Doe',
                    '+62 813-9876-5432',
                    false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressTile(
    String label,
    String address,
    String recipient,
    String phone,
    bool isDefault,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isDefault ? Icons.home : Icons.work,
              color: const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (isDefault)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Utama',
                          style: TextStyle(fontSize: 9, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$recipient • $phone',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showQrisInfo() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.qr_code, color: Color(0xFF06B6D4)),
            SizedBox(width: 8),
            Text('Pembayaran QRIS'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_2, size: 80, color: Color(0xFF06B6D4)),
            SizedBox(height: 12),
            Text(
              'Anda dapat membayar menggunakan QRIS saat checkout.\n\n'
              'Cukup pilih metode pembayaran QRIS, lalu scan kode QR yang muncul menggunakan aplikasi e-wallet Anda.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _showFaqSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pusat Bantuan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildFaqItem(
                    'Bagaimana cara memesan?',
                    'Pilih produk, tambahkan ke keranjang, lalu lakukan checkout.',
                  ),
                  _buildFaqItem(
                    'Metode pembayaran apa saja?',
                    'QRIS, Transfer Bank BCA/Mandiri, DANA, OVO, dan COD.',
                  ),
                  _buildFaqItem(
                    'Berapa lama pengiriman?',
                    '2-3 hari kerja via JNE/J&T, atau hari yang sama via GoSend Instant.',
                  ),
                  _buildFaqItem(
                    'Bagaimana cara retur barang?',
                    'Hubungi customer service kami dalam 7 hari setelah barang diterima.',
                  ),
                  _buildFaqItem(
                    'Apakah ada diskon?',
                    'Aktifkan "Promo & Voucher" di Pengaturan untuk melihat promo yang tersedia.',
                  ),
                  _buildFaqItem(
                    'Kontak Customer Service',
                    'Email: support@bluemart.id\nWhatsApp: +62 811-1234-5678',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(answer, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
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
              color: color.withValues(alpha: 0.1),
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
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
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
      margin: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pengaturan Akun',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user?.username ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'ID 1 • ${_user != null ? _user!.role.toUpperCase() : 'USER'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.verified,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildSettingsSection('Notifikasi', [
                    _buildSettingsToggle('Push Notification', true),
                    _buildSettingsToggle('Update Pesanan', true),
                    _buildSettingsToggle(
                      'Promo & Voucher',
                      _promoVoucherEnabled,
                      onChanged: _togglePromoVoucher,
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildSettingsSection('Keamanan & Tampilan', [
                    _buildSettingsToggle('Kunci Biometrik', false),
                    _buildSettingsToggle('Mode Ringkas', false),
                  ]),
                  const SizedBox(height: 16),
                  _buildSettingsSection('Preferensi', [
                    _buildSettingsOption('Bahasa', 'Indonesia'),
                    _buildSettingsOption('Mata Uang', 'IDR'),
                    _buildSettingsOption('QRIS Checkout', 'Aktif'),
                  ]),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pengaturan berhasil disimpan'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text('Simpan Pengaturan'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
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
            color: Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingsToggle(
    String label,
    bool value, {
    ValueChanged<bool>? onChanged,
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
            onChanged: onChanged ?? (_) {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOption(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Row(
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 18, color: Colors.grey[400]),
            ],
          ),
        ],
      ),
    );
  }
}
