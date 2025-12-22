import 'package:flutter/material.dart';
import 'package:madaure/main.dart';
import 'package:madaure/models/payment.dart';
import 'package:madaure/widgets/loading_widget.dart';
import 'add_payment_screen.dart';

class PaymentsListScreen extends StatefulWidget {
  const PaymentsListScreen({super.key});

  @override
  State<PaymentsListScreen> createState() => _PaymentsListScreenState();
}

class _PaymentsListScreenState extends State<PaymentsListScreen> {
  List<Payment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    try {
      final data = await apiService.fetchPayments();
      setState(() {
        _payments = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading payments: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique des Paiements')),
      body: _isLoading
          ? const LoadingWidget(message: 'Chargement...')
          : _payments.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.payments, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucun paiement enregistré'),
          ],
        ),
      )
          : ListView.builder(
        itemCount: _payments.length,
        itemBuilder: (context, index) {
          final p = _payments[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: const Icon(Icons.payment, color: Colors.green),
              title: Text('${p.amount.toStringAsFixed(2)} DZD'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date: ${p.paymentDate}'),
                  Text('Mode: ${_formatMethod(p.method)}'),
                  if (p.status != null && p.status!.isNotEmpty)
                    Text('Statut: ${p.status}'),
                ],
              ),
              trailing: Icon(
                _getMethodIcon(p.method),
                color: _getMethodColor(p.method),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddPaymentScreen())
          );
          if (result == true) {
            _loadPayments();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  String _formatMethod(String method) {
    switch (method) {
      case 'cash':
        return 'Espèce';
      case 'check':
        return 'Chèque';
      case 'bank_transfer':
        return 'Virement';
      default:
        return method;
    }
  }

  IconData _getMethodIcon(String method) {
    switch (method) {
      case 'cash':
        return Icons.money;
      case 'check':
        return Icons.description;
      case 'bank_transfer':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  Color _getMethodColor(String method) {
    switch (method) {
      case 'cash':
        return Colors.green;
      case 'check':
        return Colors.blue;
      case 'bank_transfer':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}