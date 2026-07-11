import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/transaction_service.dart';
import 'user_main_screen.dart';

class UserOrderHistoryScreen extends StatefulWidget {
  const UserOrderHistoryScreen({super.key});

  @override
  State<UserOrderHistoryScreen> createState() => _UserOrderHistoryScreenState();
}

class _UserOrderHistoryScreenState extends State<UserOrderHistoryScreen> {
  final _transactionService = TransactionService();
  final _authService = AuthService();
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  String _selectedStatus = 'Semua';

  final List<String> _statuses = [
    'Semua',
    'Menunggu',
    'Diproses',
    'Dikirim',
    'Selesai',
    'Dibatalkan',
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final user = await _authService.getCurrentUser();
    if (user != null) {
      final isAdmin = (user.role == 'admin' || user.username == 'admin');
      final orders = isAdmin
          ? await _transactionService.getAllTransactions()
          : await _transactionService.getUserOrders(user.username);
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _orders = orders;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateOrderStatus(int orderId, String newStatus) async {
    await _transactionService.updateTransactionStatus(orderId, newStatus);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Status pesanan #$orderId berhasil diubah menjadi "$newStatus"'),
        backgroundColor: const Color(0xFF22C55E),
      ),
    );
    _loadOrders();
  }

  bool _statusMatches(String? orderStatus, String selectedStatus) {
    if (orderStatus == null) return false;
    final s = orderStatus.toLowerCase();
    final sel = selectedStatus.toLowerCase();
    if (sel == 'semua') return true;
    if (sel == 'menunggu') return s == 'menunggu' || s == 'pending';
    if (sel == 'diproses') return s == 'diproses' || s == 'processing';
    if (sel == 'dikirim') return s == 'dikirim' || s == 'shipped';
    if (sel == 'selesai') return s == 'selesai' || s == 'completed';
    if (sel == 'dibatalkan') return s == 'dibatalkan' || s == 'cancelled';
    return s == sel;
  }

  List<Map<String, dynamic>> get _filteredOrders {
    if (_selectedStatus == 'Semua') return _orders;
    return _orders
        .where((o) => _statusMatches(o['status'] as String?, _selectedStatus))
        .toList();
  }

  Map<String, dynamic> _getStatusConfig(String? status) {
    switch (status?.toLowerCase()) {
      case 'menunggu':
      case 'pending':
        return {
          'icon': Icons.pending,
          'color': const Color(0xFFEAB308),
          'bg': const Color(0xFFFEF3C7),
          'label': 'Menunggu Pembayaran',
        };
      case 'diproses':
      case 'processing':
        return {
          'icon': Icons.inventory_2,
          'color': const Color(0xFF3B82F6),
          'bg': const Color(0xFFDBEAFE),
          'label': 'Diproses',
        };
      case 'dikirim':
      case 'shipped':
        return {
          'icon': Icons.local_shipping,
          'color': const Color(0xFFF97316),
          'bg': const Color(0xFFFFEDD5),
          'label': 'Dikirim',
        };
      case 'selesai':
      case 'completed':
        return {
          'icon': Icons.check_circle,
          'color': const Color(0xFF22C55E),
          'bg': const Color(0xFFDCFCE7),
          'label': 'Selesai',
        };
      case 'dibatalkan':
      case 'cancelled':
        return {
          'icon': Icons.cancel,
          'color': const Color(0xFFEF4444),
          'bg': const Color(0xFFFEF2F2),
          'label': 'Dibatalkan',
        };
      default:
        return {
          'icon': Icons.receipt_long,
          'color': const Color(0xFF94A3B8),
          'bg': const Color(0xFFF1F5F9),
          'label': status ?? 'Pesanan',
        };
    }
  }

