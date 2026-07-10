import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/checkout_address.dart';
import '../../database/db_helper.dart';
import '../../services/cart_service.dart';
import '../../services/auth_service.dart';
import '../../services/transaction_service.dart';
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
  bool _promoEnabled = false;
  List<Map<String, dynamic>> _availablePromos = [];
  final _dbHelper = DbHelper();

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
      'duration': 'Hari ini',
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

  @override
  void initState() {
    super.initState();
    _loadPromoData();
  }

  Future<void> _loadPromoData() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('promo_voucher_enabled') ?? false;
    List<Map<String, dynamic>> promos = [];
    if (enabled) {
      try {
        promos = await _dbHelper.getActivePromoCodes();
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _promoEnabled = enabled;
        _availablePromos = promos;
        if (!enabled && _promoCode != null) {
          _promoCode = null;
          _promoController.clear();
        }
      });
    }
  }

  double get _shippingCost {
    if (_selectedShipping == null) return 0;
    final m = _shippingMethods.firstWhere(
      (x) => x['id'] == _selectedShipping,
      orElse: () => _shippingMethods.first,
    );
    return (m['cost'] as num).toDouble();
  }

  double get _subtotal => context.read<CartService>().totalPrice;

  double get _discount {
    if (_promoCode == null) return 0;
    final p = _availablePromos.firstWhere(
      (x) => x['code'] == _promoCode,
      orElse: () => <String, dynamic>{},
    );
    if (p.isEmpty) return 0;
    final min = (p['minPurchase'] as num?)?.toDouble() ?? 0;
    if (_subtotal < min) return 0;
    return _subtotal * ((p['discountPercent'] as num?)?.toDouble() ?? 0);
  }

  double get _effectiveShippingCost {
    if (_promoCode == null) return _shippingCost;
    final p = _availablePromos.firstWhere(
      (x) => x['code'] == _promoCode,
      orElse: () => <String, dynamic>{},
    );
    if (p.isEmpty) return _shippingCost;
    final min = (p['minPurchase'] as num?)?.toDouble() ?? 0;
    if (_subtotal >= min && (p['freeShipping'] as int?) == 1) return 0;
    return _shippingCost;
  }

  double get _tax => (_subtotal - _discount) * 0.11;
  double get _grandTotal =>
      _subtotal + _effectiveShippingCost + _tax - _discount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konfirmasi Pesanan')),
      body: Consumer<CartService>(
        builder: (context, cart, _) {
          if (cart.items.isEmpty && _resultMessage == null) {
            return Center(
              child: Column(
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
          if (_resultMessage != null && _success) return _buildSuccessView();
          if (_resultMessage != null && !_success) return _buildErrorView();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle('Alamat Pengiriman'),
              const SizedBox(height: 8),
              _selectedAddress != null
                  ? _AddressCard(
                      address: _selectedAddress!,
                      onTap: () => _selectAddress(),
                    )
                  : _buildSelectAddressCard(),
              const SizedBox(height: 20),
              _buildSectionTitle('Metode Pengiriman'),
              const SizedBox(height: 8),
              ..._shippingMethods.map(
                (m) => _ShippingCard(
                  method: m,
                  isSelected: _selectedShipping == m['id'],
                  onTap: () =>
                      setState(() => _selectedShipping = m['id'] as String),
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('Metode Pembayaran'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _paymentMethods.map((m) {
                  final sel = _selectedPayment == m['id'];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedPayment = m['id'] as String),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: sel
                              ? const Color(0xFF1E3A8A)
                              : const Color(0xFFE2E8F0),
                          width: sel ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            m['icon'] as IconData,
                            color: m['color'] as Color,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            m['name'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: sel
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: sel
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
              if (_promoEnabled) ...[
                _buildSectionTitle('Kode Promo'),
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
              ],
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
                    _buildSummaryRow('Ongkos Kirim', _effectiveShippingCost),
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
              // Bayar button inside scrollable content
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed:
                      (_selectedAddress != null &&
                          _selectedShipping != null &&
                          _selectedPayment != null &&
                          !_isProcessing)
                      ? _showPaymentConfirmation
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                  ),
                  icon: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.payment),
                  label: Text(
                    _isProcessing
                        ? 'Memproses...'
                        : 'Bayar Sekarang • Rp ${_formatPrice(_grandTotal)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  void _showPaymentConfirmation() {
    final paymentId = _selectedPayment ?? '';
    final paymentName =
        _paymentMethods.firstWhere(
              (m) => m['id'] == paymentId,
              orElse: () => _paymentMethods.first,
            )['name']
            as String;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            height: MediaQuery.of(ctx).size.height * 0.78,
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
                        'Instruksi Pembayaran',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _getPaymentIcon(paymentId),
                                size: 48,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                paymentName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total: Rp ${_formatPrice(_grandTotal)}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildPaymentInstructions(paymentId),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Detail Pembayaran',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildDetailRow(
                                'Subtotal',
                                'Rp ${_formatPrice(_subtotal)}',
                              ),
                              _buildDetailRow(
                                'Ongkir',
                                'Rp ${_formatPrice(_effectiveShippingCost)}',
                              ),
                              if (_discount > 0)
                                _buildDetailRow(
                                  'Diskon',
                                  '-Rp ${_formatPrice(_discount)}',
                                  isDiscount: true,
                                ),
                              _buildDetailRow(
                                'Pajak (11%)',
                                'Rp ${_formatPrice(_tax)}',
                              ),
                              const Divider(height: 16),
                              _buildDetailRow(
                                'Total',
                                'Rp ${_formatPrice(_grandTotal)}',
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await _confirmCheckout();
                            },
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Konfirmasi Pembayaran'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  IconData _getPaymentIcon(String id) {
    switch (id) {
      case 'qris':
        return Icons.qr_code;
      case 'bca':
        return Icons.account_balance;
      case 'dana':
        return Icons.account_balance_wallet;
      case 'ovo':
        return Icons.payment;
      case 'cod':
        return Icons.money;
      default:
        return Icons.payment;
    }
  }

  Widget _buildPaymentInstructions(String paymentId) {
    switch (paymentId) {
      case 'qris':
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_2, size: 120, color: Colors.grey[700]),
                    const SizedBox(height: 8),
                    Text(
                      'QRIS Code',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Scan QR Code di atas menggunakan aplikasi e-wallet Anda (GoPay, OVO, DANA, LinkAja, dll).',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Color(0xFF3B82F6),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pembayaran akan diverifikasi otomatis dalam 1-2 menit.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case 'bca':
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.account_balance,
                    color: Color(0xFF0066AE),
                    size: 28,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'BCA Virtual Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0066AE),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildVaDetail(
                'Nomor Virtual Account',
                '8765 ${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 10)}',
              ),
              const SizedBox(height: 8),
              _buildVaDetail('Atas Nama', 'BlueMart Indonesia'),
              const SizedBox(height: 8),
              _buildVaDetail('Bank', 'BCA (Bank Central Asia)'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cara Pembayaran:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStep('1. Buka aplikasi BCA Mobile / KlikBCA'),
                    _buildStep('2. Pilih menu m-Transfer > Virtual Account'),
                    _buildStep('3. Masukkan nomor Virtual Account di atas'),
                    _buildStep('4. Masukkan nominal yang sesuai'),
                    _buildStep('5. Konfirmasi dan selesaikan pembayaran'),
                  ],
                ),
              ),
            ],
          ),
        );
      case 'dana':
      case 'ovo':
        final isDana = paymentId == 'dana';
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isDana ? Icons.account_balance_wallet : Icons.payment,
                    color: isDana
                        ? const Color(0xFF1089FF)
                        : const Color(0xFF4B2B9C),
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isDana ? 'DANA E-Wallet' : 'OVO',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDana
                          ? const Color(0xFF1089FF)
                          : const Color(0xFF4B2B9C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_2, size: 120, color: Colors.grey[700]),
                    const SizedBox(height: 8),
                    Text(
                      '${isDana ? "DANA" : "OVO"} QR',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Buka aplikasi ${isDana ? "DANA" : "OVO"}, pilih Scan QR, lalu scan kode di atas.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 18,
                      color: const Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pastikan saldo ${isDana ? "DANA" : "OVO"} Anda mencukupi.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case 'cod':
      default:
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.money,
                  size: 48,
                  color: Color(0xFF22C55E),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cash on Delivery',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Anda akan membayar tunai saat pesanan diterima.\n\nKurir akan menghubungi Anda sebelum pengiriman.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber,
                      size: 18,
                      color: Color(0xFFEAB308),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Siapkan uang pas untuk mempercepat proses.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildVaDetail(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ],
  );
  Widget _buildStep(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
  );
  Widget _buildDetailRow(
    String label,
    String value, {
    bool isBold = false,
    bool isDiscount = false,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isDiscount ? Colors.green[700] : const Color(0xFF0F172A),
          ),
        ),
      ],
    ),
  );

  Widget _buildSuccessView() => Center(
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
            child: Icon(Icons.check_circle, size: 60, color: Colors.green[600]),
          ),
          const SizedBox(height: 24),
          const Text(
            'Pesanan Berhasil!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _resultMessage ?? 'Pesanan Anda telah diproses',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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

  Widget _buildErrorView() => Center(
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
            child: Icon(Icons.error_outline, size: 60, color: Colors.red[600]),
          ),
          const SizedBox(height: 24),
          const Text(
            'Pembayaran Gagal',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _resultMessage ?? 'Terjadi kesalahan',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => setState(() => _resultMessage = null),
              child: const Text('Coba Lagi'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildSectionTitle(String t) => Text(
    t,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: Color(0xFF0F172A),
    ),
  );

  Widget _buildSelectAddressCard() => InkWell(
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

  Widget _buildSummaryRow(
    String label,
    double value, {
    bool isDiscount = false,
  }) => Padding(
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

  void _selectAddress() async {
    final r = await Navigator.push<CheckoutAddress>(
      context,
      MaterialPageRoute(
        builder: (ctx) => UserAddressScreen(selectedAddress: _selectedAddress),
      ),
    );
    if (r != null) setState(() => _selectedAddress = r);
  }

  void _applyPromo() async {
    final code = _promoController.text.trim().toUpperCase();
    if (code.isEmpty) {
      _showMsg('Masukkan kode promo terlebih dahulu', Colors.orange);
      return;
    }
    final p = await _dbHelper.getPromoCodeByCode(code);
    if (p != null) {
      if (!_availablePromos.any((x) => x['code'] == code))
        _availablePromos.add(p);
      setState(() => _promoCode = code);
      _showMsg('Promo "$code" berhasil diterapkan!', Colors.green);
    } else {
      try {
        _availablePromos.firstWhere((x) => x['code'] == code);
        setState(() => _promoCode = code);
        _showMsg('Promo "$code" berhasil diterapkan!', Colors.green);
      } catch (_) {
        _showMsg('Kode promo tidak valid', Colors.red);
      }
    }
  }

  void _showMsg(String msg, MaterialColor color) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: color,
        ),
      );
  }

  Future<void> _confirmCheckout() async {
    final cart = context.read<CartService>();
    final auth = AuthService();
    final txn = TransactionService();
    final user = await auth.getCurrentUser();
    if (user == null) return;
    setState(() {
      _isProcessing = true;
      _resultMessage = null;
    });
    try {
      final r = await txn.checkout(
        buyerUsername: user.username,
        cartItems: cart.items,
        totalAmount: _grandTotal,
      );
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _success = r['success'] as bool;
          _resultMessage = r['message'] as String?;
        });
        if (_success) cart.clearCart();
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _isProcessing = false;
          _success = false;
          _resultMessage = 'Terjadi kesalahan: $e';
        });
    }
  }

  String _formatPrice(double p) => p
      .toStringAsFixed(0)
      .replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
        (m) => '${m.group(1)}.',
      );
}

class _AddressCard extends StatelessWidget {
  final CheckoutAddress address;
  final VoidCallback onTap;
  const _AddressCard({required this.address, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
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
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0),
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
