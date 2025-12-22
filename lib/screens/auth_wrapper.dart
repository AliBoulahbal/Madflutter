import 'package:flutter/material.dart';
import 'package:madaure/main.dart';
import 'package:madaure/screens/login_screen.dart';
import 'package:madaure/screens/distributor_dashboard_screen.dart';
import 'package:madaure/screens/admin_dashboard_screen.dart';
import 'package:madaure/widgets/loading_widget.dart';
import 'package:madaure/models/user.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String? _userRole;
  String? _errorMessage;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    print('🔍 Vérification de l\'authentification...');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Initialiser le token
      await apiService.initToken();
      print('🔑 Token présent: ${apiService.isAuthenticated}');

      if (apiService.isAuthenticated) {
        print('✅ Token trouvé, validation...');

        // Vérifier si le token est encore valide
        try {
          // Essayer d'abord le profil utilisateur
          final userData = await apiService.fetchUserProfile();

          if (userData != null) {
            print('👤 Profil utilisateur chargé avec succès');
            // Extraire le rôle et créer l'objet User
            final role = _extractUserRole(userData);
            _currentUser = _createUserFromData(userData, role);

            setState(() {
              _isAuthenticated = true;
              _userRole = role;
              _isLoading = false;
            });

            print('✅ Authentification réussie, rôle: $role, utilisateur: ${_currentUser?.name}');
          } else {
            // Si fetchUserProfile retourne null, essayer le dashboard
            print('⚠️ fetchUserProfile retourné null, tentative avec dashboard...');
            try {
              final dashboardData = await apiService.fetchDistributorDashboard();
              if (dashboardData.containsKey('success') && dashboardData['success'] == true) {
                // Extraire l'utilisateur depuis le dashboard
                if (dashboardData.containsKey('data') && dashboardData['data'] is Map) {
                  final data = dashboardData['data'] as Map<String, dynamic>;
                  if (data.containsKey('distributor')) {
                    final distributor = data['distributor'] as Map<String, dynamic>;

                    _currentUser = User(
                      id: distributor['id'] ?? 0,
                      name: distributor['name'] ?? 'Distributeur',
                      email: distributor['email'] ?? '',
                      phone: distributor['phone'] ?? '',
                      wilaya: distributor['wilaya'] ?? '',
                      role: 'distributor',
                    );

                    setState(() {
                      _isAuthenticated = true;
                      _userRole = 'distributor';
                      _isLoading = false;
                    });

                    print('✅ Authentification via dashboard réussie');
                    return;
                  }
                }
              }

              // Si on arrive ici, le token est invalide
              print('❌ Token invalide ou expiré');
              await _handleInvalidToken();

            } catch (e) {
              print('❌ Erreur validation via dashboard: $e');

              // Essayer le dashboard admin si l'utilisateur est admin
              if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
                print('⚠️ Accès refusé au dashboard distributeur, tentative admin...');
                try {
                  // Tester si l'utilisateur est admin
                  await apiService.fetchAdminDashboard();
                  // Si on arrive ici, c'est un admin
                  _currentUser = User(
                    id: 0,
                    name: 'Administrateur',
                    email: 'admin@system',
                    role: 'admin',
                  );

                  setState(() {
                    _isAuthenticated = true;
                    _userRole = 'admin';
                    _isLoading = false;
                  });

                  print('✅ Authentification admin réussie');
                  return;
                } catch (adminError) {
                  print('❌ Erreur admin: $adminError');
                }
              }

              await _handleInvalidToken();
            }
          }
        } catch (e) {
          // Token invalide ou expiré
          print('❌ Token validation error: $e');

          // Vérifier si c'est une erreur 401 (non autorisé)
          if (e.toString().contains('401') ||
              e.toString().contains('Unauthenticated') ||
              e.toString().contains('Unauthorized')) {
            print('🔒 Token expiré ou invalide');
            await _handleInvalidToken();
          } else {
            // Autre erreur
            print('⚠️ Autre erreur de validation: $e');
            await _handleInvalidToken();
          }
        }
      } else {
        print('🔒 Aucun token trouvé, utilisateur non authentifié');
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Auth check error: $e');
      setState(() {
        _isAuthenticated = false;
        _errorMessage = 'Erreur de vérification: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleInvalidToken() async {
    print('🔄 Nettoyage du token invalide...');
    try {
      await apiService.logout();
    } catch (e) {
      print('⚠️ Erreur lors du logout: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticated = false;
          _isLoading = false;
          _errorMessage = 'Session expirée, veuillez vous reconnecter';
          _currentUser = null;
        });
      }
    }
  }

  // Méthode pour extraire le rôle de l'utilisateur
  String _extractUserRole(dynamic userData) {
    print('🎭 Extraction du rôle depuis: $userData');

    if (userData == null) {
      print('⚠️ userData est null, rôle par défaut: distributor');
      return 'distributor';
    }

    if (userData is Map<String, dynamic>) {
      final role = userData['role'] as String?;
      print('📋 Rôle trouvé dans Map: $role');

      // Normaliser les rôles
      if (role == 'admin' || role == 'super_admin' || role == 'administrator') {
        return 'admin';
      }
      return role ?? 'distributor';
    }

    // Si userData est un objet User
    try {
      if (userData is User) {
        final role = userData.role;
        print('👤 Rôle trouvé dans User: $role');

        if (role == 'admin' || role == 'super_admin' || role == 'administrator') {
          return 'admin';
        }
        return role ?? 'distributor';
      }
    } catch (e) {
      print('❌ Erreur extraction rôle User: $e');
    }

    print('⚠️ Format non reconnu, rôle par défaut: distributor');
    return 'distributor';
  }

  // Méthode pour créer un objet User à partir des données
  User _createUserFromData(dynamic userData, String role) {
    if (userData is User) {
      return userData;
    }

    if (userData is Map<String, dynamic>) {
      return User(
        id: userData['id'] is int ? userData['id'] :
        userData['id'] is String ? int.tryParse(userData['id']) ?? 0 : 0,
        name: userData['name']?.toString() ?? 'Utilisateur',
        email: userData['email']?.toString(),
        phone: userData['phone']?.toString(),
        wilaya: userData['wilaya']?.toString(),
        role: role,
      );
    }

    // User par défaut
    return User(
      id: 0,
      name: 'Utilisateur',
      email: '',
      phone: '',
      wilaya: '',
      role: role,
    );
  }

  // Méthode pour tester les dashboards (debug)
  Future<void> _testDashboards() async {
    print('🧪 Test des dashboards...');
    try {
      // Désactivé pour éviter les erreurs de compilation
      print('Test des dashboards désactivé');
      // await apiService.testDashboardEndpoints();
    } catch (e) {
      print('❌ Erreur test dashboards: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return LoadingWidget(
        message: 'Vérification de l\'authentification...',
        errorMessage: _errorMessage,
      );
    }

    if (!_isAuthenticated) {
      return LoginScreen(
        onLoginSuccess: () {
          print('🔄 Reconnexion demandée...');
          _checkAuthStatus(); // Re-vérifier l'authentification
        },
      );
    }

    // Redirection selon le rôle
    if (_userRole == 'distributor') {
      print('🎯 Redirection vers dashboard distributeur');
      return DistributorDashboardScreen(
        user: _currentUser,
      );
    } else if (_userRole == 'admin' || _userRole == 'super_admin') {
      print('🎯 Redirection vers dashboard admin');
      return AdminDashboardScreen(
        user: _currentUser,
      );
    } else {
      // Rôle inconnu - page d'erreur
      print('❌ Rôle inconnu: $_userRole');
      return _buildUnknownRoleScreen();
    }
  }

  Widget _buildUnknownRoleScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erreur de Rôle'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkAuthStatus,
            tooltip: 'Réessayer',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _testDashboards,
            tooltip: 'Tester les endpoints',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.orange, size: 80),
              const SizedBox(height: 20),
              const Text(
                'Rôle utilisateur non reconnu',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Rôle détecté: $_userRole',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Informations utilisateur:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text('Nom: ${_currentUser?.name ?? 'Inconnu'}'),
                      Text('Email: ${_currentUser?.email ?? 'Non défini'}'),
                      Text('Téléphone: ${_currentUser?.phone ?? 'Non défini'}'),
                      Text('Wilaya: ${_currentUser?.wilaya ?? 'Non définie'}'),
                      Text('Rôle: ${_currentUser?.role ?? 'Non défini'}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      await apiService.logout();
                      _checkAuthStatus();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Se déconnecter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _checkAuthStatus,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer la connexion'),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Support Technique'),
                          content: const Text(
                            'Si ce problème persiste, contactez le support technique:\n\n'
                                'Email: support@madaure.com\n'
                                'Téléphone: 0770 00 00 00',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Fermer'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.help),
                    label: const Text('Obtenir de l\'aide'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}