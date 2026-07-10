import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/product_service.dart';
import '../../models/product.dart';
import 'user_product_detail_screen.dart';
import 'user_home_screen.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final ProductService _productService = ProductService();
  bool _isScanned = false;

  void _handleBarcode(BarcodeCapture capture) {
    if (_isScanned) return;
    final barcode = capture.barcodes.first;
    final String? code = barcode.rawValue;

    if (code == null || code.isEmpty) return;

    setState(() => _isScanned = true);
    _controller.stop();

    _lookupProductByBarcode(code);
  }

  Future<void> _lookupProductByBarcode(String barcode) async {
    // Simulasi lookup: coba cari product berdasarkan id alternatif
    // Dalam implementasi nyata, product punya field barcodeId
    final products = await _productService.getAllProducts();
    Product? found;

    for (final p in products) {
      // Simulasi: cocokkan ID integer dengan barcode string
      if (p.id.toString() == barcode) {
        found = p;
        break;
      }
    }

    if (!mounted) return;

    if (found != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => UserProductDetailScreen(productId: found!.id!),
        ),
      );
    } else {
      _showNotFoundDialog(barcode);
    }
  }

  void _showNotFoundDialog(String barcode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(Icons.search_off, size: 30, color: Colors.grey[500]),
        ),
        title: const Text('Produk Tidak Ditemukan'),
        content: Text(
          'Barcode "$barcode" belum terdaftar di sistem kami.\n\nApakah Anda ingin melihat contoh produk?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _controller.start();
              setState(() => _isScanned = false);
            },
            child: const Text('Scan Ulang'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const UserHomeScreen()),
              );
            },
            child: const Text('Lihat Produk'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            icon: Icon(
              _controller.torchEnabled ? Icons.flash_on : Icons.flash_off,
            ),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: MobileScanner(controller: _controller, onDetect: _handleBarcode),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
