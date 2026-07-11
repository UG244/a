import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_item.dart';

class NotificationProvider extends ChangeNotifier {
  static const String _storageKey = 'user_notifications';
  List<AppNotification> _notifications = [];
  bool _ready = false;
  bool _saving = false;

  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;
  bool get isReady => _ready;

  /// Sync init: immediately seed data, then load disk in background.
  /// Always returns with ready=true so UI never waits.
  void initSync() {
    if (_ready) return;
    _seedIfEmpty();
    _ready = true;
    notifyListeners();
    // Load saved data from disk asynchronously (will merge/override)
    _loadFromDisk();
  }

  Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) {
        _saveToDisk(); // save seeded data
        return;
      }
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      final loaded = decoded
          .map((e) {
            try {
              return AppNotification.fromMap(e as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<AppNotification>()
          .toList();
      if (loaded.isNotEmpty) {
        // Older app versions could generate several notifications in the same
        // millisecond. Duplicate ids crash Dismissible because its keys must
        // be unique, so keep only the newest valid occurrence.
        final uniqueById = <String, AppNotification>{};
        for (final notification in loaded) {
          uniqueById.putIfAbsent(notification.id, () => notification);
        }
        loaded
          ..clear()
          ..addAll(uniqueById.values);
        loaded.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _notifications = loaded;
        if (uniqueById.length != decoded.length) {
          await _saveToDisk();
        }
        notifyListeners();
      } else {
        _saveToDisk();
      }
    } catch (_) {
      _saveToDisk();
    }
  }

  void _seedIfEmpty() {
    if (_notifications.isNotEmpty) return;
    _notifications = [
      AppNotification.promo(
        title: 'Selamat Datang di BlueMart!',
        message: 'Temukan gadget dan elektronik terbaik dengan harga spesial.',
        icon: Icons.store,
        color: const Color(0xFF1E3A8A),
      ),
      AppNotification.promo(
        title: 'Promo Spesial!',
        message: 'Diskon 50% Flash Sale hari ini. Buruan sebelum kehabisan!',
      ),
      AppNotification.promo(
        title: 'Voucher Baru',
        message:
            'Dapatkan voucher belanja Rp50.000 untuk pembelian minimal Rp500.000',
      ),
    ];
  }

  void add(AppNotification notification) {
    _notifications.insert(0, notification);
    _debouncedSave();
    notifyListeners();
  }

  void markRead(String id) {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx >= 0) {
      _notifications[idx] = _notifications[idx].copyWith(isRead: true);
      _debouncedSave();
      notifyListeners();
    }
  }

  void markAllRead() {
    bool changed = false;
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) {
      _debouncedSave();
      notifyListeners();
    }
  }

  void remove(String id) {
    final oldLength = _notifications.length;
    _notifications.removeWhere((n) => n.id == id);
    if (_notifications.length != oldLength) {
      _debouncedSave();
      notifyListeners();
    }
  }

  void _debouncedSave() {
    if (_saving) return;
    _saving = true;
    Future.delayed(const Duration(milliseconds: 200), () {
      _saving = false;
      _saveToDisk();
    });
  }

  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_notifications.map((n) => n.toMap()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {}
  }
}
