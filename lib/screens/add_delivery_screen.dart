import 'package:flutter/material.dart';
import 'package:madaure/main.dart';
import 'package:madaure/models/school.dart';
import 'package:madaure/models/delivery.dart';
import 'package:geolocator/geolocator.dart';

class AddDeliveryScreen extends StatefulWidget {
  const AddDeliveryScreen({super.key});

  @override
  State<AddDeliveryScreen> createState() => _AddDeliveryScreenState();
}

class _AddDeliveryScreenState extends State<AddDeliveryScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController(text: "1000");

  List<School> _schools = [];
  List<Delivery> _deliveries = [];
  int? _selectedSchoolId;
  Position? _currentPos;
  bool _isLoading = true;
  bool _isSubmitting = false;

  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    _initData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDeliveries() async {
    try {
      final deliveries = await apiService.fetchDeliveries();
      if (mounted) {
        setState(() {
          _deliveries = deliveries;
        });
      }
    } catch (e) {
      debugPrint("❌ Erreur chargement livraisons: $e");
    }
  }

  Future<void> _initData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // 1. GPS (Optionnel)
      try {
        _currentPos = await apiService.getCurrentLocation();
      } catch (e) {
        debugPrint("GPS non dispo: $e");
      }

      // 2. Charger les écoles
      final dynamic responseData = await apiService.fetchSchools();

      List<School> tempSchools = [];

      try {
        if (responseData is Map<String, dynamic> && responseData.containsKey('schools')) {
          final schoolsData = responseData['schools'];
          if (schoolsData is Map<String, dynamic> && schoolsData.containsKey('data')) {
            final dataList = schoolsData['data'] as List<dynamic>;

            for (var e in dataList) {
              try {
                if (e is Map<String, dynamic>) {
                  tempSchools.add(School.fromJson(e));
                }
              } catch (e) {
                debugPrint("❌ Erreur parsing école: $e");
              }
            }
          }
        }
      } catch (e) {
        debugPrint("❌ Erreur lors du traitement des données: $e");
      }

      // Filtrer les écoles valides et trier
      tempSchools = tempSchools.where((school) => school.id != 0).toList();
      tempSchools.sort((a, b) => a.name.compareTo(b.name));

      // 3. Charger les livraisons
      await _loadDeliveries();

      if (mounted) {
        setState(() {
          _schools = tempSchools;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Erreur critique init livraison: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur chargement: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedSchoolId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une école')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final qty = int.parse(_qtyController.text);
      final price = double.parse(_priceController.text);

      final Map<String, dynamic> data = {
        'school_id': _selectedSchoolId,
        'quantity': qty,
        'unit_price': price,
        'final_price': qty * price,
        'delivery_date': DateTime.now().toIso8601String().split('T')[0],
        'latitude': _currentPos?.latitude ?? 0.0,
        'longitude': _currentPos?.longitude ?? 0.0,
      };

      final success = await apiService.addDelivery(data);
      if (success && mounted) {
        // Recharger les livraisons après ajout
        await _loadDeliveries();

        // Basculer vers l'onglet des livraisons
        _tabController.animateTo(0);

        // Réinitialiser le formulaire
        _formKey.currentState?.reset();
        _selectedSchoolId = null;
        _priceController.text = "1000";
        _qtyController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Livraison enregistrée avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception("Échec de l'enregistrement");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildDeliveryCard(Delivery delivery) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (delivery.status?.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        statusText = 'Terminé';
        statusIcon = Icons.check_circle;
        break;
      case 'confirmed':
        statusColor = Colors.blue;
        statusText = 'Confirmé';
        statusIcon = Icons.verified;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'Annulé';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'En attente';
        statusIcon = Icons.pending;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(statusIcon, color: statusColor, size: 20),
        ),
        title: Text(
          delivery.schoolName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${delivery.quantity} cartes × ${delivery.unitPrice} DA',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            if (delivery.deliveryDate != null)
              Text(
                'Date: ${delivery.deliveryDate}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${delivery.finalPrice} DA',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 10,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveriesList() {
    if (_deliveries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_shipping, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Aucune livraison enregistrée',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Commencez par ajouter une nouvelle livraison',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  _tabController.animateTo(1);
                },
                icon: const Icon(Icons.add),
                label: const Text('Ajouter une livraison'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDeliveries,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: _deliveries.length,
        separatorBuilder: (context, index) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final delivery = _deliveries[index];
          return _buildDeliveryCard(delivery);
        },
      ),
    );
  }

  Widget _buildSchoolCard(School school) {
    final isSelected = _selectedSchoolId == school.id;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      elevation: isSelected ? 2 : 0,
      color: isSelected ? Colors.blue.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade300,
          width: isSelected ? 1.5 : 0.5,
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade100 : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.school,
            color: isSelected ? Colors.blue : Colors.grey,
            size: 20,
          ),
        ),
        title: Text(
          school.name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.blue.shade800 : Colors.black,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (school.wilaya != null && school.wilaya!.isNotEmpty)
              Text(
                '📍 ${school.wilaya!}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
            if (school.commune != null && school.commune!.isNotEmpty)
              Text(
                '🏘️ ${school.commune!}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            if (school.studentCount != null && school.studentCount! > 0)
              Text(
                '👥 ${school.studentCount!} élèves',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
          ],
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: Colors.green.shade600)
            : Icon(Icons.chevron_right, color: Colors.grey.shade500),
        onTap: () {
          setState(() {
            _selectedSchoolId = school.id;
          });
          FocusScope.of(context).unfocus();
        },
      ),
    );
  }

  Widget _buildSchoolsList() {
    if (_schools.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.school_outlined, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Aucune école disponible',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Veuillez contacter l\'administrateur',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _initData,
                icon: const Icon(Icons.refresh),
                label: const Text('Rafraîchir'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: _schools.length,
      separatorBuilder: (context, index) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final school = _schools[index];
        return _buildSchoolCard(school);
      },
    );
  }

  Widget _buildDeliveryForm() {
    if (_selectedSchoolId == null) {
      return Column(
        children: [
          // En-tête avec statistiques
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_schools.length}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Text(
                      'Écoles disponibles',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _initData,
                  tooltip: 'Rafraîchir la liste',
                ),
              ],
            ),
          ),

          // Message d'instruction
          Container(
            padding: const EdgeInsets.all(20),
            child: const Column(
              children: [
                Icon(Icons.touch_app, size: 50, color: Colors.blue),
                SizedBox(height: 16),
                Text(
                  'Sélectionnez une école',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Choisissez une école dans la liste ci-dessous pour créer une nouvelle livraison',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Liste des écoles
          Expanded(child: _buildSchoolsList()),
        ],
      );
    }

    final selectedSchool = _schools.firstWhere((s) => s.id == _selectedSchoolId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec l'école sélectionnée
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedSchool.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (selectedSchool.wilaya != null && selectedSchool.wilaya!.isNotEmpty)
                        Text(
                          '📍 ${selectedSchool.wilaya!}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedSchoolId = null;
                    });
                  },
                  tooltip: 'Changer d\'école',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Formulaire
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Quantité de cartes",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers, color: Colors.blue),
                    hintText: "Ex: 50",
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'La quantité est requise';
                    final intValue = int.tryParse(v);
                    if (intValue == null) return 'Nombre invalide';
                    if (intValue <= 0) return 'Doit être supérieur à 0';
                    if (intValue > 1000) return 'Quantité trop élevée';
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {});
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Prix Unitaire (DA)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.money, color: Colors.green),
                    hintText: "Ex: 1000",
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Le prix est requise';
                    final doubleValue = double.tryParse(v);
                    if (doubleValue == null) return 'Prix invalide';
                    if (doubleValue <= 0) return 'Doit être supérieur à 0';
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {});
                  },
                ),

                const SizedBox(height: 16),

                // Calcul du total
                if (_qtyController.text.isNotEmpty &&
                    _priceController.text.isNotEmpty &&
                    int.tryParse(_qtyController.text) != null &&
                    double.tryParse(_priceController.text) != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total à payer',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'Montant final',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_qtyController.text} × ${_priceController.text} DA',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '${(int.parse(_qtyController.text) * double.parse(_priceController.text)).toStringAsFixed(2)} DA',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Bouton de soumission
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'ENREGISTRER LA LIVRAISON',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Livraisons'),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(Icons.list, size: 20),
                text: 'Liste',
              ),
              Tab(
                icon: Icon(Icons.add, size: 20),
                text: 'Nouvelle',
              ),
            ],
            indicatorColor: Colors.white,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _initData,
              tooltip: 'Rafraîchir',
            ),
          ],
        ),
        body: _isLoading
            ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Chargement...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        )
            : TabBarView(
          controller: _tabController,
          children: [
            // Onglet 1: Liste des livraisons
            Column(
              children: [
                // Statistiques rapides
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  color: Colors.grey.shade50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Column(
                        children: [
                          Text(
                            _deliveries.length.toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const Text(
                            'Total',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            _deliveries
                                .where((d) => d.status?.toLowerCase() == 'completed' || d.status?.toLowerCase() == 'confirmed')
                                .length
                                .toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const Text(
                            'Terminées',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            _deliveries
                                .where((d) => d.status?.toLowerCase() == 'pending')
                                .length
                                .toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const Text(
                            'En attente',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Liste des livraisons
                Expanded(
                  child: _buildDeliveriesList(),
                ),
              ],
            ),

            // Onglet 2: Nouvelle livraison
            _buildDeliveryForm(),
          ],
        ),
      ),
    );
  }
}