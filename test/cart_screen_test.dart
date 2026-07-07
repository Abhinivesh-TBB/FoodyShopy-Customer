import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_app/features/cart/presentation/cart_screen.dart';
import 'package:customer_app/features/cart/providers/cart_provider.dart';
import 'package:customer_app/shared/models/menu_item.dart';
import 'package:customer_app/core/storage/local_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('CartScreen rendering test', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await LocalCache.init();

    final container = ProviderContainer();
    
    // Add item to cart
    container.read(cartProvider.notifier).addItem(
      const MenuItem(
        id: '1',
        name: 'Pizza',
        description: 'Cheesy pizza',
        price: 250,
        imageUrl: '',
        isVeg: true,
        category: 'Food',
      ),
      'rest_1',
      'Pizza Place',
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: CartScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(CartScreen), findsOneWidget);
  });
}
