import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/checkout_address.dart';
import '../../services/cart_service.dart';
import '../../services/auth_service.dart';
import '../../services/transaction_service.dart';
import '../../services/biometric_service.dart';
import '../../services/notification_service.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import '../../database/db_helper.dart';
import 'user_address_screen.dart';

class UserCheckoutScreen extends StatefulWidget {
  const UserCheckoutScreen({super.key});

  @override
  State<UserCheckoutScreen> createState() => _UserCheckoutScreenState();
}

class _UserCheckoutScreenState extends State<UserCheckoutScreen> {
  CheckoutAddress? _selectedAddress;
  String? _selectedShipping;
  String? _selectedPayment;
  String? _promoCode;
  final _promoController = TextEditingController();
  bool _isProcessing = false;
  String? _resultMessage;
  bool _success = false;

  List<Map<String, dynamic>> _availablePromos = [];
  bool _isPromoVoucherToggleActive = false;

  @override
  void initState() {
    super.initState();
    _loadActivePromos();
  }

  Future<void> _loadActivePromos() async {
    final prefs = await SharedPreferences.getInstance();
    final isToggleActive = prefs.getBool('promo_voucher_enabled') ?? false;
    final dbHelper = DbHelper();
    final promos = await dbHelper.getActiveCoupons();
    if (mounted) {
      setState(() {
        _isPromoVoucherToggleActive = isToggleActive;
        _availablePromos = List<Map<String, dynamic>>.from(promos);
      });
    }
  }

