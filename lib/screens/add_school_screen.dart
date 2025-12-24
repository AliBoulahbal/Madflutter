import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:madaure/main.dart';

class AddSchoolScreen extends StatefulWidget {
  const AddSchoolScreen({super.key});

  @override
  State<AddSchoolScreen> createState() => _AddSchoolScreenState();
}

class _AddSchoolScreenState extends State<AddSchoolScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _managerController = TextEditingController();
  final _districtController = TextEditingController();
  final _communeController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _studentCountController = TextEditingController();

  bool _isLoading = false;
  bool _isGettingLocation = false;
  bool _isSubmitting = false;
  Position? _currentPosition;
  String? _selectedWilaya;
  List<String> _wilayas = [];
  List<String> _communes = [];
  bool _communesLoading = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() => _isLoading = true);
    try {
      // Charger les wilayas avec débogage
      print("🔄 Chargement des wilayas...");
      _wilayas = await apiService.fetchWilayas();
      print("✅ Wilayas chargées: ${_wilayas.length} éléments");
      print("📋 Liste: $_wilayas");

      // Obtenir la localisation
      await _getCurrentLocation();
    } catch (e) {
      print("❌ Erreur init: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur initialisation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    if (mounted) {
      setState(() => _isGettingLocation = true);
    }

    try {
      final position = await apiService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isGettingLocation = false;
        });
      }
    } catch (e) {
      print("Erreur GPS: $e");
      if (mounted) {
        setState(() => _isGettingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'obtenir la localisation GPS'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _loadCommunes(String wilaya) async {
    if (wilaya.isEmpty) return;

    setState(() => _communesLoading = true);
    try {
      final communes = await apiService.getCommunesByWilaya(wilaya);
      if (mounted) {
        setState(() {
          _communes = communes;
        });
      }
    } catch (e) {
      print("Erreur chargement communes: $e");
      if (mounted) {
        setState(() {
          _communes = [];
        });
      }
    } finally {
      if (mounted) {
        setState(() => _communesLoading = false);
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez corriger les erreurs dans le formulaire'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedWilaya == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une wilaya'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_currentPosition == null) {
      final bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('GPS non disponible'),
          content: const Text('Voulez-vous continuer sans localisation GPS ?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ANNULER'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('CONTINUER'),
            ),
          ],
        ),
      );

      if (!confirm) return;
    }

    setState(() => _isSubmitting = true);
    try {
      final Map<String, dynamic> data = {
        'name': _nameController.text.trim(),
        'manager_name': _managerController.text.trim(),
        'district': _districtController.text.trim(),
        'commune': _communeController.text.trim(),
        'address': _addressController.text.trim(),
        'phone': _phoneController.text.trim(),
        'student_count': int.tryParse(_studentCountController.text) ?? 0,
        'wilaya': _selectedWilaya!,
        'latitude': _currentPosition?.latitude,
        'longitude': _currentPosition?.longitude,
        'radius': 0.1,
      };

      // Utiliser la méthode distributorStore si disponible
      final success = await apiService.addSchool(data);

      if (success && mounted) {
        // Réinitialiser le formulaire
        _formKey.currentState?.reset();
        _nameController.clear();
        _managerController.clear();
        _districtController.clear();
        _communeController.clear();
        _addressController.clear();
        _phoneController.clear();
        _studentCountController.clear();

        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('École ajoutée avec succès !'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception("Échec de l'enregistrement");
      }
    } catch (e) {
      print("Erreur soumission: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
    bool isRequired = false,
    int? maxLines,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue.shade700),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blue.shade400, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        validator: (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'Ce champ est obligatoire';
          }
          if (type == TextInputType.phone && value != null && value.isNotEmpty) {
            final phoneRegex = RegExp(r'^[0-9]{10}$');
            if (!phoneRegex.hasMatch(value)) {
              return 'Numéro de téléphone invalide';
            }
          }
          if (type == TextInputType.number && value != null && value.isNotEmpty) {
            final num = int.tryParse(value);
            if (num == null || num < 0) {
              return 'Nombre invalide';
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _buildWilayaDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wilaya *',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedWilaya,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                hint: const Text('Sélectionnez une wilaya'),
                items: _wilayas.map((wilaya) {
                  return DropdownMenuItem(
                    value: wilaya,
                    child: Text(
                      wilaya,
                      style: const TextStyle(fontSize: 15),
                    ),
                  );
                }).toList(),
                onChanged: (value) async {
                  setState(() {
                    _selectedWilaya = value;
                    _communeController.clear();
                  });
                  if (value != null) {
                    await _loadCommunes(value);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommuneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Commune',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        if (_communesLoading)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_communes.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _communeController.text.isNotEmpty ? _communeController.text : null,
                isExpanded: true,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                hint: const Text('Sélectionnez une commune'),
                items: _communes.map((commune) {
                  return DropdownMenuItem(
                    value: commune,
                    child: Text(
                      commune,
                      style: const TextStyle(fontSize: 15),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _communeController.text = value ?? '';
                  });
                },
              ),
            ),
          )
        else
          _buildField(
            controller: _communeController,
            label: 'Commune',
            icon: Icons.location_city,
            isRequired: false,
          ),
      ],
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: _currentPosition != null ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _currentPosition != null ? Colors.green.shade200 : Colors.orange.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: _currentPosition != null ? Colors.green : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _currentPosition != null ? 'Localisation obtenue' : 'Localisation en attente',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _currentPosition != null ? Colors.green.shade800 : Colors.orange.shade800,
                  ),
                ),
              ),
              if (_isGettingLocation)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_currentPosition != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latitude: ${_currentPosition!.latitude.toStringAsFixed(6)}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                Text(
                  'Longitude: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            )
          else
            const Text(
              'Cliquez sur le bouton pour obtenir votre position',
              style: TextStyle(color: Colors.grey),
            ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _isGettingLocation ? null : _getCurrentLocation,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(_currentPosition != null ? 'Actualiser la position' : 'Obtenir ma position'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentPosition != null ? Colors.green.shade100 : Colors.blue.shade50,
              foregroundColor: _currentPosition != null ? Colors.green.shade800 : Colors.blue.shade800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter une École'),
        centerTitle: true,
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
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              const Text(
                'Informations de l\'école',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Remplissez les informations de la nouvelle école',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 20),

              // Champs du formulaire
              _buildField(
                controller: _nameController,
                label: 'Nom de l\'école *',
                icon: Icons.school,
                isRequired: true,
              ),

              _buildWilayaDropdown(),

              _buildCommuneField(),

              _buildField(
                controller: _districtController,
                label: 'District *',
                icon: Icons.map,
                isRequired: true,
              ),

              _buildField(
                controller: _managerController,
                label: 'Directeur de l\'école *',
                icon: Icons.person,
                isRequired: true,
              ),

              _buildField(
                controller: _addressController,
                label: 'Adresse *',
                icon: Icons.home,
                isRequired: true,
                maxLines: 2,
              ),

              _buildField(
                controller: _phoneController,
                label: 'Téléphone',
                icon: Icons.phone,
                type: TextInputType.phone,
              ),

              _buildField(
                controller: _studentCountController,
                label: 'Nombre d\'élèves',
                icon: Icons.groups,
                type: TextInputType.number,
              ),

              const SizedBox(height: 25),

              // Section localisation
              const Text(
                'Localisation GPS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'La localisation est nécessaire pour les livraisons',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 15),

              _buildLocationCard(),

              const SizedBox(height: 30),

              // Bouton de soumission
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    shadowColor: Colors.green.shade200,
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
                      Icon(Icons.save, size: 22),
                      SizedBox(width: 10),
                      Text(
                        'ENREGISTRER L\'ÉCOLE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}