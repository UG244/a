import 'package:flutter/material.dart';
import 'user_map_picker_screen.dart';
import '../../models/checkout_address.dart';

class UserAddressScreen extends StatefulWidget {
  final CheckoutAddress? selectedAddress;
  const UserAddressScreen({super.key, this.selectedAddress});

  @override
  State<UserAddressScreen> createState() => _UserAddressScreenState();
}

class _UserAddressScreenState extends State<UserAddressScreen> {
  static final List<CheckoutAddress> _addresses = [
    CheckoutAddress(
      id: 1,
      label: 'Rumah',
      fullAddress: 'Jl. Sudirman No. 123, Denpasar, Bali 80225',
      recipient: 'John Doe',
      phone: '+62 812-3456-7890',
      isDefault: true,
    ),
    CheckoutAddress(
      id: 2,
      label: 'Kantor',
      fullAddress: 'Jl. Imam Bonjol No. 456, Denpasar, Bali 80226',
      recipient: 'John Doe',
      phone: '+62 813-9876-5432',
      isDefault: false,
    ),
  ];

  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.selectedAddress?.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Alamat'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 4.0),
            child: TextButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserMapPickerScreen()),
                );
                if (result != null && result is String) {
                  if (mounted) _showAddAddressDialog(prefilledAddress: result);
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tambah Alamat'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1E3A8A),
                backgroundColor: const Color(0xFFEFF6FF),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _addresses.length,
              itemBuilder: (context, index) {
                final address = _addresses[index];
                final isSelected = _selectedId == address.id;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedId = address.id);
                    Navigator.pop(context, address);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
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
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isSelected
                                          ? const Color(0xFF1E3A8A)
                                          : const Color(0xFF0F172A),
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
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                address.recipient,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                address.fullAddress,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? const Color(0xFF1E3A8A)
                              : const Color(0xFFCBD5E1),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
            height: 50,
            child: ElevatedButton(
              onPressed: _selectedId == null
                  ? null
                  : () {
                      final selected = _addresses.firstWhere(
                        (a) => a.id == _selectedId,
                      );
                      Navigator.pop(context, selected);
                    },
              child: const Text('Pilih Alamat'),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddAddressDialog({String? prefilledAddress}) {
    final labelController = TextEditingController();
    final recipientController = TextEditingController();
    final addressController = TextEditingController(text: prefilledAddress);
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Detail Alamat Pengiriman'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    hintText: 'Rumah/Kantor',
                  ),
                ),
                TextField(
                  controller: recipientController,
                  decoration: const InputDecoration(labelText: 'Nama Penerima'),
                ),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Alamat Lengkap (Dapat Diedit)'),
                  maxLines: 3,
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Nomor Telepon'),
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
            onPressed: () {
              if (labelController.text.isNotEmpty &&
                  recipientController.text.isNotEmpty &&
                  addressController.text.isNotEmpty &&
                  phoneController.text.isNotEmpty) {
                final newAddress = CheckoutAddress(
                  id: DateTime.now().millisecondsSinceEpoch,
                  label: labelController.text,
                  fullAddress: addressController.text,
                  recipient: recipientController.text,
                  phone: phoneController.text,
                  isDefault: _addresses.isEmpty,
                  userId: 'user-1',
                );
                setState(() {
                  _addresses.add(newAddress);
                  _selectedId = newAddress.id;
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Harap lengkapi semua kolom form'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
      ),
    );
  }
}
