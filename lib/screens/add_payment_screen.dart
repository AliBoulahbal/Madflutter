import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:madaure/main.dart';
import 'package:madaure/models/delivery.dart';

class AddPaymentScreen extends StatefulWidget {
  final bool refreshNeeded;
  const AddPaymentScreen({super.key, this.refreshNeeded = false});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  Delivery? _selectedDelivery;
  List<Delivery> _deliveries = [];
  bool _isLoading = true;
  String _selectedMethod = 'cash';

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  Future<void> _loadDeliveries() async {
    setState(() => _isLoading = true);
    try {
      final List<Delivery> data = await apiService.fetchDeliveries();
      // Filter deliveries that have an outstanding balance
      final pending = data.where((d) => (d.finalPrice - (d.paidAmount ?? 0)) > 0).toList();

      if (mounted) {
        setState(() {
          _deliveries = pending;
          if (_deliveries.isNotEmpty) {
            _selectedDelivery = _deliveries.first;
            final remaining = _selectedDelivery!.finalPrice - (_selectedDelivery!.paidAmount ?? 0);
            _amountController.text = remaining.toStringAsFixed(2);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _submitPayment() async {
    if (_selectedDelivery == null || !_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text) ?? 0;
    setState(() => _isLoading = true);

    try {
      final success = await apiService.addPayment({
        'delivery_id': _selectedDelivery!.id,
        'amount': amount,
        'payment_method': _selectedMethod,
        'payment_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      });

      if (mounted && success) {
        Navigator.pop(context, {'success': true, 'amount': amount});
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enregistrer un Paiement')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deliveries.isEmpty
          ? const Center(child: Text('Aucune livraison impayée'))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<Delivery>(
                value: _selectedDelivery,
                items: _deliveries.map((d) => DropdownMenuItem(value: d, child: Text(d.schoolName))).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedDelivery = val;
                    _amountController.text = (val!.finalPrice - (val.paidAmount ?? 0)).toStringAsFixed(2);
                  });
                },
                decoration: const InputDecoration(labelText: 'Sélectionner la livraison'),
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Montant'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _submitPayment, child: const Text('Confirmer le Paiement')),
            ],
          ),
        ),
      ),
    );
  }
}