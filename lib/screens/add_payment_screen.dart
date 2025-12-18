import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:madaure/services/api_service.dart';
import 'package:madaure/models/delivery.dart';

class AddPaymentScreen extends StatefulWidget {
  const AddPaymentScreen({super.key});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final ApiService apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();

  Delivery? _selectedDelivery;
  DateTime? _selectedDate;
  String? _selectedMethod;
  List<Delivery> _deliveries = [];
  bool _isLoading = false;
  bool _loadingDeliveries = true;

  final List<String> _paymentMethods = ['cash', 'check', 'bank_transfer', 'mobile_money'];

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
    _selectedDate = DateTime.now();
  }

  Future<void> _loadDeliveries() async {
    setState(() => _loadingDeliveries = true);
    try {
      final deliveriesData = await apiService.fetchMyDeliveries();

      // Convertir List<Map> en List<Delivery>
      final List<Delivery> deliveries = deliveriesData.map((deliveryMap) {
        return Delivery.fromJson(deliveryMap);
      }).toList();

      // Filtrer UNIQUEMENT les livraisons actives/payables
      final filteredDeliveries = deliveries.where((delivery) {
        // Condition 1: La livraison doit être "completed", "confirmed" ou "approved"
        final isStatusValid = delivery.status.toLowerCase() == 'completed' ||
            delivery.status.toLowerCase() == 'confirmed' ||
            delivery.status.toLowerCase() == 'approved' ||
            delivery.status.toLowerCase() == 'livré' ||
            delivery.status.toLowerCase() == 'terminé';

        // Condition 2: La livraison doit avoir un solde à payer
        final remaining = delivery.remainingAmount ??
            delivery.finalPrice - (delivery.paidAmount ?? 0);

        return isStatusValid && remaining > 0;
      }).toList();

      setState(() {
        _deliveries = filteredDeliveries;
        _loadingDeliveries = false;
      });
    } catch (e) {
      print('Error loading deliveries: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement des livraisons: $e')),
        );
        setState(() => _loadingDeliveries = false);
      }
    }
  }

  Future<void> _submitPayment() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez corriger les erreurs dans le formulaire')),
      );
      return;
    }

    if (_selectedDelivery == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une livraison')),
      );
      return;
    }

    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une méthode de paiement')),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une date de paiement')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    final String reference = _referenceController.text.trim();

    // Vérifier que le montant ne dépasse pas le solde restant
    final delivery = _selectedDelivery!;
    final remainingAmount = delivery.remainingAmount ??
        delivery.finalPrice - (delivery.paidAmount ?? 0);

    if (amount > remainingAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le montant ne peut pas dépasser le solde restant: ${remainingAmount.toStringAsFixed(2)} DZD')),
      );
      setState(() => _isLoading = false);
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le montant doit être supérieur à 0')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      // Utilise la méthode addPayment avec date de paiement
      await apiService.addPayment(
        deliveryId: delivery.id,
        amount: amount,
        paymentMethod: _selectedMethod!,
        reference: reference.isEmpty ? null : reference,
        paymentDate: DateFormat('yyyy-MM-dd').format(_selectedDate!), // Format attendu par l'API
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paiement enregistré avec succès!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      print('❌ Erreur d\'enregistrement du paiement: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de l\'enregistrement: ${e.toString()}')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un Paiement'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: _loadingDeliveries
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Informations générales
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informations du paiement',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sélectionnez une livraison active avec solde à payer',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Seules les livraisons "terminées" ou "confirmées" sont listées',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Date du paiement (OBLIGATOIRE selon votre API)
              const Text(
                'Date du paiement *',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _showDatePicker,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date de paiement',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    prefixIcon: const Icon(Icons.calendar_today, color: Colors.green),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate != null
                            ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                            : 'Sélectionner une date',
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Liste déroulante des livraisons
              const Text(
                'Livraison à payer *',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<Delivery>(
                decoration: InputDecoration(
                  labelText: 'Choisir une livraison active',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                value: _selectedDelivery,
                items: _deliveries.map((delivery) {
                  final remaining = delivery.remainingAmount ??
                      delivery.finalPrice - (delivery.paidAmount ?? 0);
                  final displayText = '${delivery.formattedDate} - ${delivery.schoolName} - '
                      '${delivery.status} - Solde: ${remaining.toStringAsFixed(2)} DZD';

                  return DropdownMenuItem<Delivery>(
                    value: delivery,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${delivery.formattedDate} - ${delivery.schoolName}',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(delivery.status),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _formatStatus(delivery.status),
                                style: const TextStyle(fontSize: 10, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Solde: ${remaining.toStringAsFixed(2)} DZD',
                              style: TextStyle(
                                fontSize: 12,
                                color: remaining > 0 ? Colors.red.shade700 : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (Delivery? newValue) {
                  setState(() => _selectedDelivery = newValue);
                  // Mettre à jour le montant suggéré
                  if (newValue != null) {
                    final remaining = newValue.remainingAmount ??
                        newValue.finalPrice - (newValue.paidAmount ?? 0);
                    _amountController.text = remaining.toStringAsFixed(2);
                  }
                },
                validator: (value) => value == null ? 'Veuillez sélectionner une livraison' : null,
                isExpanded: true,
              ),

              const SizedBox(height: 20),

              // Méthode de paiement
              const Text(
                'Méthode de paiement *',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Choisir une méthode',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                value: _selectedMethod,
                items: _paymentMethods.map((method) {
                  String displayText = method.toUpperCase().replaceAll('_', ' ');
                  IconData icon;

                  switch (method) {
                    case 'cash':
                      icon = Icons.money;
                      break;
                    case 'check':
                      icon = Icons.description;
                      break;
                    case 'bank_transfer':
                      icon = Icons.account_balance;
                      break;
                    case 'mobile_money':
                      icon = Icons.phone_android;
                      break;
                    default:
                      icon = Icons.payments;
                  }

                  return DropdownMenuItem<String>(
                    value: method,
                    child: Row(
                      children: [
                        Icon(icon, size: 20, color: Colors.green.shade700),
                        const SizedBox(width: 10),
                        Text(displayText),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() => _selectedMethod = newValue);
                },
                validator: (value) => value == null ? 'Veuillez sélectionner une méthode' : null,
              ),

              const SizedBox(height: 20),

              // Montant (OBLIGATOIRE selon votre API)
              const Text(
                'Montant du paiement *',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Montant (DZD)',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixIcon: const Icon(Icons.monetization_on, color: Colors.green),
                  suffixText: 'DZD',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer un montant';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Montant invalide';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Référence (Note - optionnelle)
              const Text(
                'Référence / Note (optionnelle)',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _referenceController,
                decoration: InputDecoration(
                  labelText: 'Référence (numéro de chèque, transaction, etc.)',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  prefixIcon: const Icon(Icons.receipt, color: Colors.green),
                  helperText: 'Cette information sera enregistrée comme "note" dans le système',
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 30),

              // Bouton d'enregistrement
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.check_circle),
                  label: _isLoading
                      ? const Text('Enregistrement en cours...')
                      : const Text(
                    'ENREGISTRER LE PAIEMENT',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // Message si aucune livraison
              if (_deliveries.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        const Text(
                          'Aucune livraison active avec solde à payer',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Seules les livraisons "terminées" ou "confirmées" sont listées',
                          style: TextStyle(color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Vérifiez aussi que la livraison a un solde restant à payer',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: _loadDeliveries,
                          child: const Text('Rafraîchir la liste'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods pour le statut
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'confirmed':
      case 'approved':
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
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'confirmed':
      case 'approved':
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
      case 'rejected':
        return 'Annulé';
      default:
        return status;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }
}