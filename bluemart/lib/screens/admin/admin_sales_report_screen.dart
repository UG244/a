import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../services/transaction_service.dart';
import '../../services/auth_service.dart';
import '../../database/db_helper.dart';

class AdminSalesReportScreen extends StatefulWidget {
  const AdminSalesReportScreen({super.key});

  @override
  State<AdminSalesReportScreen> createState() => _AdminSalesReportScreenState();
}

class _AdminSalesReportScreenState extends State<AdminSalesReportScreen> {
  final _transactionService = TransactionService();
  final _authService = AuthService();
  List<Map<String, dynamic>> _transactions = [];
  Map<int, List<Map<String, dynamic>>> _transactionItems = {};
  bool _isLoading = true;
  DateTimeRange? _dateRange;
  int _currentTabIndex = 0; // 0 = Diagram Statistik, 1 = Daftar Transaksi

  @override
  void initState() {
    super.initState();
    _checkAccess();
    _loadTransactions();
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

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final transactions = await _transactionService.getAllTransactions();
      final Map<int, List<Map<String, dynamic>>> itemsMap = {};
      for (final t in transactions) {
        final id = t['id'] as int;
        final items = await _transactionService.getTransactionItems(id);
        itemsMap[id] = items;
      }
      if (mounted) {
        setState(() {
          _transactions = transactions;
          _transactionItems = itemsMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_dateRange == null) return _transactions;
    return _transactions.where((t) {
      try {
        final date = DateTime.parse(t['createdAt'] as String);
        return date.isAfter(
              _dateRange!.start.subtract(const Duration(days: 1)),
            ) &&
            date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      } catch (_) {
        return false;
      }
    }).toList();
  }

  double get _totalRevenue => _filteredTransactions.fold(
    0.0,
    (sum, t) => sum + (t['totalAmount'] as num).toDouble(),
  );

  int get _totalItemsSold => _filteredTransactions.fold(0, (sum, t) {
    final items = _transactionItems[t['id'] as int] ?? [];
    return sum + items.fold(0, (s, i) => s + (i['quantity'] as int));
  });

  // Aggregated data for Weekly Revenue Bar Chart
  List<Map<String, dynamic>> get _weeklySales {
    final Map<String, double> revenueMap = {};
    final Map<String, int> countMap = {};
    final Map<String, DateTime> sortKeyMap = {};
    final Map<String, String> shortLabelMap = {};

    final now = DateTime.now();
    // Pre-populate last 4 weeks so admin always sees a nice 4-week trend bar
    for (int i = 3; i >= 0; i--) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1 + (i * 7)));
      final weekEnd = weekStart.add(const Duration(days: 6));
      final fullLabel = '${weekStart.day}/${weekStart.month} - ${weekEnd.day}/${weekEnd.month}';
      final shortLabel = i == 0 ? 'Mgg Ini' : (i == 1 ? 'Mgg Lalu' : '$i Mgg\nLalu');

      revenueMap[fullLabel] = 0.0;
      countMap[fullLabel] = 0;
      sortKeyMap[fullLabel] = DateTime(weekStart.year, weekStart.month, weekStart.day);
      shortLabelMap[fullLabel] = shortLabel;
    }

