import 'dart:convert';

import 'package:bluemart/models/notification_item.dart';
import 'package:bluemart/providers/notification_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('notifications created consecutively always have unique ids', () {
    final notifications = List.generate(
      20,
      (index) => AppNotification.promo(
        title: 'Promo $index',
        message: 'Pesan $index',
      ),
    );

    expect(notifications.map((item) => item.id).toSet(), hasLength(20));
  });

  test('provider removes duplicate ids restored from older storage', () async {
    final duplicate = AppNotification(
      id: 'legacy-duplicate',
      type: 'promo',
      title: 'Promo lama',
      message: 'Data dari versi lama',
      createdAt: DateTime(2026, 7, 11),
    );
    SharedPreferences.setMockInitialValues({
      'user_notifications': jsonEncode([
        duplicate.toMap(),
        duplicate.toMap(),
      ]),
    });

    final provider = NotificationProvider()..initSync();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(provider.notifications, hasLength(1));
    expect(provider.notifications.single.id, 'legacy-duplicate');
  });
}
