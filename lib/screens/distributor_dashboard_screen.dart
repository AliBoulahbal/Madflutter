import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:madaure/main.dart';
import 'package:madaure/models/user.dart';

class DistributorDashboardScreen extends StatefulWidget {
  final User? user;

  const DistributorDashboardScreen({super.key, this.user});

  @override
  State<DistributorDashboardScreen> createState() => _DistributorDashboardScreenState();
}

class _DistributorDashboardScreenState extends State<DistributorDashboardScreen> {
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _cardsStats;
  Map<String, dynamic>? _monthlySummary;
  Map<String, dynamic>? _myActivity;
  Map<String, dynamic>? _cardsStock;

  bool _isLoading = true;
  String? _errorMessage;
  String _selectedPeriod = 'month';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Charger UNIQUEMENT les données principales du dashboard
      final dashboard = await apiService.fetchDistributorDashboard();

      // NE PAS charger les statistiques supplémentaires qui n'existent pas
      // Ces endpoints retournent 404
      /*
    final List<Future> futures = [
      apiService.fetchCardsStats(),
      apiService.fetchMonthlySummary(),
      apiService.fetchMyActivity(),
      apiService.fetchCardsStock(),
    ];

    final results = await Future.wait(futures, eagerError: true);
    */

      if (mounted) {
        setState(() {
          _dashboardData = dashboard;
          // Ces données sont désactivées car les endpoints n'existent pas
          _cardsStats = {};
          _monthlySummary = {};
          _myActivity = {};
          _cardsStock = {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildLoadingScreen() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text('Chargement du tableau de bord...'),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.red),
          const SizedBox(height: 20),
          Text(
            'Erreur de chargement',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.red),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _errorMessage ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadDashboardData,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardHeader() {
    // Utilisez widget.user ou les données du dashboard
    final user = widget.user;
    final dashboardDistributor = _dashboardData?['data']?['distributor'] ?? {};
    final stats = _dashboardData?['data'] ?? {};

    // Priorité: 1. widget.user, 2. dashboard data, 3. valeurs par défaut
    final String userName = user?.name ?? dashboardDistributor['name'] ?? 'Distributeur';
    final String userWilaya = user?.wilaya ?? dashboardDistributor['wilaya'] ?? 'Non spécifiée';
    final String userPhone = user?.phone ?? dashboardDistributor['phone'] ?? '';
    final String userEmail = user?.email ?? dashboardDistributor['email'] ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade800, Colors.blue.shade600],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour, $userName',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Wilaya: $userWilaya',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  if (userPhone.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      'Tél: $userPhone',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ],
              ),
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(
                  Icons.person,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildBalanceCard(stats),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(Map<String, dynamic> stats) {
    final totalRevenue = (stats['totalRevenue'] ?? 0).toDouble();
    final totalPaid = (stats['totalPaid'] ?? 0).toDouble();
    final remainingAmount = (stats['remainingAmount'] ?? 0).toDouble();

    final NumberFormat formatter = NumberFormat('#,###');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'SOLDE À RÉCUPÉRER',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${formatter.format(remainingAmount)} DZD',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.redAccent,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn('Total Livré', '${formatter.format(totalRevenue)}', Colors.blue),
              Container(width: 1, height: 40, color: Colors.grey.shade300),
              _buildStatColumn('Total Payé', '${formatter.format(totalPaid)}', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    final stats = _cardsStats?['data'] ?? {};
    final cardsDelivered = stats['cards_delivered'] ?? 0;
    final cardsAvailable = stats['cards_available'] ?? 0;
    final cardsPending = stats['cards_pending'] ?? 0;
    final paymentRate = stats['payment_rate'] ?? 0;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.3,
      padding: const EdgeInsets.all(16),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Cartes Livrées',
          '$cardsDelivered',
          Icons.local_shipping,
          Colors.blue,
        ),
        _buildStatCard(
          'Cartes Disponibles',
          '$cardsAvailable',
          Icons.inventory_2,
          Colors.orange,
        ),
        _buildStatCard(
          'Cartes En Attente',
          '$cardsPending',
          Icons.pending,
          Colors.purple,
        ),
        _buildStatCard(
          'Taux de Paiement',
          '${paymentRate.toStringAsFixed(1)}%',
          Icons.pie_chart,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final activity = _myActivity?['data'] ?? [];

    if (activity.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Aucune activité récente',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activity.length,
      itemBuilder: (context, index) {
        final item = activity[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item['type'] == 'delivery' ? Icons.local_shipping : Icons.payments,
                  color: Colors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] ?? 'Activité',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item['description'] ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                item['date']?.split(' ')[0] ?? '',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildDashboardHeader(),
            ),
            SliverToBoxAdapter(
              child: _buildStatsGrid(),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  'ACTIVITÉ RÉCENTE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildRecentActivity(),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Naviguer vers l'ajout de livraison
          // Navigator.pushNamed(context, '/add-delivery');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fonctionnalité à implémenter')),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle Livraison'),
        backgroundColor: Colors.blue.shade700,
      ),
    );
  }
}