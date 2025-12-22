import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:madaure/main.dart';
import 'package:madaure/models/school.dart';
import 'package:geolocator/geolocator.dart';
import 'add_school_screen.dart';

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
  Position? _position;
  List<School> _schools = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _noSchools = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _noSchools = false;
    });

    try {
      try {
        _position = await _getLocationWithPermission();
      } catch (e) {
        debugPrint('⚠️ Erreur GPS: $e');
      }

      final List<School> schoolsData = await apiService.fetchSchools();

      if (mounted) {
        setState(() {
          if (schoolsData.isEmpty) {
            _noSchools = true;
            _schools = [];
          } else {
            _schools = schoolsData;
            final realSchools = schoolsData.where((school) => school.id != 999).toList();
            _selectedSchool = realSchools.isNotEmpty ? realSchools.first : (schoolsData.isNotEmpty ? schoolsData.first : null);
            _noSchools = false;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur de chargement: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<Position?> _getLocationWithPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 3),
      );
    } catch (e) {
      return await Geolocator.getLastKnownPosition();
    }
  }

  Future<void> _submitDelivery() async {
    if (!_formKey.currentState!.validate() || _selectedSchool == null) return;

    setState(() => _isLoading = true);
    try {
      final int qty = int.parse(_quantityController.text);
      final double price = double.parse(_priceController.text);
      final double total = qty * price;

      final data = {
        'school_id': _selectedSchool!.id,
        'quantity': qty,
        'unit_price': price,
        'final_price': total,
        'remaining_amount': total,
        'delivery_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'status': 'completed',
        'latitude': _position?.latitude ?? 0.0,
        'longitude': _position?.longitude ?? 0.0,
      };

      final success = await apiService.addDelivery(data);
      if (mounted && success) {
        Navigator.pop(context, {
          'success': true,
          'quantity': qty, // Fixed from 'quantity'
          'amount': total,  // Fixed from 'totalPrice'
          'schoolName': _selectedSchool!.name
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle Livraison')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<School>(
                value: _selectedSchool,
                items: _schools.map((s) => DropdownMenuItem(value: s, child: Text(s.name))).toList(),
                onChanged: (val) => setState(() => _selectedSchool = val),
                decoration: const InputDecoration(labelText: 'École'),
              ),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantité'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Champ requis' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Prix Unitaire'),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _submitDelivery, child: const Text('Valider')),
            ],
          ),
        ),
      ),
    );
  }
}