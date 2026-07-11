import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../services/auth_service.dart';
import '../../services/image_service.dart';
import '../../services/firestore_service.dart';

class AdminProductFormScreen extends StatefulWidget {
  const AdminProductFormScreen({super.key});

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _productService = ProductService();
  final _authService = AuthService();
  final _imageService = ImageService();
  Product? _existingProduct;
  String _category = 'Makanan';
  String? _photoPath;
  bool _isSaving = false;

  final List<String> _categories = [
    'Makanan',
    'Minuman',
    'Pakaian',
    'Elektronik',
    'Kesehatan',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _checkAccess();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Product) {
        setState(() {
          _existingProduct = args;
          _nameController.text = args.name;
          _descriptionController.text = args.description;
          _priceController.text = args.price.toString();
          _stockController.text = args.stock.toString();
          _category = args.category;
          _photoPath = args.photoPath;
        });
      }
    });
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

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  bool get _isEditing => _existingProduct != null;

  Future<void> _pickImage() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Foto'),
        content: const Text('Ambil foto dari kamera atau galeri?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt),
                SizedBox(width: 8),
                Text('Kamera'),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.photo_library),
                SizedBox(width: 8),
                Text('Galeri'),
              ],
            ),
          ),
        ],
      ),
    );

    if (source == null) return;

    String? imagePath;
    if (source == ImageSource.camera) {
      imagePath = await _imageService.pickImageFromCamera();
    } else {
      imagePath = await _imageService.pickImageFromGallery();
    }

    if (imagePath != null && mounted) {
      setState(() => _photoPath = imagePath);
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final price = double.parse(_priceController.text);
    final stock = int.parse(_stockController.text);

    if (_isEditing) {
      final updated = _existingProduct!.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        price: price,
        stock: stock,
        photoPath: _photoPath,
        isActive: true,
      );
      await _productService.updateProduct(updated);
      // Sync ke Firestore
      _syncToFirestore(updated);
    } else {
      final product = Product(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        price: price,
        stock: stock,
        photoPath: _photoPath,
        isActive: true,
      );
      final id = await _productService.createProduct(product);
      // Sync ke Firestore
      _syncToFirestore(product.copyWith(id: id));
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _syncToFirestore(Product product) async {
    try {
      final firestore = FirestoreService();
      await firestore.init();
      await firestore.pushProduct(product);
    } catch (_) {
      // Firestore sync failure tidak kritis
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Produk' : 'Tambah Produk'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProduct,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Simpan'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo section
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _photoPath != null && _photoPath!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                Image.file(
                                  File(_photoPath!),
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, err, stack) => const Icon(
                                    Icons.broken_image,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 40,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tambah Foto',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Produk',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.shopping_bag),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama produk tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi Produk',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),

              // Category dropdown
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Harga (Rp)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harga tidak boleh kosong';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Harga harus lebih dari 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Stock
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stok',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Stok tidak boleh kosong';
                  }
                  final stock = int.tryParse(value);
                  if (stock == null || stock < 0) {
                    return 'Stok harus angka valid (>= 0)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Info text
              if (!_isEditing)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.green[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Produk akan langsung aktif dan terlihat oleh pengguna setelah disimpan.',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveProduct,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(
                    _isEditing ? 'Simpan Perubahan' : 'Simpan Produk',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
