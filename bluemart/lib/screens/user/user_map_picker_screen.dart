import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class UserMapPickerScreen extends StatefulWidget {
  const UserMapPickerScreen({super.key});

  @override
  State<UserMapPickerScreen> createState() => _UserMapPickerScreenState();
}

class _UserMapPickerScreenState extends State<UserMapPickerScreen> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(-8.673892, 115.226815); // Default to ITB STIKOM BALI
  bool _isLoading = false;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    // Use default location, uncomment _checkLocation() to auto-fetch on open
    // _checkLocation();
  }

  Future<void> _checkLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
      });
      
      if (_isMapReady) {
        _mapController.move(_center, 16.0);
      }
    } catch (_) {
      // Use default location
    }
  }

  Future<void> _confirmLocation() async {
    setState(() => _isLoading = true);
    
    // The current center of the map
    final center = _mapController.camera.center;
    
    String finalAddress = 'Koordinat: ${center.latitude}, ${center.longitude}';
    
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${center.latitude}&lon=${center.longitude}');
      final response = await http.get(url, headers: {'User-Agent': 'BlueMart/1.0'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final displayName = data['display_name'];
        if (displayName != null && displayName.isNotEmpty) {
          finalAddress = displayName;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context, finalAddress);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Lokasi'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 16.0,
              onMapReady: () {
                _isMapReady = true;
                _mapController.move(_center, 16.0);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.bluemart',
              ),
            ],
          ),
          // Center Marker
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40), // Offset to point to the center
              child: Icon(
                Icons.location_on,
                color: Colors.red,
                size: 40,
              ),
            ),
          ),
          // Bottom panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Geser peta untuk menentukan lokasi yang tepat',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _confirmLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('📍 Pilih Lokasi Ini', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
          // Recenter button
          Positioned(
            right: 16,
            bottom: 120,
            child: FloatingActionButton(
              heroTag: 'recenter',
              backgroundColor: Colors.white,
              onPressed: _checkLocation,
              child: const Icon(Icons.my_location, color: Color(0xFF1E3A8A)),
            ),
          ),
        ],
      ),
    );
  }
}
