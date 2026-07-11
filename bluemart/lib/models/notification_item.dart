import 'dart:convert';
import 'package:flutter/material.dart';

class AppNotification {
  static int _idSequence = 0;

  final String id;
  final String type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? orderId;
  final String iconName;
  final int iconColorValue;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.orderId,
    this.iconName = 'notifications',
    this.iconColorValue = 0xFF3B82F6,
  });

  IconData get icon => _iconFromName(iconName);
  Color get iconColor => Color(iconColorValue);

  static IconData _iconFromName(String name) {
    switch (name) {
      case 'check_circle':
        return Icons.check_circle;
      case 'pending':
        return Icons.pending;
      case 'inventory_2':
        return Icons.inventory_2;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'cancel':
        return Icons.cancel;
      case 'discount':
        return Icons.discount;
      case 'store':
        return Icons.store;
      case 'receipt_long':
        return Icons.receipt_long;
      case 'notifications':
      default:
        return Icons.notifications;
    }
  }

  static String _iconToName(IconData icon) {
    if (icon == Icons.check_circle) return 'check_circle';
    if (icon == Icons.pending) return 'pending';
    if (icon == Icons.inventory_2) return 'inventory_2';
    if (icon == Icons.local_shipping) return 'local_shipping';
    if (icon == Icons.cancel) return 'cancel';
    if (icon == Icons.discount) return 'discount';
    if (icon == Icons.store) return 'store';
    if (icon == Icons.receipt_long) return 'receipt_long';
    return 'notifications';
  }

  static String _uniqueId(String prefix) {
    _idSequence = (_idSequence + 1) & 0x7fffffff;
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}_$_idSequence';
  }

  factory AppNotification.orderStatus({
    required String orderId,
    required String statusLabel,
    IconData icon = Icons.receipt_long,
    Color color = const Color(0xFF3B82F6),
  }) {
    return AppNotification(
      id: _uniqueId('order_$orderId'),
      type: 'order',
      title: 'Status Pesanan',
      message: 'Pesanan #$orderId telah $statusLabel',
      createdAt: DateTime.now(),
      orderId: orderId,
      iconName: _iconToName(icon),
      iconColorValue: _colorToInt(color),
    );
  }

  factory AppNotification.orderSuccess(String orderId) {
    return AppNotification(
      id: _uniqueId('success_$orderId'),
      type: 'order',
      title: 'Pesanan Berhasil',
      message:
          'Pesanan #$orderId telah berhasil dibuat dan sedang menunggu konfirmasi.',
      createdAt: DateTime.now(),
      orderId: orderId,
      iconName: 'check_circle',
      iconColorValue: _colorToInt(const Color(0xFF22C55E)),
    );
  }

  factory AppNotification.promo({
    required String title,
    required String message,
    IconData icon = Icons.discount,
    Color color = const Color(0xFFF97316),
  }) {
    return AppNotification(
      id: _uniqueId('promo'),
      type: 'promo',
      title: title,
      message: message,
      createdAt: DateTime.now(),
      iconName: _iconToName(icon),
      iconColorValue: _colorToInt(color),
    );
  }

  static int _colorToInt(Color color) => color.toARGB32();

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type,
    'title': title,
    'message': message,
    'createdAt': createdAt.toIso8601String(),
    'isRead': isRead,
    'orderId': orderId,
    'iconName': iconName,
    'iconColorValue': iconColorValue,
  };

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    final isReadVal = map['isRead'];
    final bool isRead;
    if (isReadVal is bool) {
      isRead = isReadVal;
    } else if (isReadVal is int) {
      isRead = isReadVal == 1;
    } else {
      isRead = false;
    }
    return AppNotification(
      id: map['id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isRead: isRead,
      orderId: map['orderId'] as String?,
      iconName: (map['iconName'] as String?) ?? 'notifications',
      iconColorValue: (map['iconColorValue'] as int?) ?? 0xFF3B82F6,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory AppNotification.fromJson(String json) =>
      AppNotification.fromMap(jsonDecode(json) as Map<String, dynamic>);

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      message: message,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      orderId: orderId,
      iconName: iconName,
      iconColorValue: iconColorValue,
    );
  }
}
