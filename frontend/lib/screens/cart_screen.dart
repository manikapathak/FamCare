import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../providers/cart_provider.dart';
import 'checkout_result_screen.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cart"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cart.length,
              itemBuilder: (context, index) {
                final item = cart[index];

                return ListTile(
                  title: Text(item["start_time"]),
                  subtitle: Text(item["date"]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      ref.read(cartProvider.notifier).removeItem(index);
                    },
                  ),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final cart = ref.read(cartProvider);

              try {
                final response = await ApiService().checkoutCart(
                  1, // temporary patient id

                  cart,
                );

                print("Checkout success");

                print(response.data);

                ref.read(cartProvider.notifier).clearCart();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CheckoutResultScreen(
                      isSuccess: true,
                    ),
                  ),
                );
              } on DioException catch (e) {
                String errorMessage = "Booking failed";

                if (e.response?.data != null && e.response?.data is Map) {
                  final detail = e.response?.data['detail'];
                  if (detail != null) {
                    errorMessage = detail.toString();
                  }
                }

                print("Checkout failed: $errorMessage");

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutResultScreen(
                      isSuccess: false,
                      errorMessage: errorMessage,
                    ),
                  ),
                );
              } catch (e) {
                print("Checkout failed: $e");

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CheckoutResultScreen(
                      isSuccess: false,
                      errorMessage: e.toString(),
                    ),
                  ),
                );
              }
            },
            child: const Text("Checkout"),
          )
        ],
      ),
    );
  }
}
