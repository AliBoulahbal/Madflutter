import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:madaure/main.dart';
import 'package:madaure/models/user.dart';

class AdminDashboardScreen extends StatefulWidget {
  final User? user;

  const AdminDashboardScreen({super.key, this.user});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _overviewData;
  Map<String, dynamic>? _wilayaStats;
  Map<String, dynamic>? _topDistributors;
  Map<String, dynamic>? _topSchools;

  bool _isLoading = true;
  String? _errorMessage;
  String _selectedPeriod = 'month';
  int _selectedTab = 0;

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
      // Charger les données principales du dashboard admin
      final dashboard = await apiService.fetchAdminDashboard();

      // Charger les statistiques supplémentaires en parallèle
      final List<Future> futures = [
        apiService.fetchAdminOverview(),
        apiService.fetchWilayaStats(),
        apiService.fetchTopDistributors(),
        apiService.fetchTopSchools(),
      ];

      final results = await Future.wait(futures, eagerError: true);

      if (mounted) {
        setState(() {
          _dashboardData = dashboard;
          _overviewData = results[0];
          _wilayaStats = results[1];
          _topDistributors = results[2];
          _topSchools = results[3];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });

        // Gestion des erreurs d'autorisation
        if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
          // L'utilisateur n'a pas les permissions admin
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous n\'avez pas les permissions administrateur'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
          Text('Chargement du tableau de bord admin...'),
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
    final stats = _dashboardData?['statistics'] ?? {};
    final dashboardUser = _dashboardData?['user'] ?? {};

    // Priorité: 1. widget.user, 2. dashboard data, 3. valeurs par défaut
    final String userName = user?.name ?? dashboardUser['name'] ?? 'Administrateur';
    final String userEmail = user?.email ?? dashboardUser['email'] ?? '';
    final String userRole = user?.role ?? dashboardUser['role'] ?? 'admin';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.purple.shade800, Colors.purple.shade600],
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
                  const Text(
                    'Tableau de Bord Administrateur',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Bienvenue, $userName',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  if (userEmail.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Email: $userEmail',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    'Rôle: ${userRole.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: const Icon(
                  Icons.admin_panel_settings,
                  size: 30,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildAdminStatsCard(stats), // Notez le point-virgule ici
        ],
      ),
    );
  }

  Widget _buildAdminStatsCard(Map<String, dynamic> stats) {
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
            'VUE D\'ENSEMBLE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 15),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            children: [
              _buildAdminStatItem('Écoles', '${stats['total_schools'] ?? 0}', Icons.school, Colors.blue),
              _buildAdminStatItem('Distributeurs', '${stats['total_distributors'] ?? 0}', Icons.people, Colors.green),
              _buildAdminStatItem('Livraisons', '${stats['total_deliveries'] ?? 0}', Icons.local_shipping, Colors.orange),
              _buildAdminStatItem('Revenu Total', '${formatter.format(stats['total_revenue'] ?? 0)}', Icons.attach_money, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final overview = _overviewData?['overview'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistiques Globales',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          _buildStatCard(
            'Taux de Couverture GPS',
            '${overview['coverage_percentage']?.toStringAsFixed(1) ?? '0'}%',
            Icons.gps_fixed,
            Colors.teal,
          ),
          const SizedBox(height: 10),
          _buildStatCard(
            'Revenu Mensuel',
            '${NumberFormat('#,###').format(overview['monthly_revenue'] ?? 0)} DZD',
            Icons.trending_up,
            Colors.green,
          ),
          const SizedBox(height: 10),
          _buildStatCard(
            'Livraisons ce Mois',
            '${overview['monthly_deliveries'] ?? 0}',
            Icons.calendar_today,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWilayaStatsTab() {
    final wilayas = _wilayaStats?['wilaya_stats'] ?? [];

    if (wilayas.isEmpty) {
      return const Center(
        child: Text('Aucune donnée disponible'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: wilayas.length,
      itemBuilder: (context, index) {
        final wilaya = wilayas[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Text(
              '${index + 1}',
              style: const TextStyle(color: Colors.blue),
            ),
          ),
          title: Text(wilaya['wilaya'] ?? 'Inconnu'),
          subtitle: Text('${wilaya['deliveries_count'] ?? 0} livraisons'),
          trailing: Text(
            '${NumberFormat('#,###').format(wilaya['revenue'] ?? 0)} DZD',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopDistributorsTab() {
    final distributors = _topDistributors?['top_distributors'] ?? [];

    if (distributors.isEmpty) {
      return const Center(
        child: Text('Aucun distributeur trouvé'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: distributors.length,
      itemBuilder: (context, index) {
        final distributor = distributors[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getRankColor(index),
              child: Text(
                '${index + 1}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(distributor['name'] ?? 'Distributeur'),
            subtitle: Text(
              'Wilaya: ${distributor['wilaya'] ?? 'N/A'}\n'
                  '${distributor['total_deliveries'] ?? 0} livraisons',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${NumberFormat('#,###').format(distributor['total_revenue'] ?? 0)} DZD',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  '${distributor['payment_rate']?.toStringAsFixed(1) ?? '0'}% payé',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopSchoolsTab() {
    final schools = _topSchools?['top_schools'] ?? [];

    if (schools.isEmpty) {
      return const Center(
        child: Text('Aucune école trouvée'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: schools.length,
      itemBuilder: (context, index) {
        final school = schools[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.school, color: Colors.blue),
            title: Text(school['name'] ?? 'École'),
            subtitle: Text(
              '${school['wilaya'] ?? ''} - ${school['manager'] ?? ''}',
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${school['total_deliveries'] ?? 0} liv.',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${NumberFormat('#,###').format(school['total_amount'] ?? 0)} DZD',
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 0: return Colors.amber;
      case 1: return Colors.grey.shade400;
      case 2: return Colors.orange.shade300;
      default: return Colors.blue.shade300;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 300,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildDashboardHeader(),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(50),
                  child: Container(
                    color: Colors.white,
                    child: TabBar(
                      indicatorColor: Colors.purple,
                      labelColor: Colors.purple,
                      unselectedLabelColor: Colors.grey,
                      tabs: const [
                        Tab(icon: Icon(Icons.dashboard), text: 'Vue d\'ensemble'),
                        Tab(icon: Icon(Icons.map), text: 'Wilayas'),
                        Tab(icon: Icon(Icons.people), text: 'Distributeurs'),
                        Tab(icon: Icon(Icons.school), text: 'Écoles'),
                      ],
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.person),
                    onPressed: () => _showProfileDialog(context, widget.user),
                    tooltip: 'Mon Profil',
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadDashboardData,
                    tooltip: 'Rafraîchir',
                  ),
                ],
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildOverviewTab(),
              _buildWilayaStatsTab(),
              _buildTopDistributorsTab(),
              _buildTopSchoolsTab(),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            // Action d'administration
            _showAdminMenu(context);
          },
          icon: const Icon(Icons.menu),
          label: const Text('Actions'),
          backgroundColor: Colors.purple.shade700,
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context, User? user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mon Profil'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (user != null) ...[
                _buildProfileItem('Nom', user.name),
                _buildProfileItem('Email', user.email ?? 'Non défini'),
                _buildProfileItem('Téléphone', user.phone ?? 'Non défini'),
                _buildProfileItem('Wilaya', user.wilaya ?? 'Non définie'),
                _buildProfileItem('Rôle', user.role ?? 'admin'),
              ] else ...[
                const Text('Aucune information de profil disponible'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showAdminMenu(BuildContext context) {
    final user = widget.user;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Actions Administrateur',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connecté en tant que: ${user?.name ?? 'Admin'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.blue),
                title: const Text('Ajouter un Distributeur'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fonctionnalité à implémenter')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.school, color: Colors.green),
                title: const Text('Gérer les Écoles'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fonctionnalité à implémenter')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart, color: Colors.orange),
                title: const Text('Générer un Rapport'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fonctionnalité à implémenter')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.person, color: Colors.purple),
                title: const Text('Mon Profil'),
                subtitle: Text(user?.email ?? ''),
                onTap: () {
                  Navigator.pop(context);
                  _showProfileDialog(context, user);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}