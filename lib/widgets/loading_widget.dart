import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  final String message;
  final String? errorMessage;

  const LoadingWidget({
    super.key,
    required this.message,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(fontSize: 16, color: Colors.blue),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.orange.shade800),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}