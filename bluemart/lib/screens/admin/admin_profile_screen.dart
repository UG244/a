import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../services/product_service.dart';
import '../../services/transaction_service.dart';
import '../../models/app_user.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _authService = AuthService();
  final _productService = ProductService();
  final _transactionService = TransactionService();

  AppUser? _user;
  bool _isLoading = true;
  bool _isBiometricEnabled = false;
  bool _isBiometricSupported = true;
  bool _isRealtimeNotificationEnabled = true;

  int _totalProducts = 0;
  int _totalTransactions = 0;
  double _totalRevenue = 0;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    final user = await _authService.getCurrentUser();
    final prefs = await SharedPreferences.getInstance();
    final bio = prefs.getBool('biometric_enabled') ?? false;
    final realtime = prefs.getBool('realtime_notifications_enabled') ?? true;
    final bioSupported = await BiometricService().hasFingerprintSupport();

    final products = await _productService.getAllProducts();
    final transactions = await _transactionService.getAllTransactions();
    final revenue = await _transactionService.getTotalRevenue();

    if (mounted) {
      setState(() {
        _user = user;
        _isBiometricEnabled = bio;
        _isBiometricSupported = bioSupported;
        _isRealtimeNotificationEnabled = realtime;
        _totalProducts = products.length;
        _totalTransactions = transactions.length;
        _totalRevenue = revenue;
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
            Expanded(child: Text('Konfirmasi Logout Admin')),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari panel pengelola BlueMart?'),
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
            child: const Text('Logout Admin'),
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

  void _showAdminSettingsSheet() {
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
                      'Pengaturan Sistem Admin',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSettingsSection('Keamanan Akun & Akses', [
                  _buildSettingsToggle(
                    'Kunci Biometrik Admin (Fingerprint/Face ID)',
                    _isBiometricEnabled,
                    isEnabled: _isBiometricSupported,
                    subtitle: _isBiometricSupported ? null : 'Perangkat tidak mendukung atau belum ada sidik jari yang terdaftar.',
                    onChanged: (value) async {
                      final prefs = await SharedPreferences.getInstance();
                      if (value) {
                        if (!context.mounted) return;
                        final confirmed = await BiometricService().authenticate(
                          context: context,
                          localizedReason: 'Sentuh sensor sidik jari Anda untuk mengaktifkan kunci biometrik Admin BlueMart',
                        );
                        if (confirmed) {
                          await prefs.setBool('biometric_enabled', true);
                          await prefs.setString('biometric_username', _user?.username ?? 'admin');
                          await prefs.setString('biometric_password', 'admin123');
                          setModalState(() => _isBiometricEnabled = true);
                          setState(() => _isBiometricEnabled = true);
                        }
                      } else {
                        await prefs.setBool('biometric_enabled', false);
                        await prefs.remove('biometric_username');
                        await prefs.remove('biometric_password');
                        setModalState(() => _isBiometricEnabled = false);
                        setState(() => _isBiometricEnabled = false);
                      }
                    },
                  ),
                ]),
                const SizedBox(height: 16),
                _buildSettingsSection('Pemberitahuan Sistem', [
                  _buildSettingsToggle(
                    'Notifikasi Pesanan Masuk Real-time', 
                    _isRealtimeNotificationEnabled,
                    onChanged: (value) async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('realtime_notifications_enabled', value);
                      setModalState(() => _isRealtimeNotificationEnabled = value);
                      setState(() => _isRealtimeNotificationEnabled = value);
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

  void _showAdminHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.help_center, color: Color(0xFF0F172A)),
            SizedBox(width: 8),
            Expanded(child: Text('Panduan Pengelola Toko')),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fungsi Utama Panel Admin:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• Manajemen Produk: Tambah barang baru, edit harga, & update stok.'),
            Text('• Kendali Kupon: Buat kode promo dan atur minimal belanja.'),
            Text('• Pantau Pesanan: Lihat seluruh pesanan pembeli & ubah status pengiriman.'),
            Text('• Pengaturan QRIS: Unggah atau perbarui gambar QRIS untuk pembayaran digital.'),
            Text('• Laporan Keuangan: Analisis grafik pendapatan & riwayat penjualan toko.'),
          ],
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
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0F172A))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Text('Profil & Pengaturan Admin', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showAdminSettingsSheet,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Header Admin
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.only(top: 24, bottom: 28, left: 20, right: 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.amber[400],
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10),
                      ],
                    ),
                    child: const Icon(Icons.admin_panel_settings, size: 40, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _user?.username ?? 'BlueMart Admin',
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
                            color: Colors.amber[400]!.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber[400]!),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.workspace_premium, size: 14, color: Colors.amber),
                              SizedBox(width: 4),
                              Text(
                                'SUPER ADMINISTRATOR',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Operational Stats Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.inventory_2,
                      label: 'Total Produk',
                      value: '$_totalProducts Barang',
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.receipt_long,
                      label: 'Pesanan Masuk',
                      value: '$_totalTransactions Transaksi',
                      color: const Color(0xFFF97316),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.payments,
                      label: 'Pendapatan Toko',
                      value: 'Rp ${_formatPrice(_totalRevenue)}',
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
                  _buildSectionTitle('Manajemen & Operasional Toko'),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    icon: Icons.inventory_2_outlined,
                    iconColor: const Color(0xFF3B82F6),
                    title: 'Manajemen Katalog Produk',
                    subtitle: 'Tambah barang baru, edit harga, stok, & foto',
                    onTap: () => Navigator.pushNamed(context, '/admin-products'),
                  ),
                  _buildMenuItem(
                    icon: Icons.discount_outlined,
                    iconColor: const Color(0xFF22C55E),
                    title: 'Manajemen Kupon & Promo',
                    subtitle: 'Buat & kendalikan voucher diskon untuk pembeli',
                    onTap: () => Navigator.pushNamed(context, '/admin-coupon'),
                  ),
                  _buildMenuItem(
                    icon: Icons.local_shipping_outlined,
                    iconColor: const Color(0xFFF97316),
                    title: 'Pantau & Update Status Pesanan',
                    subtitle: 'Lihat seluruh pesanan pembeli & ubah status pengiriman',
                    onTap: () => Navigator.pushNamed(context, '/user-orders'),
                  ),
                  _buildMenuItem(
                    icon: Icons.qr_code_outlined,
                    iconColor: const Color(0xFF8B5CF6),
                    title: 'Pengaturan QRIS Pembayaran Toko',
                    subtitle: 'Perbarui gambar/kode QRIS resmi BlueMart',
                    onTap: () => Navigator.pushNamed(context, '/admin-qris'),
                  ),
                  _buildMenuItem(
                    icon: Icons.bar_chart_outlined,
                    iconColor: const Color(0xFFEC4899),
                    title: 'Laporan Penjualan & Keuangan',
                    subtitle: 'Analisis grafik pendapatan & riwayat penjualan',
                    onTap: () => Navigator.pushNamed(context, '/admin-sales-report'),
                  ),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Sistem & Panduan Admin'),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    icon: Icons.help_center_outlined,
                    iconColor: const Color(0xFF64748B),
                    title: 'Panduan Pengelola Toko BlueMart',
                    subtitle: 'FAQ dan informasi penggunaan dasbor admin',
                    onTap: _showAdminHelpDialog,
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
                        'Keluar dari Akun Admin',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFECACA), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
    bool isEnabled = true,
    String? subtitle,
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label, 
                  style: TextStyle(
                    fontSize: 14, 
                    color: isEnabled ? Colors.black : Colors.grey,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle, 
                    style: const TextStyle(fontSize: 11, color: Colors.red),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: const Color(0xFF0F172A),
            onChanged: isEnabled && onChanged != null ? (val) => onChanged(val) : null,
          ),
        ],
      ),
    );
  }
}