    for (final t in _filteredTransactions) {
      final iso = t['createdAt'] as String? ?? '';
      String fullLabel = 'Minggu Ini';
      String shortLabel = 'Mgg Ini';
      DateTime sortKey = now;
      try {
        final date = DateTime.parse(iso);
        final monday = date.subtract(Duration(days: date.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        fullLabel = '${monday.day}/${monday.month} - ${sunday.day}/${sunday.month}';
        sortKey = DateTime(monday.year, monday.month, monday.day);

        final diffWeeks = now.difference(monday).inDays ~/ 7;
        if (diffWeeks == 0) {
          shortLabel = 'Mgg Ini';
        } else if (diffWeeks == 1) {
          shortLabel = 'Mgg Lalu';
        } else if (diffWeeks > 1 && diffWeeks <= 4) {
          shortLabel = '$diffWeeks Mgg\nLalu';
        } else {
          shortLabel = '${monday.day}/${monday.month}';
        }
      } catch (_) {}

      final amount = (t['totalAmount'] as num?)?.toDouble() ?? 0.0;
      revenueMap[fullLabel] = (revenueMap[fullLabel] ?? 0.0) + amount;
      countMap[fullLabel] = (countMap[fullLabel] ?? 0) + 1;
      if (!sortKeyMap.containsKey(fullLabel) || sortKey.isBefore(sortKeyMap[fullLabel]!)) {
        sortKeyMap[fullLabel] = sortKey;
        shortLabelMap[fullLabel] = shortLabel;
      }
    }

    final List<Map<String, dynamic>> result = [];
    revenueMap.forEach((week, rev) {
      result.add({
        'week': week,
        'shortLabel': shortLabelMap[week] ?? week,
        'revenue': rev,
        'orders': countMap[week] ?? 0,
        'sortKey': sortKeyMap[week] ?? now,
      });
    });

    result.sort((a, b) => (a['sortKey'] as DateTime).compareTo(b['sortKey'] as DateTime));
    return result;
  }

  // Aggregated data for Status Donut Chart
  Map<String, int> get _statusCounts {
    final Map<String, int> counts = {
      'selesai': 0,
      'dikirim': 0,
      'diproses': 0,
      'menunggu': 0,
      'dibatalkan': 0,
    };
    for (final t in _filteredTransactions) {
      final status = (t['status'] as String? ?? 'menunggu').toLowerCase();
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  // Aggregated data for Top Selling Products
  List<Map<String, dynamic>> get _topProducts {
    final Map<String, int> qtyMap = {};
    final Map<String, double> revMap = {};

    for (final t in _filteredTransactions) {
      final id = t['id'] as int;
      final items = _transactionItems[id] ?? [];
      for (final item in items) {
        final name = item['productName'] as String? ?? 'Produk Toko';
        final qty = (item['quantity'] as num?)?.toInt() ?? 1;
        final sub = (item['subtotal'] as num?)?.toDouble() ?? 0.0;
        qtyMap[name] = (qtyMap[name] ?? 0) + qty;
        revMap[name] = (revMap[name] ?? 0.0) + sub;
      }
    }

    final List<Map<String, dynamic>> list = [];
    qtyMap.forEach((name, qty) {
      list.add({
        'name': name,
        'quantity': qty,
        'revenue': revMap[name] ?? 0.0,
      });
    });

    list.sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));
    return list.take(5).toList();
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  Future<void> _updateTransactionStatus(
    int transactionId,
    String newStatus,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified, color: Color(0xFF1E3A8A)),
            SizedBox(width: 8),
            Text('Konfirmasi Update Status'),
          ],
        ),
        content: Text('Ubah status pesanan menjadi "$newStatus"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Update'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final dbHelper = DbHelper();
        await dbHelper.updateTransactionStatus(transactionId, newStatus);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status berhasil diupdate menjadi $newStatus'),
              backgroundColor: const Color(0xFF22C55E),
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadTransactions();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal update status: $e'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _showStatusUpdateDialog(Map<String, dynamic> transaction) {
    final currentStatus = transaction['status'] as String? ?? 'menunggu';
    final statusOptions = [
      {'value': 'menunggu', 'label': 'Menunggu Pembayaran', 'icon': Icons.pending},
      {'value': 'diproses', 'label': 'Diproses', 'icon': Icons.inventory_2},
      {'value': 'dikirim', 'label': 'Dikirim', 'icon': Icons.local_shipping},
      {'value': 'selesai', 'label': 'Selesai', 'icon': Icons.check_circle},
      {'value': 'dibatalkan', 'label': 'Dibatalkan', 'icon': Icons.cancel},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Update Status Pesanan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transaksi #${transaction['id']}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                'Status saat ini: ${_getStatusLabel(currentStatus)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text('Pilih status baru:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...statusOptions.map((status) {
                final isSelected = currentStatus == status['value'];
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    if (!isSelected) {
                      _updateTransactionStatus(
                        transaction['id'] as int,
                        status['value'] as String,
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1E3A8A).withValues(alpha: 0.1) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          status['icon'] as IconData,
                          color: isSelected ? const Color(0xFF1E3A8A) : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            status['label'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: Color(0xFF1E3A8A), size: 20),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'menunggu':
        return 'Menunggu Pembayaran';
      case 'diproses':
        return 'Diproses';
      case 'dikirim':
        return 'Dikirim';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status ?? 'Unknown';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'menunggu':
        return const Color(0xFFEAB308);
      case 'diproses':
        return const Color(0xFF3B82F6);
      case 'dikirim':
        return const Color(0xFFF97316);
      case 'selesai':
        return const Color(0xFF22C55E);
      case 'dibatalkan':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  void _showTransactionDetail(Map<String, dynamic> transaction) async {
    final items = _transactionItems[transaction['id'] as int] ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detail Transaksi #${transaction['id']}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(transaction['status'] as String?).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusLabel(transaction['status'] as String?),
                      style: TextStyle(
                        color: _getStatusColor(transaction['status'] as String?),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Waktu: ${_formatDate(transaction['createdAt'] as String)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const Divider(height: 24),
              const Text('Daftar Produk:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['productName'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '${item['quantity']} x Rp ${_formatPrice((item['unitPrice'] as num).toDouble())}',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Rp ${_formatPrice((item['subtotal'] as num).toDouble())}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showStatusUpdateDialog(transaction);
                },
                icon: const Icon(Icons.update),
                label: const Text('Update Status Pesanan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Text('Laporan & Analisis Penjualan', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range, color: Colors.white),
            onPressed: _pickDateRange,
            tooltip: 'Filter Tanggal',
          ),
          if (_dateRange != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.amber),
              onPressed: () => setState(() => _dateRange = null),
              tooltip: 'Hapus Filter',
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F172A)))
          : RefreshIndicator(
              onRefresh: _loadTransactions,
              color: const Color(0xFF0F172A),
              child: CustomScrollView(
                slivers: [
                  // Top Summary Bar
                  SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.only(top: 16, bottom: 20, left: 16, right: 16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
                        ),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildCompactHeaderCard(
                                  icon: Icons.account_balance_wallet,
                                  title: 'Total Pendapatan',
                                  value: 'Rp ${_formatPrice(_totalRevenue)}',
                                  color: const Color(0xFF22C55E),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildCompactHeaderCard(
                                  icon: Icons.receipt_long,
                                  title: 'Total Transaksi',
                                  value: '${_filteredTransactions.length} Pesanan',
                                  color: const Color(0xFF3B82F6),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildCompactHeaderCard(
                                  icon: Icons.shopping_bag,
                                  title: 'Barang Terjual',
                                  value: '$_totalItemsSold Item',
                                  color: const Color(0xFFF97316),
                                ),
                              ),
                            ],
                          ),
                          if (_dateRange != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.filter_alt, size: 14, color: Colors.amber),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Filter Aktif: ${_formatDateOnly(_dateRange!.start)} s/d ${_formatDateOnly(_dateRange!.end)}',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Mode Toggle Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTabButton(
                                title: '📊 Diagram Statistik',
                                isSelected: _currentTabIndex == 0,
                                onTap: () => setState(() => _currentTabIndex = 0),
                              ),
                            ),
                            Expanded(
                              child: _buildTabButton(
                                title: '📝 Riwayat Pesanan (${_filteredTransactions.length})',
                                isSelected: _currentTabIndex == 1,
                                onTap: () => setState(() => _currentTabIndex = 1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Tab 0: Diagram Statistik Dashboard
                  if (_currentTabIndex == 0) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWeeklyRevenueBarChart(),
                            const SizedBox(height: 16),
                            _buildOrderStatusDonutChart(),
                            const SizedBox(height: 16),
                            _buildTopProductsChart(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // Tab 1: Transaction List
                    if (_filteredTransactions.isEmpty)
                      SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum ada riwayat transaksi penjualan',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final t = _filteredTransactions[index];
                            final status = t['status'] as String? ?? 'menunggu';
                            return Container(
                              margin: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(status).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.receipt_rounded, color: _getStatusColor(status), size: 24),
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Order #${t['id']} • ${t['buyerUsername']}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _getStatusLabel(status),
                                        style: TextStyle(
                                          color: _getStatusColor(status),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _formatDate(t['createdAt'] as String),
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                      Text(
                                        'Rp ${_formatPrice((t['totalAmount'] as num).toDouble())}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: () => _showTransactionDetail(t),
                              ),
                            );
                          },
                          childCount: _filteredTransactions.length,
                        ),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeaderCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Diagram 1: Weekly Revenue Bar Chart
  Widget _buildWeeklyRevenueBarChart() {
    final data = _weeklySales;
    double maxRev = 0;
    for (final d in data) {
      final r = d['revenue'] as double;
      if (r > maxRev) maxRev = r;
    }
    if (maxRev == 0) maxRev = 100000;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bar_chart, color: Color(0xFF3B82F6), size: 22),
                  SizedBox(width: 8),
                  Text('Grafik Tren Pendapatan Mingguan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
              Icon(Icons.info_outline, size: 18, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 4),
          Text('Perbandingan pendapatan omzet mingguan (per 7 hari) toko BlueMart', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 24),
          if (data.isEmpty)
            const SizedBox(
              height: 180,
              child: Center(child: Text('Belum ada data grafik pendapatan mingguan.')),
            )
          else
            SizedBox(
              height: 220,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: data.map((d) {
                  final rev = d['revenue'] as double;
                  final orders = d['orders'] as int;
                  final week = d['week'] as String;
                  final shortLabel = d['shortLabel'] as String? ?? week;
                  final heightRatio = rev / maxRev;
                  final barHeight = math.max(heightRatio * 150.0, 16.0);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Tooltip(
                            message: 'Periode: $week\nPendapatan: Rp ${_formatPrice(rev)}\nTotal: $orders pesanan',
                            child: Column(
                              children: [
                                Text(
                                  rev >= 1000000
                                      ? '${(rev / 1000000).toStringAsFixed(1)}Jt'
                                      : (rev >= 1000 ? '${(rev / 1000).toStringAsFixed(0)}Rbi' : _formatPrice(rev)),
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 600),
                                  curve: Curves.easeOutCubic,
                                  height: barHeight,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            shortLabel,
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$orders Ord',
                            style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // Diagram 2: Order Status Donut Chart
  Widget _buildOrderStatusDonutChart() {
    final counts = _statusCounts;
    final total = _filteredTransactions.length;

    final statusList = [
      {'key': 'selesai', 'label': 'Selesai', 'color': const Color(0xFF22C55E)},
      {'key': 'dikirim', 'label': 'Dikirim', 'color': const Color(0xFFF97316)},
      {'key': 'diproses', 'label': 'Diproses', 'color': const Color(0xFF3B82F6)},
      {'key': 'menunggu', 'label': 'Menunggu', 'color': const Color(0xFFEAB308)},
      {'key': 'dibatalkan', 'label': 'Dibatalkan', 'color': const Color(0xFFEF4444)},
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart, color: Color(0xFFF97316), size: 22),
              SizedBox(width: 8),
              Text('Diagram Komposisi Status Pesanan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Proporsi persentase dari $total total pesanan masuk', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 24),
          if (total == 0)
            const SizedBox(height: 180, child: Center(child: Text('Belum ada transaksi untuk dipetakan.')))
          else
            Row(
              children: [
                // Center Donut
                Expanded(
                  flex: 5,
                  child: Center(
                    child: SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: const Size(140, 140),
                            painter: _OrderStatusPiePainter(counts: counts, total: total),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$total',
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              Text('Transaksi', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Legend list
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: statusList.map((st) {
                      final key = st['key'] as String;
                      final label = st['label'] as String;
                      final color = st['color'] as Color;
                      final cnt = counts[key] ?? 0;
                      final pct = total > 0 ? (cnt / total * 100).toStringAsFixed(0) : '0';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                label,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text(
                              '$cnt ($pct%)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // Diagram 3: Top Selling Products
  Widget _buildTopProductsChart() {
    final topList = _topProducts;
    int maxQty = 0;
    for (final p in topList) {
      final q = p['quantity'] as int;
      if (q > maxQty) maxQty = q;
    }
    if (maxQty == 0) maxQty = 1;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.leaderboard, color: Color(0xFF22C55E), size: 22),
              SizedBox(width: 8),
              Text('Peringkat Produk Terlaris', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text('Daftar 5 barang toko dengan jumlah penjualan tertinggi', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(height: 20),
          if (topList.isEmpty)
            const SizedBox(height: 120, child: Center(child: Text('Belum ada produk yang terjual.')))
          else
            ...topList.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final item = entry.value;
              final name = item['name'] as String;
              final qty = item['quantity'] as int;
              final rev = item['revenue'] as double;
              final progress = qty / maxQty;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '#$idx. $name',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '$qty Terjual (Rp ${_formatPrice(rev)})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: Colors.grey[100],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          idx == 1
                              ? const Color(0xFF22C55E)
                              : (idx == 2 ? const Color(0xFF3B82F6) : const Color(0xFF64748B)),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  String _formatDateOnly(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
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
}

class _OrderStatusPiePainter extends CustomPainter {
  final Map<String, int> counts;
  final int total;

  _OrderStatusPiePainter({required this.counts, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) {
      final paint = Paint()
        ..color = Colors.grey[200]!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 22;
      canvas.drawCircle(Offset(size.width / 2, size.height / 2), size.width / 2 - 12, paint);
      return;
    }

    final rect = Rect.fromLTWH(12, 12, size.width - 24, size.height - 24);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.butt;

    double startAngle = -math.pi / 2;

    final colorMap = {
      'selesai': const Color(0xFF22C55E),
      'dikirim': const Color(0xFFF97316),
      'diproses': const Color(0xFF3B82F6),
      'menunggu': const Color(0xFFEAB308),
      'dibatalkan': const Color(0xFFEF4444),
    };

    counts.forEach((status, count) {
      if (count > 0) {
        final sweepAngle = (count / total) * 2 * math.pi;
        paint.color = colorMap[status] ?? Colors.grey;
        canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
        startAngle += sweepAngle;
      }
    });
  }

  @override
  bool shouldRepaint(covariant _OrderStatusPiePainter oldDelegate) {
    return oldDelegate.counts != counts || oldDelegate.total != total;
  }
}
