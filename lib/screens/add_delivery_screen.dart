import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:madaure/main.dart'; // Pour apiService global
import 'package:madaure/models/school.dart';
import 'package:madaure/models/user.dart';
import 'package:geolocator/geolocator.dart';

class AddDeliveryScreen extends StatefulWidget {
  const AddDeliveryScreen({super.key});

  @override
  State<AddDeliveryScreen> createState() => _AddDeliveryScreenState();
}

class _AddDeliveryScreenState extends State<AddDeliveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();

  School? _selectedSchool;
  User? _currentUser;
  DateTime? _selectedDate = DateTime.now();
  Position? _position;
  List<School> _schools = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _getCurrentLocation();
  }

  /// Initialise les données en récupérant le profil utilisateur
  /// puis en filtrant les écoles par Wilaya.
  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Récupérer le profil pour avoir la wilaya
      final userData = await apiService.fetchUserProfile();

      if (!mounted) return;

      if (userData != null) {
        _currentUser = User.fromJson(userData);
        print('✅ Distributeur localisé à: ${_currentUser?.wilaya}');
      }

      // 2. Charger les écoles filtrées par cette wilaya
      final schoolsData = await apiService.fetchSchools(wilaya: _currentUser?.wilaya);

      if (mounted) {
        setState(() {
          _schools = schoolsData.map((s) => School.fromJson(s)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur initialisation: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );
      if (mounted) {
        setState(() => _position = position);
      }
    } catch (e) {
      print("⚠️ Erreur GPS: $e");
    }
  }

  Future<void> _submitDelivery() async {
    if (!_formKey.currentState!.validate() || _selectedSchool == null || _position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez remplir tous les champs et activer le GPS'))
      );
      return;
    }

    setState(() => _isLoading = true);

    final int quantity = int.parse(_quantityController.text);
    final double unitPrice = double.parse(_priceController.text);

    // CALCUL : Total = Quantité * Prix Unitaire
    final double finalPrice = quantity * unitPrice;

    try {
      await apiService.addDelivery(
        schoolId: _selectedSchool!.id,
        quantity: quantity,
        unitPrice: unitPrice,
        finalPrice: finalPrice,
        deliveryDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
        latitude: _position!.latitude,
        longitude: _position!.longitude,
        status: 'pending',
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Livraison enregistrée avec succès'))
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur backend: $e'))
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle Livraison')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- BANDEAU INFO DISTRIBUTEUR ---
              _buildHeaderCard(),
              const SizedBox(height: 20),

              // --- SÉLECTION ÉCOLE (FILTRÉE) ---
              const Text('Client / École', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<School>(
                decoration: const InputDecoration(
                  hintText: 'Choisir une école de votre wilaya',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school),
                ),
                value: _selectedSchool,
                items: _schools.map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(s.name, overflow: TextOverflow.ellipsis)
                )).toList(),
                onChanged: (val) => setState(() => _selectedSchool = val),
                validator: (v) => v == null ? 'Veuillez choisir une école' : null,
              ),

              const SizedBox(height: 16),

              // --- QUANTITÉ ---
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantité livrée',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.inventory_2),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null,
              ),

              const SizedBox(height: 16),

              // --- PRIX UNITAIRE ---
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Prix Unitaire (DA)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sell),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Champ obligatoire' : null,
              ),

              const SizedBox(height: 20),

              // --- STATUT GPS ---
              _buildLocationStatus(),

              const SizedBox(height: 30),

              // --- BOUTON VALIDER ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitDelivery,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('VALIDER LA LIVRAISON',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Colors.blue),
              const SizedBox(width: 10),
              Text(
                _currentUser?.name ?? "Chargement...",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const Divider(),
          Row(
            children: [
              const Icon(Icons.map, color: Colors.orange, size: 20),
              const SizedBox(width: 10),
              Text("Secteur d'activité : ${_currentUser?.wilaya ?? 'Non défini'}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationStatus() {
    bool hasGPS = _position != null;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasGPS ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            hasGPS ? Icons.location_on : Icons.location_off,
            color: hasGPS ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasGPS
                  ? 'Position acquise : [${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}]'
                  : 'Signal GPS requis pour valider la livraison',
              style: TextStyle(
                  color: hasGPS ? Colors.green.shade900 : Colors.red.shade900,
                  fontSize: 13,
                  fontWeight: FontWeight.w500
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}