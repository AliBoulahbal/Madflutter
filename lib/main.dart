import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'screens/auth_wrapper.dart';

// Instance globale du service API
final ApiService apiService = ApiService();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Madaure Distribution',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}