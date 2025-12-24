import 'package:flutter/material.dart';
import 'package:madaure/main.dart';

class AddPaymentScreen extends StatefulWidget {
  const AddPaymentScreen({super.key});

  @override
  State<AddPaymentScreen> createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  List<Map<String, dynamic>> _deliveries = [];
  int? _selectedDeliveryId;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  Future<void> _loadDeliveries() async {
    setState(() => _isLoading = true);
    try {
      final response = await apiService.fetchDeliveriesRaw();
      print("📦 API Response type: ${response.runtimeType}");

      List<dynamic> deliveriesList = [];

      if (response is List) {
        // Si c'est directement une liste
        deliveriesList = response;
        print("✅ Réponse est une List de ${deliveriesList.length} éléments");
      } else {
        // Convertir en Map pour traitement
        final responseAsMap = response as Map<String, dynamic>? ?? {};
        print("✅ Réponse traitée comme Map");

        if (responseAsMap.containsKey('deliveries') && responseAsMap['deliveries'] is List) {
          deliveriesList = responseAsMap['deliveries'] as List<dynamic>;
        } else if (responseAsMap.containsKey('data') && responseAsMap['data'] is List) {
          deliveriesList = responseAsMap['data'] as List<dynamic>;
        } else {
          // Parcourir toutes les clés pour trouver une liste
          for (var key in responseAsMap.keys) {
            if (responseAsMap[key] is List) {
              deliveriesList = responseAsMap[key] as List<dynamic>;
              print("✅ Liste trouvée dans la clé: $key");
              break;
            }
          }
        }
      }

      // Convertir en List<Map> sécurisée
      final List<Map<String, dynamic>> safeDeliveries = [];
      for (var item in deliveriesList) {
        if (item is Map) {
          try {
            safeDeliveries.add(Map<String, dynamic>.from(item));
          } catch (e) {
            print("⚠️ Erreur conversion item en Map: $e");
          }
        }
      }

      setState(() {
        _deliveries = safeDeliveries;
        _isLoading = false;
      });

      print("✅ ${_deliveries.length} livraisons chargées");
    } catch (e) {
      print("❌ Erreur chargement livraisons: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de chargement: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  // Méthode pour construire les items du dropdown
  List<DropdownMenuItem<int>> _buildDeliveryItems() {
    final items = <DropdownMenuItem<int>>[];

    for (var d in _deliveries) {
      try {
        // Extraire les données avec des valeurs par défaut
        final dynamic id = d['id'];
        final dynamic school = d['school'];
        final String schoolName = _extractSchoolName(school);

        final dynamic amount = d['final_price'] ?? d['total_price'] ?? 0;
        final String amountStr = amount.toString();

        // L'API /deliveries ne met pas à jour les soldes, donc on affiche toujours le total
        final double remaining = double.tryParse(amountStr) ?? 0;

        final String wilaya = _extractWilaya(school);

        // Convertir l'ID en int
        final int? intId = _parseDeliveryId(id);

        if (intId != null && remaining > 0) {
          items.add(
            DropdownMenuItem<int>(
              value: intId,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min, // CORRECTION ICI
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wilaya.isNotEmpty
                          ? "$schoolName ($wilaya)"
                          : schoolName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Total: $amountStr DA",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      } catch (e) {
        print("⚠️ Erreur traitement livraison: $e");
        continue;
      }
    }

    if (items.isEmpty) {
      items.add(
        const DropdownMenuItem<int>(
          value: -1,
          enabled: false,
          child: Text("Toutes les livraisons sont payées", style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    items.sort((a, b) => b.value!.compareTo(a.value!));

    return items;
  }

  // Méthodes utilitaires
  String _extractSchoolName(dynamic school) {
    if (school is Map) {
      return school['name']?.toString() ?? 'École inconnue';
    }
    return 'École inconnue';
  }

  String _extractWilaya(dynamic school) {
    if (school is Map) {
      return school['wilaya']?.toString() ?? '';
    }
    return '';
  }

  int? _parseDeliveryId(dynamic id) {
    if (id is int) {
      return id;
    } else if (id is String) {
      return int.tryParse(id);
    } else if (id is num) {
      return id.toInt();
    }
    return null;
  }

  // Méthode pour mettre à jour le montant lorsqu'une livraison est sélectionnée
  void _updateAmountFromSelectedDelivery(int deliveryId) {
    try {
      for (var d in _deliveries) {
        final int? intId = _parseDeliveryId(d['id']);

        if (intId == deliveryId) {
          final dynamic amount = d['final_price'] ?? d['total_price'] ?? 0;
          final double totalAmount = double.tryParse(amount.toString()) ?? 0;

          if (totalAmount > 0) {
            _amountController.text = totalAmount.toStringAsFixed(0);
          } else {
            _amountController.text = '0';
          }

          return;
        }
      }
    } catch (e) {
      print("❌ Erreur lors de la récupération du montant: $e");
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    if (_selectedDeliveryId == null || _selectedDeliveryId == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez une livraison valide')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final paymentAmount = double.parse(_amountController.text);

      if (paymentAmount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le montant doit être supérieur à 0'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final data = {
        'delivery_id': _selectedDeliveryId,
        'amount': paymentAmount,
        'payment_method': 'cash',
        'payment_date': DateTime.now().toIso8601String(),
        'note': _noteController.text.isNotEmpty ? _noteController.text : null,
      };

      final success = await apiService.addPayment(data);
      if (success && mounted) {
        await _loadDeliveries(); // Recharger les données

        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paiement enregistré avec succès !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      final errorMessage = e.toString();
      print("❌ Erreur paiement: $errorMessage");

      // Message d'erreur amélioré
      String userMessage = 'Erreur: $errorMessage';
      if (errorMessage.contains("dépasse le solde restant")) {
        userMessage = 'Le montant dépasse le solde réel. Essayez un montant plus petit.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau Paiement'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text(
                "Livraison concernée",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                isExpanded: true,
                value: _selectedDeliveryId,
                hint: const Text("Sélectionner une livraison"),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.local_shipping),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                ),
                items: _buildDeliveryItems(),
                onChanged: (val) {
                  setState(() {
                    _selectedDeliveryId = val;
                    if (val != null && val != -1) {
                      _updateAmountFromSelectedDelivery(val);
                    } else {
                      _amountController.clear();
                    }
                  });
                },
                validator: (v) {
                  if (v == null || v == -1) {
                    return 'Veuillez sélectionner une livraison';
                  }
                  return null;
                },
              ),

              if (_selectedDeliveryId != null && _selectedDeliveryId != -1)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 16),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          "Note: Le solde réel sera vérifié par l'API lors du paiement",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade800,
                            fontStyle: FontStyle.italic,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 25),

              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Montant versé (DA)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.money),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Veuillez entrer un montant';
                  }
                  final amount = double.tryParse(v);
                  if (amount == null) {
                    return 'Montant invalide';
                  }
                  if (amount <= 0) {
                    return 'Le montant doit être supérieur à 0';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 25),

              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Note (optionnelle)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignLabelWithHint: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                ),
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    "ENREGISTRER LE PAIEMENT",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (_deliveries.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber.shade700, size: 30),
                      const SizedBox(height: 10),
                      const Text(
                        "Aucune livraison disponible",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Vous devez d'abord créer des livraisons avant de pouvoir enregistrer un paiement.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Retour au dashboard"),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}