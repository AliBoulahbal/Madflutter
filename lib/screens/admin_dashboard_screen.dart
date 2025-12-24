import 'package:flutter/material.dart';
import 'package:madaure/main.dart';
import 'package:madaure/models/user.dart';

class AdminDashboardScreen extends StatefulWidget {
  final User? user;
  const AdminDashboardScreen({super.key, this.user});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final res = await apiService.fetchAdminDashboard();
      setState(() {
        _data = res['data'] ?? res;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administration'), backgroundColor: Colors.indigo),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildGlobalStats(),
            const SizedBox(height: 20),
            const Text("ACTIONS DE GESTION", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _adminTile(Icons.people, "Distributeurs", "Gérer les comptes", Colors.blue),
            _adminTile(Icons.school, "Écoles", "Liste et Localisations", Colors.green),
            _adminTile(Icons.analytics, "Rapports Wilayas", "Statistiques de vente", Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalStats() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Chiffre d'Affaires Global", style: TextStyle(color: Colors.grey)),
            Text("${_data?['total_sales'] ?? 0} DA", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniStat("Écoles", "${_data?['total_schools'] ?? 0}"),
                _miniStat("Cartes", "${_data?['total_cards'] ?? 0}"),
                _miniStat("Dettes", "${_data?['pending_payments'] ?? 0} DA"),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _adminTile(IconData icon, String title, String sub, Color color) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color)),
        title: Text(title),
        subtitle: Text(sub),
        trailing: const Icon(Icons.chevron_right),
        onTap: () { /* Navigation vers les listes CRUD */ },
      ),
    );
  }
}