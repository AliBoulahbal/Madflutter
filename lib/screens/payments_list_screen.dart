import 'package:flutter/material.dart';
import 'package:madaure/main.dart';
import 'package:madaure/widgets/loading_widget.dart';
import 'add_payment_screen.dart'; // Assurez-vous que ce fichier existe

class PaymentsListScreen extends StatefulWidget {
  const PaymentsListScreen({super.key});

  @override
  State<PaymentsListScreen> createState() => _PaymentsListScreenState();
}

class _PaymentsListScreenState extends State<PaymentsListScreen> {
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final paymentsData = await apiService.fetchPayments();
      setState(() {
        _payments = paymentsData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de chargement des paiements: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des Paiements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayments,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Chargement des paiements...')
          : _payments.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.payments, size: 60, color: Colors.grey),
            const SizedBox(height: 20),
            const Text(
              'Aucun paiement enregistré',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  // CORRECTION: Enlever const ici
                  MaterialPageRoute(builder: (context) => AddPaymentScreen()),
                );
              },
              child: const Text('Ajouter un paiement'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadPayments,
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: _payments.length,
          itemBuilder: (context, index) {
            final payment = _payments[index];
            return _buildPaymentCard(payment, index);
          },
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Icon(
            _getPaymentMethodIcon(payment['method'] ?? 'cash'),
            color: Colors.green,
          ),
        ),
        title: Text(
          'Paiement #${index + 1}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Méthode: ${payment['method'] ?? 'Non spécifié'}'),
            if (payment['reference'] != null) Text('Référence: ${payment['reference']}'),
            Text('Date: ${payment['payment_date'] ?? payment['date'] ?? 'Non spécifiée'}'),
          ],
        ),
        trailing: Text(
          '${payment['amount']} DZD',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
        ),
        onTap: () {
          _showPaymentDetails(payment);
        },
      ),
    );
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'check':
        return Icons.description;
      case 'bank_transfer':
        return Icons.account_balance;
      case 'mobile_money':
        return Icons.phone_android;
      default:
        return Icons.payments;
    }
  }

  void _showPaymentDetails(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails du paiement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Montant', '${payment['amount']} DZD'),
            _detailRow('Méthode', payment['method'] ?? 'Non spécifié'),
            _detailRow('Date', payment['payment_date'] ?? payment['date'] ?? 'Non spécifiée'),
            if (payment['reference'] != null) _detailRow('Référence', payment['reference']),
            if (payment['delivery_id'] != null) _detailRow('Livraison ID', payment['delivery_id'].toString()),
            if (payment['note'] != null) _detailRow('Note', payment['note']),
          ],
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

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}