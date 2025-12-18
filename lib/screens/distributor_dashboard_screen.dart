import 'package:flutter/material.dart';
import 'package:madaure/main.dart';
import 'package:madaure/models/user.dart';
import 'package:madaure/models/distributor_stats.dart';
import 'package:madaure/widgets/loading_widget.dart';
import 'add_delivery_screen.dart';
import 'add_school_screen.dart';
import 'add_payment_screen.dart';
import 'payments_list_screen.dart';

class DistributorDashboardScreen extends StatefulWidget {
  const DistributorDashboardScreen({super.key});

  @override
  State<DistributorDashboardScreen> createState() => _DistributorDashboardScreenState();
}

class _DistributorDashboardScreenState extends State<DistributorDashboardScreen> {
  // NE JAMAIS laisser _stats être null - utiliser un objet vide par défaut
  DistributorStats _stats = DistributorStats.empty();
  User? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

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
      // 1. Charger le profil utilisateur
      final userData = await apiService.fetchUserProfile();
      if (userData != null) {
        _currentUser = User.fromJson(userData);
      }

      // 2. Charger les statistiques
      print('🔄 Appel API pour dashboard...');
      final data = await apiService.fetchDistributorDashboard();

      if (mounted) {
        if (data != null) {
          print('📊 Données reçues, création des stats...');
          try {
            final newStats = DistributorStats.fromJson(data);
            setState(() {
              _stats = newStats;
              _isLoading = false;
            });
            print('✅ Stats mises à jour avec succès');
          } catch (e) {
            print('❌ Erreur parsing: $e');
            setState(() {
              _errorMessage = "Format de données invalide";
              // Garder les stats vides
              _isLoading = false;
            });
          }
        } else {
          print('⚠️ Aucune donnée reçue');
          setState(() {
            _errorMessage = "Aucune donnée disponible";
            // Garder les stats vides
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ Erreur API: $e');
      if (mounted) {
        setState(() {
          _errorMessage = "Erreur: ${e.toString()}";
          // Garder les stats vides
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Afficher le chargement
    if (_isLoading) {
      return const LoadingWidget(message: "Synchronisation des données...");
    }

    // _stats n'est jamais null car initialisé avec .empty()
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Tableau de Bord'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
          if (_errorMessage != null)
            IconButton(
              icon: const Icon(Icons.warning, color: Colors.orange),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Information'),
                    content: Text(_errorMessage ?? ''),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              tooltip: 'Afficher l\'erreur',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 20),

              // Afficher un message d'erreur si nécessaire
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.orange.shade800), // Enlevez const

                        ),
                      ),
                    ],
                  ),
                ),

              // Section Cartes
              _buildCardsSection(),
              const SizedBox(height: 20),

              // Section Paiements
              _buildPaymentsSection(),
              const SizedBox(height: 20),

              const Text("Résumé Financier",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildFinanceGrid(),

              const SizedBox(height: 30),
              const Text("Actions Rapides",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildActionList(),

              const SizedBox(height: 30),
              const Text("Dernières Activités",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade800, Colors.blue.shade500]),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Bienvenue, ${_currentUser?.name ?? 'Distributeur'}",
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text("Secteur : ${_currentUser?.wilaya ?? 'Algérie'}",
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardsSection() {
    // _stats est toujours non-null
    final int totalCards = _stats.totalCards;
    final int cardsDelivered = _stats.cardsDelivered;
    final int cardsAvailable = _stats.cardsAvailable;
    final int cardsPending = _stats.cardsPending;

    double deliveredPercent = totalCards > 0 ? (cardsDelivered / totalCards) : 0.0;

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.credit_card, color: Colors.blue),
                SizedBox(width: 10),
                Text(
                  "Gestion des Cartes",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Barre de progression globale
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Progression globale", style: TextStyle(fontWeight: FontWeight.w500)),
                Text("$cardsDelivered/$totalCards",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: deliveredPercent,
              backgroundColor: Colors.grey[200],
              color: Colors.blue,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 20),

            // Statistiques détaillées
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: [
                _cardStatItem("Total reçues", totalCards, Icons.inbox, Colors.blue),
                _cardStatItem("Livrées", cardsDelivered, Icons.check_circle, Colors.green),
                _cardStatItem("Disponibles", cardsAvailable, Icons.inventory, Colors.orange),
                _cardStatItem("En attente", cardsPending, Icons.pending, Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardStatItem(String title, int value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              Text(
                value.toString(),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsSection() {
    final double totalPaid = _stats.totalPaid;
    final double remaining = _stats.remaining;
    final double paymentRate = _stats.paymentRate;

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.payments, color: Colors.green),
                SizedBox(width: 10),
                Text(
                  "Suivi des Paiements",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Taux de paiement
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Taux de paiement", style: TextStyle(fontWeight: FontWeight.w500)),
                Text("${paymentRate.toStringAsFixed(1)}%",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: paymentRate > 70 ? Colors.green :
                        paymentRate > 40 ? Colors.orange : Colors.red
                    )),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: paymentRate / 100,
              backgroundColor: Colors.grey[200],
              color: paymentRate > 70 ? Colors.green :
              paymentRate > 40 ? Colors.orange : Colors.red,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 20),

            // Montants
            Row(
              children: [
                Expanded(
                  child: _paymentAmountItem("Total payé", totalPaid, Colors.green),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _paymentAmountItem("Reste à payer", remaining, Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentAmountItem(String title, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          const SizedBox(height: 5),
          Text(
            "${amount.toStringAsFixed(0)} DZD",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _statItem("Total Livré", _stats.totalDeliveredAmount, Colors.blue, Icons.local_shipping),
        _statItem("Total Payé", _stats.totalPaid, Colors.green, Icons.check_circle),
        _statItem("Solde Restant", _stats.remaining, Colors.red, Icons.account_balance_wallet),
        _statItem("Écoles", _stats.schoolsServed.toDouble(), Colors.orange, Icons.school),
      ],
    );
  }

  Widget _statItem(String title, double value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          FittedBox(
            child: Text(
              "${value.toStringAsFixed(0)} DZD",
              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionList() {
    return Column(
      children: [
        _actionItem("Nouvelle Livraison", Icons.add_shopping_cart, Colors.blue, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddDeliveryScreen()));
        }),
        _actionItem("Enregistrer un Paiement", Icons.payments, Colors.green, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddPaymentScreen()));
        }),
        _actionItem("Ajouter une École", Icons.school, Colors.purple, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddSchoolScreen()));
        }),
        _actionItem("Voir tous les Paiements", Icons.list, Colors.teal, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentsListScreen()));
        }),
      ],
    );
  }

  Widget _actionItem(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, size: 18),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      children: [
        // Dernières livraisons
        if (_stats.recentDeliveries.isNotEmpty) ...[
          _sectionHeader("Livraisons récentes"),
          ..._stats.recentDeliveries.take(3).map((delivery) => _buildDeliveryItem(delivery)),
        ] else ...[
          _sectionHeader("Livraisons récentes"),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Aucune livraison récente",
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
        ],

        // Derniers paiements
        if (_stats.recentPayments.isNotEmpty) ...[
          _sectionHeader("Paiements récents"),
          ..._stats.recentPayments.take(3).map((payment) => _buildPaymentItem(payment)),
        ] else if (_stats.recentDeliveries.isNotEmpty) ...[
          _sectionHeader("Paiements récents"),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Aucun paiement récent",
              style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    );
  }

  Widget _buildDeliveryItem(RecentDelivery delivery) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade50,
          child: const Icon(Icons.local_shipping, color: Colors.blue, size: 20),
        ),
        title: Text(delivery.school, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${delivery.date} • ${delivery.quantity} cartes"),
            const SizedBox(height: 4),
            Chip(
              label: Text(
                _formatStatus(delivery.status),
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
              backgroundColor: _statusColor(delivery.status),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        trailing: Text("${delivery.amount.toStringAsFixed(0)} DZD",
            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPaymentItem(RecentPayment payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade50,
          child: const Icon(Icons.payments, color: Colors.green, size: 20),
        ),
        title: Text("Paiement ${payment.method}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(payment.date),
            if (payment.reference != null) ...[
              const SizedBox(height: 4),
              Text("Ref: ${payment.reference}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ],
        ),
        trailing: Text("${payment.amount.toStringAsFixed(0)} DZD",
            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Helper methods
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'livré':
      case 'terminé':
        return Colors.green;
      case 'pending':
      case 'en attente':
        return Colors.orange;
      case 'in_progress':
      case 'en cours':
        return Colors.blue;
      case 'cancelled':
      case 'annulé':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'livré':
      case 'terminé':
        return 'Terminé';
      case 'pending':
      case 'en attente':
        return 'En attente';
      case 'in_progress':
      case 'en cours':
        return 'En cours';
      case 'cancelled':
      case 'annulé':
        return 'Annulé';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}