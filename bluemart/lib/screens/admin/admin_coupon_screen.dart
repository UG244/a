import 'package:flutter/material.dart';
import '../../database/db_helper.dart';

class AdminCouponScreen extends StatefulWidget {
  const AdminCouponScreen({super.key});

  @override
  State<AdminCouponScreen> createState() => _AdminCouponScreenState();
}

class _AdminCouponScreenState extends State<AdminCouponScreen> {
  final _dbHelper = DbHelper();
  List<Map<String, dynamic>> _coupons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() => _isLoading = true);
    try {
      final coupons = await _dbHelper.getAllPromoCodes();
      if (mounted) {
        setState(() {
          _coupons = coupons;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleCoupon(int id, int currentActive) async {
    final newActive = currentActive == 1 ? 0 : 1;
    await _dbHelper.togglePromoCode(id, newActive);
    _loadCoupons();
  }

  Future<void> _deleteCoupon(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kupon'),
        content: const Text('Yakin ingin menghapus kupon ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _dbHelper.deletePromoCode(id);
      _loadCoupons();
    }
  }

  Future<void> _showAddEditDialog({Map<String, dynamic>? coupon}) async {
    final codeController = TextEditingController(text: coupon?['code'] ?? '');
    final discountController = TextEditingController(
      text: coupon != null
          ? ((coupon['discountPercent'] as num) * 100).toStringAsFixed(0)
          : '',
    );
    final minPurchaseController = TextEditingController(
      text: coupon != null
          ? (coupon['minPurchase'] as num).toStringAsFixed(0)
          : '',
    );
    final isEdit = coupon != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Kupon' : 'Tambah Kupon'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Kode Kupon',
                  hintText: 'Contoh: FLASH50',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: discountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Diskon (%)',
                  hintText: 'Contoh: 50',
                  suffixText: '%',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: minPurchaseController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Min. Pembelian (Rp)',
                  hintText: 'Contoh: 500000',
                  prefixText: 'Rp ',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = codeController.text.trim();
              if (code.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Kode kupon wajib diisi')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: Text(isEdit ? 'Simpan' : 'Tambah'),
          ),
        ],
      ),
    );

    if (result == true) {
      final code = codeController.text.trim().toUpperCase();
      final discount = double.tryParse(discountController.text) ?? 0;
      final minPurchase = double.tryParse(minPurchaseController.text) ?? 0;

      if (isEdit) {
        await _dbHelper.updatePromoCode(coupon['id'] as int, {
          'code': code,
          'discountPercent': discount / 100,
          'minPurchase': minPurchase,
        });
      } else {
        await _dbHelper.insertPromoCode({
          'code': code,
          'discountPercent': discount / 100,
          'minPurchase': minPurchase,
          'freeShipping': 0,
        });
      }
      _loadCoupons();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kupon Diskon'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddEditDialog(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _coupons.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.discount_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada kupon',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddEditDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Tambah Kupon'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadCoupons,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _coupons.length,
                itemBuilder: (context, index) {
                  final coupon = _coupons[index];
                  return _buildCouponCard(coupon);
                },
              ),
            ),
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon) {
    final isActive = (coupon['isActive'] as int?) == 1;
    final discountPercent =
        (coupon['discountPercent'] as num?)?.toDouble() ?? 0;
    final minPurchase = (coupon['minPurchase'] as num?)?.toDouble() ?? 0;
    final freeShipping = (coupon['freeShipping'] as int?) == 1;

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
                Expanded(
                  child: Container(
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
                      coupon['code'] as String? ?? '',
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
                ),
                const SizedBox(width: 10),
                Switch(
                  value: isActive,
                  onChanged: (v) => _toggleCoupon(
                    coupon['id'] as int,
                    coupon['isActive'] as int,
                  ),
                  activeTrackColor: const Color(
                    0xFF22C55E,
                  ).withValues(alpha: 0.5),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _showAddEditDialog(coupon: coupon),
                ),
                IconButton(
                  icon: Icon(Icons.delete, size: 20, color: Colors.red[400]),
                  onPressed: () => _deleteCoupon(coupon['id'] as int),
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
                    '${(discountPercent * 100).toStringAsFixed(0)}%',
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    Icons.shopping_bag,
                    'Min. Belanja',
                    'Rp ${_fmt(minPurchase)}',
                  ),
                ),
              ],
            ),
            if (freeShipping)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_shipping,
                      size: 14,
                      color: Colors.green[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Gratis Ongkir',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ],
    );
  }

  String _fmt(double val) {
    return val
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m.group(1)}.',
        );
  }
}
