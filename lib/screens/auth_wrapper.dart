import 'package:flutter/material.dart';
import 'package:madaure/main.dart'; // Importe apiService
import 'package:madaure/screens/login_screen.dart';
import 'package:madaure/screens/distributor_dashboard_screen.dart';
import 'package:madaure/widgets/loading_widget.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Utilise l'instance globale apiService
      await apiService.initToken();

      if (apiService.isAuthenticated) {
        // Vérifier si le token est encore valide
        try {
          final userData = await apiService.fetchUserProfile();

          // Extrait le rôle de l'utilisateur
          // Adaptez cette partie selon la structure de votre API
          final role = _extractUserRole(userData);

          setState(() {
            _isAuthenticated = true;
            _userRole = role;
            _isLoading = false;
          });
        } catch (e) {
          // Token invalide ou expiré
          print('❌ Token validation error: $e');
          await apiService.logout();
          setState(() {
            _isAuthenticated = false;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Auth check error: $e');
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
    }
  }

  // Méthode pour extraire le rôle de l'utilisateur
  String _extractUserRole(dynamic userData) {
    if (userData == null) return 'distributor';

    if (userData is Map<String, dynamic>) {
      return userData['role'] as String? ?? 'distributor';
    }

    // Si userData est un objet User
    try {
      return userData.role ?? 'distributor';
    } catch (e) {
      return 'distributor';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingWidget(message: 'Vérification de l\'authentification...');
    }

    if (!_isAuthenticated) {
      return LoginScreen(onLoginSuccess: () {
        _checkAuthStatus(); // Re-vérifier l'authentification
      });
    }

    // Redirection selon le rôle
    if (_userRole == 'distributor') {
      return const DistributorDashboardScreen();
    } else if (_userRole == 'admin' || _userRole == 'super_admin') {
      // TODO: Implémentez AdminDashboardScreen
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tableau de Bord Admin'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Interface Admin',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text('Cette fonctionnalité sera bientôt disponible'),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () async {
                  await apiService.logout();
                  _checkAuthStatus();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      );
    } else {
      // Rôle inconnu
      return Scaffold(
        appBar: AppBar(title: const Text('Erreur')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 60),
              const SizedBox(height: 20),
              const Text(
                'Rôle utilisateur non reconnu',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
              const SizedBox(height: 10),
              Text('Rôle: $_userRole'),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  await apiService.logout();
                  _checkAuthStatus();
                },
                child: const Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      );
    }
  }
}