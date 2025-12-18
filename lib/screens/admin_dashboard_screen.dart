import 'package:flutter/material.dart';
import 'package:madaure/main.dart';
import 'package:madaure/screens/auth_wrapper.dart';
import 'add_delivery_screen.dart';
import 'add_school_screen.dart';
import 'add_payment_screen.dart';

class DistributorDashboardScreen extends StatefulWidget {
  const DistributorDashboardScreen({super.key});

  @override
  State<DistributorDashboardScreen> createState() => _DistributorDashboardScreenState();
}

class _DistributorDashboardScreenState extends State<DistributorDashboardScreen> {
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    print('🔄 Chargement des données du dashboard...');

    try {
      // Test d'authentification
      await apiService.initToken();
      print('🔑 Token présent: ${apiService.isAuthenticated}');

      if (!apiService.isAuthenticated) {
        throw Exception('Utilisateur non authentifié. Veuillez vous reconnecter.');
      }

      print('📊 Appel API pour le dashboard...');
      final data = await apiService.fetchDistributorDashboard();
      print('✅ Données reçues avec succès');
      print('📦 Clés des données: ${data.keys.toList()}');

      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Erreur de chargement du dashboard: $e');

      String errorMessage = 'Impossible de charger les données';

      // Messages d'erreur plus conviviaux
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        errorMessage = 'Serveur inaccessible. Vérifiez votre connexion.';
      } else if (e.toString().contains('401') ||
          e.toString().contains('Unauthenticated') ||
          e.toString().contains('token')) {
        errorMessage = 'Session expirée. Veuillez vous reconnecter.';

        // Déconnexion automatique
        await apiService.logout();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const AuthWrapper()),
                (Route<dynamic> route) => false,
          );
          return;
        }
      }

      setState(() {
        _errorMessage = errorMessage;
        _isLoading = false;
      });
    }
  }

  void _onLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await apiService.logout();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthWrapper()),
                      (Route<dynamic> route) => false,
                );
              }
            },
            child: const Text('Déconnexion', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Tableau de Bord'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Rafraîchir',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _onLogout,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    if (_dashboardData == null) {
      return _buildEmptyScreen();
    }

    final data = _dashboardData!;

    // Extraction sécurisée des données
    final Map<String, dynamic> distributorInfo = data['distributor'] is Map
        ? Map<String, dynamic>.from(data['distributor'])
        : {};

    final String distributorName = distributorInfo['name']?.toString() ?? 'Distributeur';
    final String distributorWilaya = distributorInfo['wilaya']?.toString() ?? 'Non spécifiée';

    final int totalOrders = _safeParseInt(data['totalOrders']);
    final int pendingDeliveries = _safeParseInt(data['pendingDeliveries']);
    final int completedToday = _safeParseInt(data['completedToday']);
    final double totalRevenue = _safeParseDouble(data['totalRevenue']);
    final double totalPaid = _safeParseDouble(data['totalPaid']);
    final double remainingAmount = _safeParseDouble(data['remainingAmount']);
    final int monthlyDeliveries = _safeParseInt(data['monthlyDeliveries']);
    final double monthlyRevenue = _safeParseDouble(data['monthlyRevenue']);
    final int assignedSchools = _safeParseInt(data['assignedSchools']);

    final List<dynamic> recentOrders = data['recentOrders'] is List
        ? List<dynamic>.from(data['recentOrders'])
        : [];

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Carte de bienvenue
          _buildWelcomeCard(distributorName, distributorWilaya),
          const SizedBox(height: 20),

          // Carte de synthèse financière
          _buildBalanceCard(totalRevenue, totalPaid, remainingAmount),
          const SizedBox(height: 20),

          // Grille de statistiques
          _buildStatsGrid(
            totalOrders: totalOrders,
            pendingDeliveries: pendingDeliveries,
            completedToday: completedToday,
            monthlyDeliveries: monthlyDeliveries,
            monthlyRevenue: monthlyRevenue,
            assignedSchools: assignedSchools,
          ),
          const SizedBox(height: 20),

          // Commandes récentes
          _buildRecentOrders(recentOrders),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(
            'Chargement du tableau de bord...',
            style: TextStyle(fontSize: 16, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 20),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AuthWrapper()),
                      (route) => false,
                );
              },
              icon: const Icon(Icons.login),
              label: const Text('Retour à la connexion'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, color: Colors.blue, size: 60),
          const SizedBox(height: 20),
          const Text(
            'Aucune donnée disponible',
            style: TextStyle(fontSize: 18, color: Colors.blue),
          ),
          const SizedBox(height: 10),
          const Text(
            'Veuillez rafraîchir ou vérifier votre connexion',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh),
            label: const Text('Rafraîchir'),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(String name, String wilaya) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenue, $name!',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Wilaya: $wilaya',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Date: ${_formatDate(DateTime.now())}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info, color: Colors.blue),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Informations'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nom: $name'),
                        Text('Wilaya: $wilaya'),
                        Text('Dernière mise à jour: ${DateTime.now().toString()}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double totalRevenue, double totalPaid, double remainingAmount) {
    final Color remainingColor = remainingAmount > 0 ? Colors.red.shade700 : Colors.green.shade700;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.blue),
                SizedBox(width: 10),
                Text(
                  'Synthèse Financière',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            _buildStatRow('Total Livré', totalRevenue, Colors.green.shade700),
            _buildStatRow('Total Payé', totalPaid, Colors.teal.shade700),
            _buildStatRow(
              'Solde Restant',
              remainingAmount,
              remainingColor,
              isLarge: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, double value, Color color, {bool isLarge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isLarge ? 16 : 14,
              fontWeight: isLarge ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${value.toStringAsFixed(2)} DZD',
            style: TextStyle(
              fontSize: isLarge ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid({
    required int totalOrders,
    required int pendingDeliveries,
    required int completedToday,
    required int monthlyDeliveries,
    required double monthlyRevenue,
    required int assignedSchools,
  }) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.2,
      children: [
        _buildMiniStatCard('Total Commandes', totalOrders.toString(), Icons.shopping_cart, Colors.indigo),
        _buildMiniStatCard('En Attente', pendingDeliveries.toString(), Icons.pending, Colors.orange),
        _buildMiniStatCard('Aujourd\'hui', completedToday.toString(), Icons.today, Colors.green),
        _buildMiniStatCard('Mensuel', monthlyDeliveries.toString(), Icons.calendar_month, Colors.blue),
        _buildMiniStatCard('Revenu Mensuel', '${monthlyRevenue.toStringAsFixed(2)} DZD', Icons.monetization_on, Colors.purple),
        _buildMiniStatCard('Écoles', assignedSchools.toString(), Icons.school, Colors.teal),
      ],
    );
  }

  Widget _buildMiniStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrders(List<dynamic> recentOrders) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history, color: Colors.blue),
                SizedBox(width: 10),
                Text(
                  'Activité Récente',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            if (recentOrders.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(
                  child: Text(
                    'Aucune activité récente',
                    style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                  ),
                ),
              )
            else
              ...recentOrders.take(5).map((order) => _buildOrderItem(order)).toList(),
            if (recentOrders.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fonctionnalité de liste complète à venir'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Text('Voir tout'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(dynamic order) {
    final Map<String, dynamic> orderData = order is Map<String, dynamic>
        ? Map<String, dynamic>.from(order)
        : {};

    final customer = orderData['customer']?.toString() ?? 'Client';
    final status = orderData['status']?.toString() ?? 'Inconnu';
    final amount = _safeParseDouble(orderData['amount']);
    final date = orderData['date']?.toString() ?? 'Date inconnue';
    final quantity = _safeParseInt(orderData['quantity']);

    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.info;
    String statusText = status;

    switch (status.toLowerCase()) {
      case 'completed':
      case 'livré':
      case 'terminé':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Terminé';
        break;
      case 'pending':
      case 'en attente':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'En attente';
        break;
      case 'in_progress':
      case 'en cours':
        statusColor = Colors.blue;
        statusIcon = Icons.local_shipping;
        statusText = 'En cours';
        break;
      case 'cancelled':
      case 'annulé':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Annulé';
        break;
    }

    return ListTile(
      leading: Icon(statusIcon, color: statusColor),
      title: Text(customer),
      subtitle: Text('$date • $quantity unités • ${amount.toStringAsFixed(2)} DZD'),
      trailing: Chip(
        label: Text(statusText, style: const TextStyle(fontSize: 12, color: Colors.white)),
        backgroundColor: statusColor,
        visualDensity: VisualDensity.compact,
      ),
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Détails: $customer - $statusText'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          isScrollControlled: true,
          builder: (context) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Actions Rapides',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.add_shopping_cart, color: Colors.blue),
                  title: const Text('Nouvelle Livraison'),
                  subtitle: const Text('Avec géolocalisation GPS'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddDeliveryScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.school, color: Colors.purple),
                  title: const Text('Ajouter une École'),
                  subtitle: const Text('Nouveau point de distribution'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddSchoolScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.payments, color: Colors.teal),
                  title: const Text('Enregistrer un Paiement'),
                  subtitle: const Text('Suivi des encaissements'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddPaymentScreen()),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fermer'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      label: const Text('Nouvelle Action'),
      icon: const Icon(Icons.add),
      backgroundColor: Colors.blue.shade600,
      foregroundColor: Colors.white,
    );
  }

  // Helper methods
  int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }

  double _safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    if (value is num) return value.toDouble();
    return 0.0;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}