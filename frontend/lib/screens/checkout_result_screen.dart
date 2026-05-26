import 'package:flutter/material.dart';

class CheckoutResultScreen extends StatelessWidget {
  final bool isSuccess;
  final String? errorMessage;

  const CheckoutResultScreen({
    super.key,
    required this.isSuccess,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Checkout Result",
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              size: 100,
            ),
            const SizedBox(
              height: 20,
            ),
            Text(
              isSuccess ? "Booking Successful" : "Booking Failed",
              style: const TextStyle(
                fontSize: 24,
              ),
            ),
            if (!isSuccess && errorMessage != null) ...[
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
