import 'package:flutter_test/flutter_test.dart';
import 'package:bluemart/models/product.dart';
import 'package:bluemart/models/cart_item.dart';
import 'package:bluemart/models/checkout_address.dart';
import 'package:bluemart/services/cart_service.dart';

void main() {
  group('Product model tests', () {
    test('Product serialization and deserialization from map (int vs num vs bool)', () {
      final mapFromSqlite = {
        'id': 1,
        'name': 'Kopi Susu',
        'description': 'Kopi segar',
        'category': 'Minuman',
        'price': 15000, // int in SQLite/JSON
        'stock': 20,
        'photoPath': 'kopi.png',
        'supplierId': 2,
        'isActive': 1, // int 1 in SQLite
        'createdAt': '2026-01-01T10:00:00',
        'updatedAt': '2026-01-01T10:00:00',
      };

      final product = Product.fromMap(mapFromSqlite);
      expect(product.id, 1);
      expect(product.name, 'Kopi Susu');
      expect(product.price, 15000.0);
      expect(product.price, isA<double>());
      expect(product.isActive, true);

      final mapFromFirestore = {
        'id': 2,
        'name': 'Roti Bakar',
        'description': 'Roti keju',
        'category': 'Makanan',
        'price': 25000.5,
        'stock': 10,
        'isActive': true, // boolean in Firestore
      };

      final productFs = Product.fromMap(mapFromFirestore);
      expect(productFs.id, 2);
      expect(productFs.price, 25000.5);
      expect(productFs.isActive, true);
    });

    test('Product copyWith works properly', () {
      final p1 = Product(
        id: 1,
        name: 'Teh Es',
        category: 'Minuman',
        price: 5000,
        stock: 50,
      );

      final p2 = p1.copyWith(price: 6000, stock: 45);
      expect(p2.id, 1);
      expect(p2.name, 'Teh Es');
      expect(p2.price, 6000.0);
      expect(p2.stock, 45);
    });
  });

  group('CartItem and CartService tests', () {
    test('CartItem calculation and toTransactionItem conversion', () {
      final item = CartItem(
        productId: 101,
        productName: 'Susu UHT',
        unitPrice: 18000.0,
        quantity: 3,
      );

      expect(item.subtotal, 54000.0);
      final txnItem = item.toTransactionItem(500);
      expect(txnItem['transactionId'], 500);
      expect(txnItem['productId'], 101);
      expect(txnItem['subtotal'], 54000.0);
    });

    test('CartService addItem, updateQuantity, clearCart, and totalPrice calculation', () {
      final cart = CartService();
      expect(cart.items, isEmpty);
      expect(cart.totalPrice, 0.0);

      final item1 = CartItem(productId: 1, productName: 'Biskuit', unitPrice: 12000, quantity: 1);
      final item2 = CartItem(productId: 2, productName: 'Air Mineral', unitPrice: 4000, quantity: 1);

      // Add item1 (stock 10)
      bool added = cart.addItem(item1, 10);
      expect(added, isTrue);
      expect(cart.items.length, 1);
      expect(cart.totalPrice, 12000.0);

      // Add another 1 of item1
      cart.addItem(CartItem(productId: 1, productName: 'Biskuit', unitPrice: 12000, quantity: 1), 10);
      expect(cart.items.first.quantity, 2);
      expect(cart.totalPrice, 24000.0);

      // Add item2
      cart.addItem(item2, 20);
      expect(cart.items.length, 2);
      expect(cart.totalPrice, 28000.0);

      // Update item2 quantity to 3
      cart.updateQuantity(2, 3);
      expect(cart.items.firstWhere((i) => i.productId == 2).quantity, 3);
      expect(cart.totalPrice, 36000.0); // (2*12000) + (3*4000) = 24000 + 12000 = 36000

      // Try adding item exceeding stock limit
      bool addedExceed = cart.addItem(CartItem(productId: 1, productName: 'Biskuit', unitPrice: 12000, quantity: 10), 10);
      expect(addedExceed, isFalse); // Should fail because 2 + 10 > 10

      // Update quantity <= 0 should remove item
      cart.updateQuantity(1, 0);
      expect(cart.items.length, 1);
      expect(cart.totalPrice, 12000.0); // only item2 (3*4000) remains

      cart.clearCart();
      expect(cart.items, isEmpty);
      expect(cart.totalPrice, 0.0);
    });
  });

  group('CheckoutAddress tests', () {
    test('CheckoutAddress fromMap handles flexible types', () {
      final addrMap = {
        'id': 10,
        'label': 'Rumah',
        'fullAddress': 'Jl. Mawar No 5',
        'recipient': 'Budi',
        'phone': '08123456789',
        'isDefault': 1,
      };

      final addr = CheckoutAddress.fromMap(addrMap);
      expect(addr.id, 10);
      expect(addr.label, 'Rumah');
      expect(addr.isDefault, true);
    });
  });
}
