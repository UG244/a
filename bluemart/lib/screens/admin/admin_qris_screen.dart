import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AdminQrisScreen extends StatefulWidget {
  const AdminQrisScreen({super.key});

  @override
  State<AdminQrisScreen> createState() => _AdminQrisScreenState();
}

class _AdminQrisScreenState extends State<AdminQrisScreen> {
  double _nominal = 0;
  final _nominalController = TextEditingController();
  String? _generatedQrData;

  @override
  void dispose() {
    _nominalController.dispose();
    super.dispose();
  }

  void _generateQRIS() {
    setState(() {
      _nominal = double.tryParse(_nominalController.text) ?? 0;
      if (_nominal > 0) {
        // Generate QRIS data string (simplified format)
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        _generatedQrData = 'BLUEMART|${_nominal.toInt()}|$timestamp|QRIS';
      } else {
        _generatedQrData = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran QRIS')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // QRIS Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.qr_code,
                    size: 48,
                    color: Color(0xFF06B6D4),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'BlueMart QRIS',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pembayaran via QRIS',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 20),
                // QR Code
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
                    ),
                  ),
                  child: _generatedQrData != null
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: QrImageView(
                            data: _generatedQrData!,
                            version: QrVersions.auto,
                            size: 168,
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
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_2,
                                size: 100,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'QRIS Code',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Scan QRIS di atas untuk melakukan pembayaran',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Set Nominal
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Atur Nominal Pembayaran',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nominalController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
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
                    onChanged: (value) {
                      setState(() {
                        _nominal = double.tryParse(value) ?? 0;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickNominal(50000),
                      _buildQuickNominal(100000),
                      _buildQuickNominal(200000),
                      _buildQuickNominal(500000),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _generateQRIS,
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Generate QRIS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6D4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Transaction History
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history, size: 18, color: Color(0xFF1E3A8A)),
                      SizedBox(width: 6),
                      Text(
                        'Riwayat Pembayaran QRIS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildQrisHistoryItem(
                    'Pembayaran #INV001',
                    'Rp 150.000',
                    'Berhasil',
                    const Color(0xFF22C55E),
                  ),
                  const Divider(height: 16),
                  _buildQrisHistoryItem(
                    'Pembayaran #INV002',
                    'Rp 75.000',
                    'Berhasil',
                    const Color(0xFF22C55E),
                  ),
                  const Divider(height: 16),
                  _buildQrisHistoryItem(
                    'Pembayaran #INV003',
                    'Rp 200.000',
                    'Gagal',
                    const Color(0xFFEF4444),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickNominal(int nominal) {
    final isSelected = _nominal == nominal;
    return GestureDetector(
      onTap: () {
        setState(() {
          _nominal = nominal.toDouble();
          _nominalController.text = nominal.toString();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF06B6D4).withValues(alpha: 0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF06B6D4) : Colors.transparent,
          ),
        ),
        child: Text(
          'Rp ${nominal ~/ 1000}rb',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFF06B6D4) : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildQrisHistoryItem(
    String title,
    String amount,
    String status,
    Color statusColor,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                amount,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }
}
