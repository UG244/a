import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/checkout_address.dart';
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

  final List<Map<String, dynamic>> _availablePromos = [
    {
      'code': 'FLASH50',
      'discountPercent': 0.50,
      'minPurchase': 500000,
      'freeShipping': false,
    },
    {
      'code': 'FREESHIP',
      'discountPercent': 0,
      'minPurchase': 200000,
      'freeShipping': true,
    },
  ];

  double get _shippingCost {
    if (_selectedShipping == null) return 0;
    final method = _shippingMethods.firstWhere(
      (m) => m['id'] == _selectedShipping,
      orElse: () => _shippingMethods.first,
    );
    return method['cost'] as double;
  }

  double get _subtotal {
    return context.read<CartService>().totalPrice;
  }

  double get _discount {
    if (_promoCode == null) return 0;
    final promo = _availablePromos.firstWhere(
      (p) => p['code'] == _promoCode,
      orElse: () => <String, dynamic>{},
    );
    return promo.isNotEmpty
        ? (_subtotal * (promo['discountPercent'] as double))
        : 0;
  }

  double get _tax => (_subtotal - _discount) * 0.11;
  double get _grandTotal => _subtotal + _shippingCost + _tax - _discount;

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

              // Promo Code
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
      bottomNavigationBar: Container(
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
          content: Text('Kode promo tidak valid'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _confirmCheckout() async {
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
