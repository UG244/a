import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static const String _storageKey = 'user_notifications';
  
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Menambahkan notifikasi baru
  Future<void> addNotification(String title, String message, {String type = 'pesanan'}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Ambil list notifikasi yang sudah ada
    List<String> notificationsList = prefs.getStringList(_storageKey) ?? [];
    
    // Buat object notifikasi baru
    final newNotification = {
      'title': title,
      'message': message,
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': false,
    };
    
    // Tambahkan ke paling awal (terbaru di atas)
    notificationsList.insert(0, jsonEncode(newNotification));
    
    // Simpan kembali ke SharedPreferences
    await prefs.setStringList(_storageKey, notificationsList);
  }

  /// Mengambil semua notifikasi
  Future<List<Map<String, dynamic>>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> notificationsList = prefs.getStringList(_storageKey) ?? [];
    
    return notificationsList.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
  }

  /// Menghapus semua notifikasi
  Future<void> clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
