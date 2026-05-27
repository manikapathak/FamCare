import 'package:flutter_riverpod/flutter_riverpod.dart';

final cartProvider = NotifierProvider<CartNotifier, List<Map<String, dynamic>>>(
  CartNotifier.new,
);

class CartNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() {
    return [];
  }

  void addItem(Map<String, dynamic> item) {
    state = [...state, item];
  }

  void removeItem(int index) {
    if (index >= 0 && index < state.length) {
      state = [...state..removeAt(index)];
    }
  }

  void clearCart() {
    state = [];
  }
}
