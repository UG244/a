import 'package:flutter/material.dart';
import '../../services/transaction_service.dart';

class AdminSalesReportScreen extends StatefulWidget {
  const AdminSalesReportScreen({super.key});

  @override
  State<AdminSalesReportScreen> createState() => _AdminSalesReportScreenState();
}

class _AdminSalesReportScreenState extends State<AdminSalesReportScreen> {
  final _transactionService = TransactionService();
  List<Map<String, dynamic>> _transactions = [];
  Map<int, List<Map<String, dynamic>>> _transactionItems = {};
  bool _isLoading = true;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
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

  void _showTransactionDetail(Map<String, dynamic> transaction) async {
    final items = await _transactionService.getTransactionItems(
      transaction['id'] as int,
    );
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              Text(
                'Transaksi #${transaction['id']}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pembeli: ${transaction['buyerUsername']}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              Text(
                'Tanggal: ${_formatDate(transaction['createdAt'] as String)}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const Divider(),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
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
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    'Rp ${_formatPrice((transaction['totalAmount'] as num).toDouble())}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
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
        title: const Text('Laporan Penjualan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _pickDateRange,
            tooltip: 'Filter Tanggal',
          ),
          if (_dateRange != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => _dateRange = null),
              tooltip: 'Hapus Filter',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTransactions,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Summary cards
                  _buildSummaryCard(
                    icon: Icons.monetization_on,
                    title: 'Total Pendapatan',
                    value: 'Rp ${_formatPrice(_totalRevenue)}',
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryCard(
                    icon: Icons.receipt_long,
                    title: 'Total Transaksi',
                    value: '${_filteredTransactions.length}',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryCard(
                    icon: Icons.shopping_bag,
                    title: 'Total Item Terjual',
                    value: '$_totalItemsSold',
                    color: Colors.purple,
                  ),

                  if (_dateRange != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Filter: ${_formatDate(_dateRange!.start.toIso8601String())} - ${_formatDate(_dateRange!.end.toIso8601String())}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Text(
                    'Daftar Transaksi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  if (_filteredTransactions.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Tidak ada transaksi',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  else
                    ..._filteredTransactions.map(
                      (t) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.green[700],
                              size: 20,
                            ),
                          ),
                          title: Text(
                            'Transaksi #${t['id']} - ${t['buyerUsername']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            _formatDate(t['createdAt'] as String),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          trailing: Text(
                            'Rp ${_formatPrice((t['totalAmount'] as num).toDouble())}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          onTap: () => _showTransactionDetail(t),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
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
