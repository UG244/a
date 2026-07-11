import 'package:flutter/material.dart';
import '../../database/db_helper.dart';

class AdminCouponScreen extends StatefulWidget {
  const AdminCouponScreen({super.key});

  @override
  State<AdminCouponScreen> createState() => _AdminCouponScreenState();
}

class _AdminCouponScreenState extends State<AdminCouponScreen> {
  final DbHelper _dbHelper = DbHelper();
  List<Map<String, dynamic>> _coupons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() => _isLoading = true);
    final data = await _dbHelper.getAllCoupons();
    if (mounted) {
      setState(() {
        _coupons = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleCouponStatus(Map<String, dynamic> coupon) async {
    final code = coupon['code'] as String;
    final currentStatus = (coupon['isActive'] as int?) == 1;
    final newStatus = !currentStatus;
    await _dbHelper.updateCouponStatus(code, newStatus);
    await _loadCoupons();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kupon "$code" ${newStatus ? "diaktifkan" : "dinonaktifkan"}',
          ),
          backgroundColor: newStatus ? const Color(0xFF22C55E) : Colors.grey[700],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatCurrency(double amount) {
    if (amount <= 0) return 'Rp 0';
    return 'Rp ${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kupon Diskon'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddCouponDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _coupons.length + 1, // +1 for header
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      'Kelola kupon diskon untuk pelanggan (aktif/nonaktif langsung tersinkron ke checkout)',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  );
                }
                final coupon = _coupons[index - 1];
                return _buildCouponCard(coupon);
              },
            ),
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon) {
    final isActive = (coupon['isActive'] as int?) == 1;
    final minPurchaseVal = (coupon['minPurchase'] as num?)?.toDouble() ?? 0.0;
    final minPurchaseStr = _formatCurrency(minPurchaseVal);
    final uses = (coupon['uses'] as int?) ?? 0;
    final maxUses = (coupon['maxUses'] as int?) ?? 100;
    final progress = maxUses > 0 ? (uses / maxUses).clamp(0.0, 1.0) : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isActive
              ? const Color(0xFF22C55E).withValues(alpha: 0.3)
              : Colors.grey[300]!,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFF97316).withValues(alpha: 0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFFF97316)
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    coupon['code'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      letterSpacing: 1,
                      color: isActive
                          ? const Color(0xFFF97316)
                          : Colors.grey[500],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF22C55E).withValues(alpha: 0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'Aktif' : 'Nonaktif',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? const Color(0xFF22C55E)
                          : Colors.grey[500],
                    ),
                  ),
                ),
                const Spacer(),
                Switch(
                  value: isActive,
                  onChanged: (val) => _toggleCouponStatus(coupon),
                  activeThumbColor: const Color(0xFF22C55E),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.discount,
                    'Diskon',
                    coupon['discount'] as String? ?? '10%',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.shopping_bag,
                    'Min. Belanja',
                    minPurchaseStr,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    Icons.calendar_today,
                    'Kadaluarsa',
                    coupon['expiry'] as String? ?? '31 Des 2026',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.people,
                    'Digunakan',
                    '$uses/$maxUses',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              color: isActive
                  ? const Color(0xFF22C55E)
                  : Colors.grey[400],
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showAddCouponDialog() {
    final codeController = TextEditingController();
    final discountController = TextEditingController();
    final minPurchaseController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.local_offer, color: Color(0xFF1E3A8A)),
            SizedBox(width: 8),
            Text('Tambah Kupon Diskon'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Kode Kupon (mis. PROMO50)',
                  hintText: 'PROMO50',
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: discountController,
                decoration: const InputDecoration(
                  labelText: 'Diskon (mis. 15% atau Gratis Ongkir)',
                  hintText: '15%',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: minPurchaseController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Min. Belanja (Rp)',
                  hintText: '100000',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.isNotEmpty &&
                  discountController.text.isNotEmpty) {
                final code = codeController.text.trim().toUpperCase();
                final discount = discountController.text.trim();
                final digits = minPurchaseController.text.replaceAll(RegExp(r'[^0-9]'), '');
                final minP = double.tryParse(digits) ?? 0.0;

                double discountPercent = 0.10;
                int freeShipping = 0;
                if (discount.toLowerCase().contains('gratis') ||
                    discount.toLowerCase().contains('ongkir')) {
                  freeShipping = 1;
                  discountPercent = 0.0;
                } else if (discount.contains('%')) {
                  final pStr = discount.replaceAll('%', '').trim();
                  discountPercent = (double.tryParse(pStr) ?? 10) / 100.0;
                }

                await _dbHelper.insertCoupon({
                  'code': code,
                  'discount': discount,
                  'discountPercent': discountPercent,
                  'minPurchase': minP,
                  'freeShipping': freeShipping,
                  'expiry': '31 Des 2026',
                  'uses': 0,
                  'maxUses': 100,
                  'isActive': 1,
                  'createdAt': DateTime.now().toIso8601String(),
                });

                if (context.mounted) Navigator.pop(context);
                if (mounted) _loadCoupons();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}