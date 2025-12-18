import 'package:flutter/material.dart';
import 'package:madaure/services/api_service.dart'; // Import requis
import 'package:geolocator/geolocator.dart'; // Import requis
// import 'package:madaure/main.dart'; // Probablement non requis ici

class AddSchoolScreen extends StatefulWidget {
  const AddSchoolScreen({super.key});

  @override
  State<AddSchoolScreen> createState() => _AddSchoolScreenState();
}

class _AddSchoolScreenState extends State<AddSchoolScreen> {
  // AJOUT/CORRECTION : Instance de ApiService
  final ApiService apiService = ApiService();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _managerNameController = TextEditingController();
  final _districtController = TextEditingController();
  final _communeController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isGettingLocation = false;
  double? _latitude;
  double? _longitude;
  String? _selectedWilaya;
  List<String> _wilayas = [];

  @override
  void initState() {
    super.initState();
    _loadWilayas();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _managerNameController.dispose();
    _districtController.dispose();
    _communeController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadWilayas() async {
    try {
      final wilayas = await apiService.fetchWilayas();
      setState(() {
        _wilayas = wilayas;
      });
    } catch (e) {
      print('Error loading wilayas: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement des wilayas: $e')),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      final position = await apiService.getCurrentLocation();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la récupération de la localisation: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  // --- FONCTION DE SOUMISSION CORRIGÉE ---
  Future<void> _submitSchool() async {
    // 1. Validation du formulaire et de la wilaya
    if (!_formKey.currentState!.validate() || _selectedWilaya == null) {
      return;
    }

    setState(() => _isLoading = true);

    // 2. Création du Map de données
    final schoolData = {
      'name': _nameController.text.trim(),
      'manager_name': _managerNameController.text.trim(),
      'district': _districtController.text.trim(),
      'commune': _communeController.text.trim(),
      'address': _addressController.text.trim(),
      'phone': _phoneController.text.trim(),
      'wilaya': _selectedWilaya,
      // Les coordonnées ne sont envoyées que si elles ont été récupérées
      if (_latitude != null) 'latitude': _latitude,
      if (_longitude != null) 'longitude': _longitude,
    };

    try {
      // 3. CORRECTION : Appel avec l'argument positionnel schoolData
      // L'erreur "Too few positional arguments" est résolue ici.
      await apiService.addSchool(schoolData); // Ligne 95

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('École enregistrée avec succès!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      print('❌ Erreur d\'enregistrement de l\'école: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de l\'enregistrement de l\'école: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une École'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Nom de l'école
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'école',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  prefixIcon: Icon(Icons.school),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer le nom' : null,
              ),

              const SizedBox(height: 16),

              // Nom du manager
              TextFormField(
                controller: _managerNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du Manager/Directeur',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer le nom du manager' : null,
              ),

              const SizedBox(height: 16),

              // Wilaya
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Wilaya',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  prefixIcon: Icon(Icons.location_city),
                ),
                value: _selectedWilaya,
                items: _wilayas.map((wilaya) {
                  return DropdownMenuItem<String>(
                    value: wilaya,
                    child: Text(wilaya),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedWilaya = newValue;
                  });
                },
                validator: (value) => value == null ? 'Veuillez sélectionner une wilaya' : null,
              ),

              const SizedBox(height: 16),

              // Commune
              TextFormField(
                controller: _communeController,
                decoration: const InputDecoration(
                  labelText: 'Commune',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  prefixIcon: Icon(Icons.map),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer la commune' : null,
              ),

              const SizedBox(height: 16),

              // Quartier/District (optionnel)
              TextFormField(
                controller: _districtController,
                decoration: const InputDecoration(
                  labelText: 'Quartier/District (optionnel)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),

              const SizedBox(height: 16),

              // Adresse complète
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse Complète',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  prefixIcon: Icon(Icons.home),
                ),
              ),

              const SizedBox(height: 16),

              // Numéro de téléphone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Numéro de téléphone',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer le téléphone' : null,
              ),

              const SizedBox(height: 30),

              // Localisation GPS
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Localisation GPS',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('Latitude: ${_latitude?.toStringAsFixed(6) ?? 'Non définie'}'),
                      Text('Longitude: ${_longitude?.toStringAsFixed(6) ?? 'Non définie'}'),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _isGettingLocation ? null : _getCurrentLocation,
                        icon: _isGettingLocation
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.my_location),
                        label: Text(_isGettingLocation ? 'Localisation en cours...' : 'Obtenir la position actuelle'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Bouton de soumission
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitSchool,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Text(
                    'Enregistrer l\'École',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}