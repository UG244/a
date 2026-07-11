import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../models/checkout_address.dart';

class UserAddressScreen extends StatefulWidget {
  final CheckoutAddress? selectedAddress;
  const UserAddressScreen({super.key, this.selectedAddress});

  @override
  State<UserAddressScreen> createState() => _UserAddressScreenState();
}

class _UserAddressScreenState extends State<UserAddressScreen> {
  final List<CheckoutAddress> _addresses = [
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
  bool _isLocatingList = false;

  Future<void> _fetchLocationForList() async {
    const String defaultAddress = 'ITB STIKOM BALI RENON, Jl. Raya Puputan No.86, Dangin Puri Klod, Kec. Denpasar Tim., Kota Denpasar, Bali 80234';
    
    setState(() => _isLocatingList = true);
    String finalAddress = defaultAddress;
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.denied && permission != LocationPermission.deniedForever) {
          Position position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 10),
            ),
          );

          final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}');
          final response = await http.get(url, headers: {'User-Agent': 'BlueMart/1.0'});

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final displayName = data['display_name'];
            if (displayName != null && displayName.isNotEmpty) {
              finalAddress = displayName;
            }
          }
        }
      }
    } catch (_) {
      // Abaikan dan gunakan default
    }

    if (mounted) {
      final newAddress = CheckoutAddress(
        id: DateTime.now().millisecondsSinceEpoch,
        label: 'Lokasi Anda',
        fullAddress: finalAddress,
        recipient: 'Pengguna',
        phone: '-',
        isDefault: _addresses.isEmpty,
        userId: 'user-1',
      );
      setState(() {
        _addresses.insert(0, newAddress);
        _selectedId = newAddress.id;
        _isLocatingList = false;
      });
      // Otomatis memilih dan kembali ke checkout
      Navigator.pop(context, newAddress);
    }
  }

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
        actions: [
          TextButton.icon(
            onPressed: () => _showAddAddressDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Tambah'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLocatingList ? null : _fetchLocationForList,
                icon: _isLocatingList 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location, size: 18),
                label: Text(_isLocatingList ? 'Mencari Lokasi...' : 'Gunakan Lokasi Saat Ini'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: const Color(0xFF1E3A8A),
                  side: const BorderSide(color: Color(0xFF1E3A8A)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                maxLines: 1,
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

  void _showAddAddressDialog() {
    final labelController = TextEditingController();
    final recipientController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    bool isLocating = false;

    Future<void> fetchLocation(StateSetter setDialogState) async {
      const String defaultAddress = 'ITB STIKOM BALI RENON, Jl. Raya Puputan No.86, Dangin Puri Klod, Kec. Denpasar Tim., Kota Denpasar, Bali 80234';
      
      setDialogState(() => isLocating = true);
      try {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) throw Exception('Service disabled');

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) throw Exception('Permission denied');
        }
        if (permission == LocationPermission.deniedForever) throw Exception('Permission denied forever');

        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );

        final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}');
        final response = await http.get(url, headers: {'User-Agent': 'BlueMart/1.0'});

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final displayName = data['display_name'];
          if (displayName != null && displayName.isNotEmpty) {
            addressController.text = displayName;
          } else {
            addressController.text = defaultAddress;
          }
        } else {
          addressController.text = defaultAddress;
        }
      } catch (e) {
        addressController.text = defaultAddress;
      } finally {
        if (mounted) {
          setDialogState(() => isLocating = false);
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Tambah Alamat Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: isLocating ? null : () => fetchLocation(setDialogState),
                  icon: isLocating 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location, size: 18),
                  label: Text(isLocating ? 'Mencari Lokasi...' : 'Gunakan Lokasi Saat Ini'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1E3A8A),
                    side: const BorderSide(color: Color(0xFF1E3A8A)),
                  ),
                ),
                const SizedBox(height: 8),
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
                  decoration: const InputDecoration(labelText: 'Alamat Lengkap'),
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
