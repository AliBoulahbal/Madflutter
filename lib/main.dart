import 'package:flutter/material.dart';
import 'package:madaure/screens/auth_wrapper.dart';
import 'package:madaure/screens/add_delivery_screen.dart';
import 'package:madaure/screens/add_payment_screen.dart';
import 'package:madaure/screens/add_school_screen.dart';
import 'package:madaure/services/api_service.dart';

// Service API global
ApiService apiService = ApiService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Madaure Distribution',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/add-delivery': (context) => AddDeliveryScreen(),
        '/add-payment': (context) => AddPaymentScreen(),
        '/add-school': (context) => AddSchoolScreen(),
      },
    );
  }
}