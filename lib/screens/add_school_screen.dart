import 'package:flutter/material.dart';
import 'package:madaure/services/api_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:madaure/main.dart';

class AddSchoolScreen extends StatefulWidget {
  const AddSchoolScreen({super.key});

  @override
  State<AddSchoolScreen> createState() => _AddSchoolScreenState();
}

class _AddSchoolScreenState extends State<AddSchoolScreen> {
  final _formKey = GlobalKey<FormState>();

  // Déclarer les contrôleurs mais ne pas les initialiser ici
  late TextEditingController _nameController;
  late TextEditingController _managerNameController;
  late TextEditingController _districtController;
  late TextEditingController _communeController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _studentCountController;

  bool _isLoading = false;
  bool _isGettingLocation = false;
  double? _latitude;
  double? _longitude;
  String? _selectedWilaya;
  List<String> _wilayas = [];

  @override
  void initState() {
    super.initState();

    // Initialiser les contrôleurs dans initState
    _nameController = TextEditingController();
    _managerNameController = TextEditingController();
    _districtController = TextEditingController();
    _communeController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _studentCountController = TextEditingController();

    _loadWilayas();
  }

  @override
  void dispose() {
    // Toujours disposer les contrôleurs
    _nameController.dispose();
    _managerNameController.dispose();
    _districtController.dispose();
    _communeController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _studentCountController.dispose();
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
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la récupération de la localisation: $e')),
        );
      }
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  Future<void> _submitSchool() async {
    if (!_formKey.currentState!.validate() || _selectedWilaya == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs requis')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final schoolData = {
        'name': _nameController.text.trim(),
        'manager_name': _managerNameController.text.trim(),
        'district': _districtController.text.trim(),
        'commune': _communeController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'student_count': int.tryParse(_studentCountController.text.trim()) ?? 0,
        'wilaya': _selectedWilaya,
        if (_latitude != null) 'latitude': _latitude,
        if (_longitude != null) 'longitude': _longitude,
      };

      print('🏫 Données à envoyer: $schoolData');

      final success = await apiService.addSchool(schoolData);

      if (mounted) {
        setState(() => _isLoading = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('École enregistrée avec succès!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Échec de l\'enregistrement de l\'école'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erreur d\'enregistrement de l\'école: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                  labelText: 'Nom de l\'école *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  prefixIcon: Icon(Icons.school),
                  hintText: 'Ex: Lycée Technique',
                ),
                validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer le nom' : null,
              ),

              const SizedBox(height: 16),

              // Nom du manager
              TextFormField(
                controller: _managerNameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du Manager/Directeur *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  prefixIcon: Icon(Icons.person),
                  hintText: 'Ex: Mohamed Ahmed',
                ),
                validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer le nom du manager' : null,
              ),

              const SizedBox(height: 16),

              // Nombre d'étudiants
              TextFormField(
                controller: _studentCountController,
                decoration: const InputDecoration(
                  labelText: 'Nombre d\'étudiants *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  prefixIcon: Icon(Icons.people),
                  hintText: 'Ex: 500, 1000',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le nombre d\'étudiants';
                  }
                  final count = int.tryParse(value);
                  if (count == null) {
                    return 'Veuillez entrer un nombre valide';
                  }
                  if (count <= 0) {
                    return 'Le nombre doit être positif';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Wilaya
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Wilaya *',
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
                  labelText: 'Commune *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  prefixIcon: Icon(Icons.map),
                  hintText: 'Ex: Batna Centre',
                ),
                validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer la commune' : null,
              ),

              const SizedBox(height: 16),

              // Quartier/District
              TextFormField(
                controller: _districtController,
                decoration: const InputDecoration(
                  labelText: 'Quartier/District (optionnel)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  prefixIcon: Icon(Icons.location_on),
                  hintText: 'Ex: Cité 200 logements',
                ),
              ),

              const SizedBox(height: 16),

              // Adresse
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse Complète',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  prefixIcon: Icon(Icons.home),
                  hintText: 'Ex: Rue des Frères Boucherit, N°15',
                ),
              ),

              const SizedBox(height: 16),

              // Téléphone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Numéro de téléphone *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  prefixIcon: Icon(Icons.phone),
                  hintText: 'Ex: 0770123456',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez entrer le téléphone';
                  }
                  // Validation simple du numéro de téléphone algérien
                  final phoneRegex = RegExp(r'^(0[5-7]\d{8})$');
                  if (!phoneRegex.hasMatch(value.trim())) {
                    return 'Numéro de téléphone algérien invalide (ex: 0770123456)';
                  }
                  return null;
                },
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
                      const Row(
                        children: [
                          Icon(Icons.gps_fixed, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Localisation GPS',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Latitude: ${_latitude?.toStringAsFixed(6) ?? 'Non définie'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Longitude: ${_longitude?.toStringAsFixed(6) ?? 'Non définie'}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _isGettingLocation ? null : _getCurrentLocation,
                        icon: _isGettingLocation
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.my_location),
                        label: Text(_isGettingLocation ? 'Localisation en cours...' : 'Obtenir la position actuelle'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 45),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Note: La localisation GPS est optionnelle mais recommandée pour le suivi des livraisons.',
                        style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Bouton d'enregistrement
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
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                      : const Text(
                    'Enregistrer l\'École',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Note informative
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple.shade100, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Colors.purple),
                        SizedBox(width: 8),
                        Text(
                          'Information importante',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Les champs marqués d\'un * sont obligatoires',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '• Le nombre d\'étudiants est requis par le système',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Après enregistrement, vous pourrez créer des livraisons pour cette école',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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