  void _showOrderDetail(Map<String, dynamic> order) async {
    final items = await _transactionService.getTransactionItems(
      order['id'] as int,
    );
    if (!mounted) return;
    final statusConfig = _getStatusConfig(order['status'] as String?);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 1.0,
          minChildSize: 0.3,
          maxChildSize: 1.0,
          expand: false,
          builder: (context, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: statusConfig['bg'] as Color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      statusConfig['icon'] as IconData,
                      color: statusConfig['color'] as Color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pesanan #${order['id']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          statusConfig['label'] as String,
                          style: TextStyle(
                            color: statusConfig['color'] as Color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatDate(order['createdAt'] as String),
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              const Divider(height: 24),
              const Text(
                'Produk yang Dibeli',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              ...items.map(
                (item) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['productName'] as String,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item['quantity']} x Rp ${_formatPrice((item['unitPrice'] as num).toDouble())}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Rp ${_formatPrice((item['subtotal'] as num).toDouble())}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Total Pesanan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'Rp ${_formatPrice((order['totalAmount'] as num).toDouble())}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Timeline Tracking
              const Text(
                'Status Pengiriman',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              _buildTimeline(order['status'] as String?),
              if (_isAdmin) ...[
                const Divider(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF3B82F6), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.admin_panel_settings, color: Color(0xFF1E3A8A)),
                          SizedBox(width: 8),
                          Text(
                            'Admin: Update Status Pesanan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Pilih status baru untuk pesanan ini:',
                        style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['menunggu', 'diproses', 'dikirim', 'selesai', 'dibatalkan'].map((statusOption) {
                          final isCurrent = (order['status'] as String?)?.toLowerCase() == statusOption;
                          final cfg = _getStatusConfig(statusOption);
                          return ChoiceChip(
                            label: Text(cfg['label'] as String),
                            selected: isCurrent,
                            selectedColor: cfg['color'] as Color,
                            labelStyle: TextStyle(
                              color: isCurrent ? Colors.white : (cfg['color'] as Color),
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            backgroundColor: cfg['bg'] as Color,
                            onSelected: isCurrent
                                ? null
                                : (selected) async {
                                    if (selected) {
                                      await _updateOrderStatus(order['id'] as int, statusOption);
                                      if (context.mounted) Navigator.pop(context);
                                    }
                                  },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  label: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan'),
        automaticallyImplyLeading: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
            )
          : Column(
              children: [
                // Status filter chips
                Container(
                  height: 48,
                  color: Colors.white,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    children: _statuses.map((status) {
                      final isSelected = _selectedStatus == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedStatus = status),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF1E3A8A)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF475569),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 0),
                // Orders list
                Expanded(
                  child: _filteredOrders.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFEFF6FF),
                                      Color(0xFFDBEAFE),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF1E3A8A,
                                      ).withValues(alpha: 0.08),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.receipt_long_outlined,
                                  size: 50,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Belum ada pesanan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ayo mulai berbelanja!',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  if (!UserMainScreen.switchToTab(context, 0)) {
                                    Navigator.pushReplacementNamed(context, '/user-home');
                                  }
                                },
                                icon: const Icon(Icons.shopping_bag, size: 18),
                                label: const Text('Belanja Sekarang'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1E3A8A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadOrders,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = _filteredOrders[index];
                              return _buildOrderCard(order);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final statusConfig = _getStatusConfig(order['status'] as String?);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showOrderDetail(order),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusConfig['bg'] as Color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  statusConfig['icon'] as IconData,
                  color: statusConfig['color'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Pesanan #${order['id']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: (statusConfig['bg'] as Color).withValues(
                              alpha: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            statusConfig['label'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: statusConfig['color'] as Color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          _formatDate(order['createdAt'] as String),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Rp ${_formatPrice((order['totalAmount'] as num).toDouble())}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ],
                    ),
                    if (_isAdmin && order['buyerUsername'] != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Pembeli: ${order['buyerUsername']}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF3B82F6)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.edit, size: 11, color: Color(0xFF1E3A8A)),
                                SizedBox(width: 3),
                                Text(
                                  'Update Status',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agu',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoDate;
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

  Widget _buildTimeline(String? status) {
    final steps = [
      _TimelineStep('Pesanan Dibuat', Icons.receipt, true),
      _TimelineStep(
        'Pembayaran Dikonfirmasi',
        Icons.payment,
        _isStepReached(status, 1),
      ),
      _TimelineStep('Diproses', Icons.inventory_2, _isStepReached(status, 2)),
      _TimelineStep('Dikirim', Icons.local_shipping, _isStepReached(status, 3)),
      _TimelineStep('Selesai', Icons.check_circle, _isStepReached(status, 4)),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          _buildTimelineDot(steps[i]),
          if (i < steps.length - 1)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 2,
                color: steps[i + 1].reached
                    ? const Color(0xFF1E3A8A)
                    : const Color(0xFFE2E8F0),
              ),
            ),
        ],
      ],
    );
  }

  bool _isStepReached(String? status, int step) {
    final index = _getStatusIndex(status);
    return index >= step;
  }

  int _getStatusIndex(String? status) {
    switch (status?.toLowerCase()) {
      case 'dibatalkan':
      case 'cancelled':
        return -1;
      case 'menunggu':
      case 'pending':
        return 0;
      case 'diproses':
      case 'processing':
        return 1;
      case 'dikirim':
      case 'shipped':
        return 2;
      case 'selesai':
      case 'completed':
        return 4;
      default:
        return 0;
    }
  }

  Widget _buildTimelineDot(_TimelineStep step) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: step.reached
                ? const Color(0xFF1E3A8A)
                : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            step.icon,
            size: 14,
            color: step.reached ? Colors.white : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          step.label,
          style: TextStyle(
            fontSize: 9,
            color: step.reached
                ? const Color(0xFF1E3A8A)
                : const Color(0xFF94A3B8),
            fontWeight: step.reached ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _TimelineStep {
  final String label;
  final IconData icon;
  final bool reached;
  _TimelineStep(this.label, this.icon, this.reached);
}