  final List<Map<String, dynamic>> _shippingMethods = [
    {
      'id': 'jne',
      'name': 'JNE YES',
      'cost': 50000,
      'duration': '2-3 Hari',
      'icon': Icons.local_shipping,
    },
    {
      'id': 'jnt',
      'name': 'J&T Express',
      'cost': 45000,
      'duration': '2-3 Hari',
      'icon': Icons.local_shipping,
    },
    {
      'id': 'gosend',
      'name': 'GoSend Instant',
      'cost': 35000,
      'duration': ' Hari ini',
      'icon': Icons.motorcycle,
    },
  ];

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'qris',
      'name': 'QRIS',
      'icon': Icons.qr_code,
      'color': Color(0xFF1E3A8A),
    },
    {
      'id': 'bca',
      'name': 'BCA Virtual Account',
      'icon': Icons.account_balance,
      'color': Color(0xFF1E3A8A),
    },
    {
      'id': 'dana',
      'name': 'DANA E-Wallet',
      'icon': Icons.account_balance_wallet,
      'color': Color(0xFF3B82F6),
    },
    {
      'id': 'ovo',
      'name': 'OVO',
      'icon': Icons.payment,
      'color': Color(0xFF8B5CF6),
    },
    {
      'id': 'cod',
      'name': 'COD',
      'icon': Icons.money,
      'color': Color(0xFF22C55E),
    },
  ];

  double get _shippingCost {
    if (_selectedShipping == null) return 0;
    final method = _shippingMethods.firstWhere(
      (m) => m['id'] == _selectedShipping,
      orElse: () => _shippingMethods.first,
    );
    double cost = (method['cost'] as num).toDouble();
    if (_promoCode != null) {
      final promo = _availablePromos.firstWhere(
        (p) => (p['code'] as String).toUpperCase() == _promoCode!.toUpperCase(),
        orElse: () => <String, dynamic>{},
      );
      if (promo.isNotEmpty &&
          (((promo['freeShipping'] as int?) == 1) ||
              promo['freeShipping'] == true ||
              promo['freeShipping'] == 1)) {
        return 0;
      }
    }
    return cost;
  }

  double get _subtotal {
    return context.read<CartService>().totalPrice;
  }

  double get _discount {
    if (_promoCode == null) return 0;
    final promo = _availablePromos.firstWhere(
      (p) => (p['code'] as String).toUpperCase() == _promoCode!.toUpperCase(),
      orElse: () => <String, dynamic>{},
    );
    if (promo.isEmpty) return 0;
    final pVal = (promo['discountPercent'] as num?)?.toDouble() ?? 0.0;
    return _subtotal * pVal;
  }

  double get _tax =>
      ((_subtotal - _discount) > 0 ? (_subtotal - _discount) : 0) * 0.11;
  double get _grandTotal {
    double total = _subtotal + _shippingCost + _tax - _discount;
    return total > 0 ? total : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Pesanan')),
      body: Consumer<CartService>(
        builder: (context, cart, _) {
          if (cart.items.isEmpty && _resultMessage == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.shopping_cart_outlined,
                      size: 40,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Keranjang Kosong',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Kembali Belanja'),
                  ),
                ],
              ),
            );
          }

          if (_resultMessage != null && _success) {
            return _buildSuccessView();
          }

          if (_resultMessage != null && !_success) {
            return _buildErrorView();
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Address Selection
              _buildSectionTitle('Alamat Pengiriman'),
              const SizedBox(height: 8),
              _selectedAddress != null
                  ? _AddressCard(
                      address: _selectedAddress!,
                      onTap: () => _selectAddress(),
                    )
                  : _buildSelectAddressCard(),
              const SizedBox(height: 20),

              // Shipping Selection
              _buildSectionTitle('Metode Pengiriman'),
              const SizedBox(height: 8),
              ..._shippingMethods.map(
                (method) => _ShippingCard(
                  method: method,
                  isSelected: _selectedShipping == method['id'],
                  onTap: () {
                    setState(() => _selectedShipping = method['id'] as String);
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Payment Selection
              _buildSectionTitle('Metode Pembayaran'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _paymentMethods.map((method) {
                  final isSelected = _selectedPayment == method['id'];
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedPayment = method['id'] as String);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1E3A8A)
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            method['icon'] as IconData? ?? Icons.payment,
                            color: method['color'] as Color? ?? Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            method['name'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? const Color(0xFF1E3A8A)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              if (_isPromoVoucherToggleActive && _availablePromos.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.discount, color: Color(0xFF1E3A8A), size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Promo & Voucher Aktif (Kendali Admin)',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: _showActivePromosBottomSheet,
                            child: const Text(
                              'Lihat Semua',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 110,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _availablePromos.length,
                          itemBuilder: (context, index) {
                            final promo = _availablePromos[index];
                            final code = promo['code'] as String;
                            final isApplied = _promoCode?.toUpperCase() == code.toUpperCase();
                            return Container(
                              width: 220,
                              margin: const EdgeInsets.only(right: 10),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isApplied ? const Color(0xFFDCFCE7) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isApplied ? const Color(0xFF22C55E) : const Color(0xFFBFDBFE),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        code,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: isApplied ? const Color(0xFF15803D) : const Color(0xFF1E3A8A),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF97316),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          promo['discount'] as String? ?? '',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Min. Rp ${_formatPrice((promo['minPurchase'] as num).toDouble())} • Exp: ${promo['expiry'] ?? '-'}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(
                                    height: 26,
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: isApplied
                                          ? null
                                          : () {
                                              _promoController.text = code;
                                              _applyPromo();
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1E3A8A),
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: Text(
                                        isApplied ? 'Sedang Dipakai' : 'Pakai Promo Ini',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
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
                ),
                const SizedBox(height: 16),
              ],

              // Promo Code
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Kode Promo'),
                  TextButton.icon(
                    onPressed: _showActivePromosBottomSheet,
                    icon: const Icon(Icons.local_offer, size: 16, color: Color(0xFF1E3A8A)),
                    label: const Text(
                      'Lihat Promo & Voucher Aktif',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _promoController,
                      decoration: InputDecoration(
                        hintText: 'Masukkan kode promo',
                        suffixIcon: _promoCode != null
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  setState(() => _promoCode = null);
                                  _promoController.clear();
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) =>
                          _promoCode = value.isEmpty ? null : value,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _applyPromo,
                    child: const Text('Terapkan'),
                  ),
                ],
              ),
              if (_promoCode != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green[600],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Promo "$_promoCode" diterapkan',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              // Order Summary
              _buildSectionTitle('Ringkasan Pembayaran'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Subtotal', _subtotal),
                    _buildSummaryRow('Ongkos Kirim', _shippingCost),
                    if (_discount > 0)
                      _buildSummaryRow('Diskon', -_discount, isDiscount: true),
                    _buildSummaryRow('Pajak (11%)', _tax),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rp ${_formatPrice(_grandTotal)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E3A8A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<CartService>(
        builder: (context, cart, _) {
          if (_resultMessage != null || cart.items.isEmpty) {
            return const SizedBox.shrink();
          }
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      (_selectedAddress != null &&
                          _selectedShipping != null &&
                          _selectedPayment != null &&
                          !_isProcessing)
                      ? _confirmCheckout
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Bayar Sekarang • Rp ${_formatPrice(_grandTotal)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.check_circle,
                size: 60,
                color: Colors.green[600],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Status Pembayaran: Berhasil!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _resultMessage ?? 'Pesanan Anda telah diproses',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
            ),
            if (_promoCode != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_offer, color: Color(0xFF1E3A8A), size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Promo Aktif Digunakan: $_promoCode (Diskon Rp ${_formatPrice(_discount)})',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFEF3C7)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Menunggu verifikasi admin',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber[900],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/user-home',
                  (route) => false,
                ),
                child: const Text('Kembali ke Beranda'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/user-orders'),
              child: const Text('Lihat Riwayat Pesanan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Status Pembayaran: Gagal',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _resultMessage ?? 'Terjadi kesalahan saat memproses pembayaran',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => setState(() {
                  _resultMessage = null;
                }),
                child: const Text('Coba Lagi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildSelectAddressCard() {
    return InkWell(
      onTap: _selectAddress,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
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
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.add_location_alt, color: Colors.grey[500]),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Pilih Alamat Pengiriman',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }



  Widget _buildSummaryRow(
    String label,
    double value, {
    bool isDiscount = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          Text(
            '${isDiscount ? '-' : ''}Rp ${_formatPrice(value)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: isDiscount ? FontWeight.w600 : FontWeight.normal,
              color: isDiscount ? Colors.green[600] : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  void _selectAddress() async {
    final result = await Navigator.push<CheckoutAddress>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            UserAddressScreen(selectedAddress: _selectedAddress),
      ),
    );
    if (result != null) {
      setState(() => _selectedAddress = result);
    }
  }

  void _applyPromo() {
    final code = _promoController.text.trim().toUpperCase();
    final promo = _availablePromos.firstWhere(
      (p) => p['code'] == code,
      orElse: () => <String, dynamic>{},
    );
    if (promo.isNotEmpty) {
      final minPurchase = (promo['minPurchase'] as num).toDouble();
      if (_subtotal < minPurchase) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Minimal belanja untuk promo "$code" adalah Rp ${_formatPrice(minPurchase)}',
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
        return;
      }
      setState(() => _promoCode = code);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Promo "$code" berhasil diterapkan!'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF22C55E),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kode promo tidak valid'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _confirmCheckout() async {
    if (_selectedPayment == null) return;

    // QRIS Payment - Generate QR from Total Amount and show dialog with download option
    if (_selectedPayment == 'qris') {
      _showQRISDialog();
      return;
    }

    // Virtual Account or E-Wallet - Show payment dialog
    if (_selectedPayment == 'bca' ||
        _selectedPayment == 'dana' ||
        _selectedPayment == 'ovo') {
      _showPaymentDialog();
      return;
    }

    // COD - Direct verification & checkout
    await _verifySecurityBeforePayment();
  }

  void _showQRISDialog() {
    final GlobalKey qrisReceiptKey = GlobalKey();
    final String qrisData =
        'BLUEMART-QRIS-PAYMENT|MERCHANT:BLUEMART.ID|AMOUNT:${_grandTotal.toInt()}|REF:${DateTime.now().millisecondsSinceEpoch}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_2, color: Color(0xFF1E3A8A), size: 28),
            SizedBox(width: 10),
            Text('Pembayaran QRIS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Scan QRIS di bawah ini menggunakan aplikasi M-Banking atau E-Wallet (BCA, Mandiri, Gopay, OVO, DANA):',
                  style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                RepaintBoundary(
                  key: qrisReceiptKey,
                  child: Container(
                    width: 300,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.storefront, color: Color(0xFF1E3A8A), size: 18),
                            const SizedBox(width: 6),
                            const Text(
                              'BLUEMART STORE QRIS',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: QrImageView(
                            data: qrisData,
                            version: QrVersions.auto,
                            size: 200,
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF1E3A8A),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Total Tagihan Pembayaran:',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        Text(
                          'Rp ${_formatPrice(_grandTotal)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF22C55E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'NMID: ID1020023049102 • QrCode Dinamis',
                          style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _downloadQRISImage(qrisReceiptKey),
                  icon: const Icon(Icons.download, size: 18, color: Color(0xFF1E3A8A)),
                  label: const Text(
                    'Download QR Pembayaran',
                    style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E3A8A)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF1E3A8A), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _verifySecurityBeforePayment();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Sudah Bayar'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadQRISImage(GlobalKey key) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      Directory? targetDir;
      if (Platform.isAndroid) {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          targetDir = downloadDir;
        } else {
          targetDir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        }
      } else {
        targetDir = await getApplicationDocumentsDirectory();
      }

      final fileName = 'QRIS_BlueMart_Rp${_grandTotal.toInt()}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${targetDir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('QR berhasil didownload ke:\n${file.path}'),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF22C55E),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendownload QR: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showPaymentDialog() {
    final nominalController = TextEditingController();
    String selectedBank = _selectedPayment == 'bca'
        ? 'BCA'
        : _selectedPayment == 'dana'
        ? 'DANA'
        : 'OVO';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              _selectedPayment == 'bca'
                  ? Icons.account_balance
                  : Icons.account_balance_wallet,
              color: const Color(0xFF1E3A8A),
            ),
            const SizedBox(width: 8),
            Text(selectedBank),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedPayment == 'bca')
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Virtual Account BCVA',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '8801 ${DateTime.now().millisecondsSinceEpoch.toString().substring(8, 13)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A),
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Atas nama: ${_getCustomerName()}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              if (_selectedPayment == 'dana' || _selectedPayment == 'ovo')
                TextField(
                  controller: nominalController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Nominal Transfer',
                    hintText: 'Masukkan nominal',
                    prefixText: 'Rp ',
                    prefixStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E3A8A),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.amber[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Total yang harus dibayar: Rp ${_formatPrice(_grandTotal)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.amber[900],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
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
              Navigator.pop(context);
              await _verifySecurityBeforePayment();
            },
            child: const Text('Sudah Bayar'),
          ),
        ],
      ),
    );
  }

  String _getCustomerName() {
    return 'Pelanggan';
  }

  Future<void> _verifySecurityBeforePayment() async {
    final prefs = await SharedPreferences.getInstance();
    final isBiometric = prefs.getBool('biometric_enabled') ?? false;

    if (isBiometric) {
      final biometricSuccess = await _showBiometricDialog();
      if (biometricSuccess == true) {
        await _processCODCheckout();
      } else if (biometricSuccess == false) {
        // Fallback to PIN / Password
        final pinSuccess = await _showPinPasswordDialog();
        if (pinSuccess == true) {
          await _processCODCheckout();
        }
      }
    } else {
      final pinSuccess = await _showPinPasswordDialog();
      if (pinSuccess == true) {
        await _processCODCheckout();
      }
    }
  }

  Future<bool?> _showBiometricDialog() async {
    final success = await BiometricService().authenticate(
      context: context,
      localizedReason: 'Sentuh sensor sidik jari Anda untuk konfirmasi pembayaran Rp ${_formatPrice(_grandTotal)}',
    );
    return success ? true : false;
  }

  Future<bool?> _showPinPasswordDialog() async {
    final pinController = TextEditingController();
    String? errorMessage;

    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: Color(0xFF1E3A8A)),
              SizedBox(width: 8),
              Text('Konfirmasi PIN/Password'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Masukkan PIN atau Password akun Anda untuk melanjutkan pembayaran:',
                style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pinController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'PIN / Password',
                  hintText: 'pakai password user (mis. user123)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  errorText: errorMessage,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final input = pinController.text.trim();
                final auth = AuthService();
                final user = await auth.getCurrentUser();
                final expectedPwd = (user?.username == 'admin') ? 'admin123' : 'user123';

                if (!context.mounted) return;
                if (input == expectedPwd ||
                    input == 'user123' ||
                    input == 'admin123' ||
                    input == '123456') {
                  Navigator.pop(context, true);
                } else {
                  setDialogState(() {
                    errorMessage = 'PIN / Password salah!';
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                foregroundColor: Colors.white,
              ),
              child: const Text('Konfirmasi'),
            ),
          ],
        ),
      ),
    );
  }

  void _showActivePromosBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Promo & Voucher Aktif',
                  style: TextStyle(
                    fontSize: 18,
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
            const SizedBox(height: 4),
            Text(
              'Pilih promo dari kendali admin untuk potongan belanja Anda',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            if (_availablePromos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Tidak ada promo yang aktif saat ini.',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              )
            else
              ..._availablePromos.map((promo) {
                final code = promo['code'] as String;
                final discount = promo['discount'] as String? ?? '';
                final minP = (promo['minPurchase'] as num?)?.toDouble() ?? 0.0;
                final canUse = _subtotal >= minP;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: canUse
                        ? const Color(0xFFEFF6FF)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: canUse
                          ? const Color(0xFF3B82F6)
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: canUse
                              ? const Color(0xFF1E3A8A)
                              : Colors.grey[400],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.local_offer,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              code,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: canUse
                                    ? const Color(0xFF1E3A8A)
                                    : Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              discount.isNotEmpty ? 'Diskon $discount' : 'Potongan Spesial',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: canUse
                                    ? const Color(0xFF2563EB)
                                    : Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Min. Belanja: Rp ${_formatPrice(minP)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: canUse
                            ? () {
                                Navigator.pop(context);
                                _promoController.text = code;
                                _applyPromo();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Gunakan'),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Future<void> _processCODCheckout() async {
    final cart = context.read<CartService>();
    final authService = AuthService();
    final transactionService = TransactionService();

    final user = await authService.getCurrentUser();
    if (user == null) return;

    setState(() {
      _isProcessing = true;
      _resultMessage = null;
    });

    try {
      final result = await transactionService.checkout(
        buyerUsername: user.username,
        cartItems: cart.items,
        totalAmount: _grandTotal,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _success = result['success'] as bool;
          _resultMessage = result['message'] as String?;
        });

        if (_success) {
          cart.clearCart();
          // Simpan notifikasi
          NotificationService().addNotification(
            'Pembayaran Berhasil',
            'Pesanan Anda telah dibayar dan sedang diproses.',
            type: 'pesanan',
          );
          // Mainkan suara
          FlutterRingtonePlayer().playNotification();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _success = false;
          _resultMessage = 'Terjadi kesalahan: $e';
        });
      }
    }
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

class _AddressCard extends StatelessWidget {
  final CheckoutAddress address;
  final VoidCallback onTap;
  const _AddressCard({required this.address, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1E3A8A), width: 2),
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
                address.isDefault ? Icons.home : Icons.work,
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
                        address.label,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      if (address.isDefault)
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
                    address.recipient,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address.fullAddress,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20, color: Color(0xFF3B82F6)),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _ShippingCard extends StatelessWidget {
  final Map<String, dynamic> method;
  final bool isSelected;
  final VoidCallback onTap;
  const _ShippingCard({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1E3A8A)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
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
                method['icon'] as IconData? ?? Icons.local_shipping,
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method['name'] as String,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      fontSize: 14,
                      color: isSelected
                          ? const Color(0xFF1E3A8A)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    method['duration'] as String,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Text(
              'Rp ${method['cost']}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E3A8A),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
