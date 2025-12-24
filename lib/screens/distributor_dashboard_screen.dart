import 'package:flutter/material.dart';
import 'package:madaure/main.dart';
import 'package:madaure/models/user.dart';
import 'package:madaure/screens/add_delivery_screen.dart';
import 'package:madaure/screens/add_school_screen.dart';
import 'package:madaure/screens/add_payment_screen.dart';
import 'package:madaure/screens/payments_list_screen.dart';

class DistributorDashboardScreen extends StatefulWidget {
  final User? user;
  const DistributorDashboardScreen({super.key, this.user});

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

  // --- Sécurité pour transformer les valeurs dynamiques en String propre ---
  String _formatValue(dynamic value) {
    if (value == null) return "0";
    if (value is num) return value.toStringAsFixed(0);
    if (value is String) return value.isNotEmpty ? value : "0";
    return value.toString();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await apiService.fetchDistributorDashboard();
      setState(() {
        // DashboardController2.php renvoie tout dans l'objet 'data'
        _dashboardData = response['data'] ?? response;
        _isLoading = false;
      });
      debugPrint("🔍 Debug Dashboard Data: $_dashboardData");
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
      debugPrint("❌ Erreur Dashboard: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extraction des stats depuis les clés exactes de DashboardController2.php
    final String totalRevenue = _formatValue(_dashboardData?['totalRevenue']);
    final String remainingAmount = _formatValue(_dashboardData?['remainingAmount']);
    final String totalCards = _formatValue(_dashboardData?['totalCards']);
    final String paymentRate = _formatValue(_dashboardData?['paymentRate']);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Madaure - Distributeur'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await apiService.logout();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 10),
              Text('Erreur: $_errorMessage'),
              ElevatedButton(onPressed: _loadDashboardData, child: const Text("Réessayer")),
            ],
          ),
        )
            : CustomScrollView(
          slivers: [
            // 1. Profil / Header
            SliverToBoxAdapter(child: _buildHeader()),

            // 2. Boutons d'actions rapides
            SliverToBoxAdapter(child: _buildQuickActions()),

            // 3. Grille de statistiques
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _statCard('Ventes Totales', '$totalRevenue DA', Icons.trending_up, Colors.blue),
                  _statCard('Solde Dû', '$remainingAmount DA', Icons.account_balance, Colors.red),
                  _statCard('Cartes Livrées', totalCards, Icons.style, Colors.indigo),
                  _statCard('Taux Paiement', '$paymentRate%', Icons.pie_chart, Colors.teal),
                ],
              ),
            ),

            // 4. Titre Historique
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 25, 16, 10),
                child: Text(
                  'LIVRAISONS RÉCENTES',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[700], letterSpacing: 1.1),
                ),
              ),
            ),

            // 5. Liste des livraisons (recentOrders)
            _buildRecentActivityList(),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddDeliveryScreen()),
          );
          if (res == true) _loadDashboardData();
        },
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Nouvelle Livraison'),
        backgroundColor: Colors.blue.shade800,
      ),
    );
  }

  Widget _buildHeader() {
    final dist = _dashboardData?['distributor'];
    final name = dist?['name'] ?? widget.user?.name ?? 'Distributeur';
    final wilaya = dist?['wilaya'] ?? 'Non renseigné';

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 5),
      color: Colors.white,
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.blue.shade800,
            child: Text(name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bonjour, $name', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Secteur: $wilaya', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _actionBtn(Icons.school, "École", Colors.green, () async {
            final res = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddSchoolScreen()));
            if (res == true) _loadDashboardData();
          }),
          _actionBtn(Icons.payment, "Payer", Colors.orange, () async {
            final res = await Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPaymentScreen()));
            if (res == true) _loadDashboardData();
          }),
          _actionBtn(Icons.history, "Historique", Colors.purple, () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentsListScreen()))),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(title, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildRecentActivityList() {
    // Utilisation de la clé 'recentOrders' du DashboardController2.php
    final List deliveries = _dashboardData?['recentOrders'] ?? [];

    if (deliveries.isEmpty) {
      return const SliverToBoxAdapter(
        child: Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Aucune livraison enregistrée'))),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final d = deliveries[index];
          // Ton PHP renvoie 'amount' pour le prix et 'school_name' ou 'customer'
          final String price = _formatValue(d['amount']);
          final String school = d['school_name'] ?? d['customer'] ?? 'Établissement';
          final String date = d['date'] ?? '--/--/----';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.local_shipping, color: Colors.blue, size: 18),
              ),
              title: Text(school, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Text('Qté: ${d['quantity']} • $date', style: const TextStyle(fontSize: 11)),
              trailing: Text('$price DA', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ),
          );
        },
        childCount: deliveries.length,
      ),
    );
  }
}