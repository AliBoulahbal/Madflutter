import 'dart:convert';
import 'dart:io';
import 'dart:math'; // Ajouté pour la fonction min()

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:madaure/models/school.dart';
import 'package:madaure/models/delivery.dart';
import 'package:madaure/models/payment.dart';

// URL de base dynamique
String getBaseUrl() {
  if (kIsWeb) {
    return 'http://127.0.0.1:8000/api';
  }
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8000/api';
  }
  return 'http://localhost:8000/api';
}

final String API_BASE_URL = getBaseUrl();

class ApiService {
  String? _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  ApiService();

  // --- 1. GESTION DU TOKEN ---
  Future<void> initToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      print('🔑 Token initialisé: ${_token != null ? "OUI" : "NON"}');
    } catch (e) {
      print('❌ Error initializing token: $e');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    if (_token == null) await initToken();
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // --- 2. MOTEUR DE REQUÊTE ---
  Future<http.Response> _makeRequest(
      String method,
      String endpoint,
      Map<String, dynamic>? body,
      ) async {
    final url = Uri.parse('$API_BASE_URL/$endpoint');
    final headers = await _getHeaders();

    print('🌐 Requête $method: $url');
    if (body != null) {
      print('📦 Body: $body');
    }

    try {
      switch (method) {
        case 'GET':
          return await http.get(url, headers: headers);
        case 'POST':
          return await http.post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
        default:
          throw Exception('Méthode non supportée: $method');
      }
    } catch (e) {
      print('❌ Network error: $e');
      rethrow;
    }
  }

  // --- 3. AUTHENTIFICATION ---
  Future<Map<String, dynamic>> login(
      String email,
      String password,
      String device,
      ) async {
    print('🔐 Tentative de connexion pour: $email');

    final response = await _makeRequest(
      'POST',
      'login',
      {
        'email': email,
        'password': password,
        'device_name': device,
      },
    );

    print('📡 Réponse login: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ Connexion réussie');

      _token = data['token'] ?? data['access_token'];
      if (_token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        print('🔐 Token sauvegardé');
      }
      return data;
    } else {
      print('❌ Échec connexion: ${response.statusCode} - ${response.body}');
      throw Exception('Échec de la connexion: ${response.statusCode}');
    }
  }

  Future<void> logout() async {
    print('🚪 Déconnexion...');
    try {
      if (isAuthenticated) {
        await _makeRequest('POST', 'logout', null);
        print('✅ Logout API appelé');
      }
    } catch (e) {
      print('⚠️ Erreur logout API: $e');
    } finally {
      _token = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      print('🔑 Token supprimé');
    }
  }

  // --- 4. ÉCOLES ET WILAYAS ---
  Future<List<String>> fetchWilayas() async {
    // Liste statique pour Batna et environs
    return [
      'Batna',
      'Alger',
      'Sétif',
      'Constantine',
      'Oran',
      'Biskra',
      'M\'Sila',
      'Djelfa',
      'Blida',
      'Tizi Ouzou',
      'Annaba',
      'Béjaïa',
      'Sidi Bel Abbès',
      'Tlemcen',
      'Ghardaïa',
      'Laghouat',
      'Tiaret',
      'Mostaganem',
      'Médéa'
    ];
  }

  Future<bool> addSchool(Map<String, dynamic> data) async {
    print('🏫 Ajout d\'une école: $data');
    final response = await _makeRequest('POST', 'schools', data);

    print('📡 Réponse addSchool: ${response.statusCode}');

    if (response.statusCode >= 200 && response.statusCode < 300) {
      print('✅ École ajoutée avec succès');
      return true;
    } else {
      print('❌ Échec addSchool: ${response.body}');

      // Parser les erreurs de validation
      try {
        final errorData = jsonDecode(response.body);
        if (errorData['errors'] != null) {
          final errors = errorData['errors'] as Map<String, dynamic>;
          final errorMessages =
          errors.entries.map((e) => '${e.key}: ${e.value.join(", ")}').join("\n");
          throw Exception('Erreurs de validation:\n$errorMessages');
        } else if (errorData['message'] != null) {
          throw Exception(errorData['message']);
        }
      } catch (e) {
        print('⚠️ Erreur lors du parsing des erreurs: $e');
      }

      throw Exception('Échec d\'ajout de l\'école: ${response.statusCode}');
    }
  }

  Future<List<School>> fetchSchools() async {
    print('🏫 Chargement des écoles...');

    try {
      final response = await _makeRequest('GET', 'schools', null);

      print('📡 Réponse fetchSchools: ${response.statusCode}');
      print(
          '📡 Body (premier 500 caractères): ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          print('📡 Type de données: ${data.runtimeType}');
          print('📡 Données JSON: $data');

          List<School> schools = [];

          // STRUCTURE: {success: true, schools: {current_page: 1, data: [...]}}
          if (data is Map) {
            if (data.containsKey('success') &&
                data['success'] == true &&
                data.containsKey('schools')) {
              print('✅ Format reconnu: success + schools');

              final schoolsData = data['schools'];
              if (schoolsData is Map &&
                  schoolsData.containsKey('data') &&
                  schoolsData['data'] is List) {
                print('✅ Sous-structure: schools.data (List)');
                final schoolsList = schoolsData['data'] as List;

                schools = schoolsList.map<School>((item) {
                  try {
                    return School.fromJson(item);
                  } catch (e) {
                    print('❌ Erreur parsing item: $item, erreur: $e');
                    return School(
                      id: 0,
                      name: 'École invalide',
                      district: '',
                      commune: '',
                      address: '',
                      phone: '',
                      managerName: '',
                      studentCount: 0,
                      wilaya: '',
                      isActive: false,
                      deliveriesCount: 0,
                      totalDelivered: 0,
                    );
                  }
                }).toList();
              } else if (schoolsData is List) {
                print('✅ Format: success + schools (List direct)');
                schools = schoolsData.map<School>((item) {
                  try {
                    return School.fromJson(item);
                  } catch (e) {
                    print('❌ Erreur parsing item: $item, erreur: $e');
                    return School(
                      id: 0,
                      name: 'École invalide',
                      district: '',
                      commune: '',
                      address: '',
                      phone: '',
                      managerName: '',
                      studentCount: 0,
                      wilaya: '',
                      isActive: false,
                      deliveriesCount: 0,
                      totalDelivered: 0,
                    );
                  }
                }).toList();
              }
            }
            // ESSAYER D'AUTRES FORMATS
            else if (data.containsKey('data') && data['data'] is List) {
              print('✅ Format 2: Structure avec clé "data"');
              final schoolsData = data['data'] as List;
              schools = schoolsData.map<School>((item) {
                try {
                  return School.fromJson(item);
                } catch (e) {
                  print('❌ Erreur parsing item: $item, erreur: $e');
                  return School(
                    id: 0,
                    name: 'École invalide',
                    district: '',
                    commune: '',
                    address: '',
                    phone: '',
                    managerName: '',
                    studentCount: 0,
                    wilaya: '',
                    isActive: false,
                    deliveriesCount: 0,
                    totalDelivered: 0,
                  );
                }
              }).toList();
            } else {
              // Afficher toutes les clés pour déboguer
              print('⚠️ Structure non reconnue. Clés disponibles: ${data.keys.toList()}');
              print('⚠️ Contenu schools type: ${data['schools']?.runtimeType}');
              if (data['schools'] is Map) {
                final schoolsMap = data['schools'] as Map;
                print('⚠️ Schools keys: ${schoolsMap.keys.toList()}');
              }
            }
          } else if (data is List) {
            print('✅ Format 3: Données directes (List)');
            schools = data.map<School>((item) {
              try {
                return School.fromJson(item);
              } catch (e) {
                print('❌ Erreur parsing item: $item, erreur: $e');
                return School(
                  id: 0,
                  name: 'École invalide',
                  district: '',
                  commune: '',
                  address: '',
                  phone: '',
                  managerName: '',
                  studentCount: 0,
                  wilaya: '',
                  isActive: false,
                  deliveriesCount: 0,
                  totalDelivered: 0,
                );
              }
            }).toList();
          }

          print('✅ ${schools.length} écoles chargées après parsing');

          // Log les écoles chargées pour déboguer
          for (var school in schools) {
            print('   📍 École: ${school.name}, ID: ${school.id}, Wilaya: ${school.wilaya}');
          }

          // NE PAS CRÉER D'ÉCOLE FACTICE - utiliser les vraies écoles
          if (schools.isEmpty) {
            print('⚠️ Aucune école retournée par l\'API');
          }

          return schools;
        } catch (e) {
          print('❌ Erreur parsing schools JSON: $e');
          print('❌ Stack trace: ${e.toString()}');
          print('❌ Raw response body: ${response.body}');
          return [];
        }
      } else {
        print('❌ Erreur HTTP fetchSchools: ${response.statusCode}');
        print('❌ Body: ${response.body}');
        return [];
      }
    } catch (e) {
      print('❌ Exception fetchSchools: $e');
      print('❌ Type d\'erreur: ${e.runtimeType}');
      return [];
    }
  }

  // --- 5. LIVRAISONS ET PAIEMENTS ---
  Future<List<Delivery>> fetchDeliveries() async {
    print('📦 Chargement des livraisons...');
    final response = await _makeRequest('GET', 'deliveries', null);

    print('📡 Réponse fetchDeliveries: ${response.statusCode}');

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        List<Delivery> deliveries = [];

        print('📊 Structure des données: ${data.runtimeType}');

        // STRUCTURE: {success: true, deliveries: {current_page: 1, data: [...]}}
        if (data is Map) {
          if (data.containsKey('success') && data['success'] == true) {
            print('✅ Format reconnu: success + data');

            // Essayer différentes structures
            if (data.containsKey('deliveries')) {
              final deliveriesData = data['deliveries'];
              print('📊 Type de deliveriesData: ${deliveriesData.runtimeType}');

              if (deliveriesData is Map &&
                  deliveriesData.containsKey('data') &&
                  deliveriesData['data'] is List) {
                print('✅ Sous-structure: deliveries.data (List)');
                final deliveriesList = deliveriesData['data'] as List;

                deliveries = deliveriesList.map<Delivery>((item) {
                  try {
                    return Delivery.fromJson(item);
                  } catch (e) {
                    print('❌ Erreur parsing delivery: $item, erreur: $e');
                    // Créer une livraison vide pour éviter la crash
                    return Delivery(
                      id: 0,
                      schoolId: 0,
                      schoolName: 'Livraison invalide',
                      quantity: 0,
                      unitPrice: 0,
                      finalPrice: 0,
                      remainingAmount: 0,
                      paidAmount: 0,
                      status: '',
                      deliveryDate: '',
                      latitude: 0,
                      longitude: 0,
                    );
                  }
                }).toList();
              } else if (deliveriesData is List) {
                print('✅ Format: deliveries (List direct)');
                deliveries = deliveriesData.map<Delivery>((item) {
                  try {
                    return Delivery.fromJson(item);
                  } catch (e) {
                    print('❌ Erreur parsing delivery: $item, erreur: $e');
                    return Delivery(
                      id: 0,
                      schoolId: 0,
                      schoolName: 'Livraison invalide',
                      quantity: 0,
                      unitPrice: 0,
                      finalPrice: 0,
                      remainingAmount: 0,
                      paidAmount: 0,
                      status: '',
                      deliveryDate: '',
                      latitude: 0,
                      longitude: 0,
                    );
                  }
                }).toList();
              }
            }
            // Autre structure possible: {success: true, data: [...]}
            else if (data.containsKey('data')) {
              print('✅ Format: data direct (List)');
              if (data['data'] is List) {
                final deliveriesData = data['data'] as List;
                deliveries = deliveriesData.map<Delivery>((item) {
                  try {
                    return Delivery.fromJson(item);
                  } catch (e) {
                    print('❌ Erreur parsing delivery: $item, erreur: $e');
                    return Delivery(
                      id: 0,
                      schoolId: 0,
                      schoolName: 'Livraison invalide',
                      quantity: 0,
                      unitPrice: 0,
                      finalPrice: 0,
                      remainingAmount: 0,
                      paidAmount: 0,
                      status: '',
                      deliveryDate: '',
                      latitude: 0,
                      longitude: 0,
                    );
                  }
                }).toList();
              }
            }
          }
          // Format direct sans "success"
          else if (data.containsKey('deliveries') && data['deliveries'] is List) {
            print('✅ Format direct: deliveries (List)');
            deliveries = (data['deliveries'] as List).map<Delivery>((item) {
              try {
                return Delivery.fromJson(item);
              } catch (e) {
                print('❌ Erreur parsing delivery: $item, erreur: $e');
                return Delivery(
                  id: 0,
                  schoolId: 0,
                  schoolName: 'Livraison invalide',
                  quantity: 0,
                  unitPrice: 0,
                  finalPrice: 0,
                  remainingAmount: 0,
                  paidAmount: 0,
                  status: '',
                  deliveryDate: '',
                  latitude: 0,
                  longitude: 0,
                );
              }
            }).toList();
          }
        } else if (data is List) {
          print('✅ Format: List direct');
          deliveries = data.map<Delivery>((item) {
            try {
              return Delivery.fromJson(item);
            } catch (e) {
              print('❌ Erreur parsing delivery: $item, erreur: $e');
              return Delivery(
                id: 0,
                schoolId: 0,
                schoolName: 'Livraison invalide',
                quantity: 0,
                unitPrice: 0,
                finalPrice: 0,
                remainingAmount: 0,
                paidAmount: 0,
                status: '',
                deliveryDate: '',
                latitude: 0,
                longitude: 0,
              );
            }
          }).toList();
        }

        print('✅ ${deliveries.length} livraisons chargées');

        // Debug: Afficher les premières livraisons
        if (deliveries.isNotEmpty) {
          for (int i = 0; i < min(3, deliveries.length); i++) {
            final d = deliveries[i];
            print('📊 Livraison $i: ${d.schoolName}, Prix: ${d.finalPrice}, Reste: ${d.remainingAmount}');
          }
        }

        return deliveries;
      } catch (e) {
        print('❌ Error parsing deliveries: $e');
        print('❌ Stack trace: ${e.toString()}');
        print('❌ Raw response body: ${response.body}');
        return [];
      }
    } else {
      print('❌ Erreur fetchDeliveries: ${response.statusCode}');
      print('❌ Body: ${response.body}');
      return [];
    }
  }

  Future<bool> addDelivery(Map<String, dynamic> data) async {
    print('🚚 Ajout d\'une livraison: $data');
    final response = await _makeRequest('POST', 'deliveries', data);

    print('📡 Réponse addDelivery: ${response.statusCode}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      print('✅ Livraison ajoutée avec succès');
      return true;
    } else {
      print('❌ Échec addDelivery: ${response.body}');
      return false;
    }
  }

  Future<bool> addPayment(Map<String, dynamic> data) async {
    print('💰 Ajout d\'un paiement: $data');
    final response = await _makeRequest('POST', 'payments', data);

    print('📡 Réponse addPayment: ${response.statusCode}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      print('✅ Paiement ajouté avec succès');
      return true;
    } else {
      print('❌ Échec addPayment: ${response.body}');
      return false;
    }
  }

  Future<List<Payment>> fetchPayments() async {
    print('💳 Chargement des paiements...');
    final response = await _makeRequest('GET', 'payments', null);

    print('📡 Réponse fetchPayments: ${response.statusCode}');

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        List<Payment> payments = [];

        if (data['payments'] is List) {
          payments = (data['payments'] as List).map((j) => Payment.fromJson(j)).toList();
        } else if (data is List) {
          payments = data.map((j) => Payment.fromJson(j)).toList();
        } else if (data['data'] is List) {
          payments = (data['data'] as List).map((j) => Payment.fromJson(j)).toList();
        }

        print('✅ ${payments.length} paiements chargées');
        return payments;
      } catch (e) {
        print('❌ Error parsing payments: $e');
        return [];
      }
    } else {
      print('❌ Erreur fetchPayments: ${response.statusCode}');
      return [];
    }
  }

  // --- 6. STATS ET PROFIL ---
  Future<Map<String, dynamic>?> fetchUserProfile() async {
    print('👤 Chargement profil utilisateur...');

    try {
      final response = await _makeRequest('GET', 'user/profile', null);

      print('📡 Réponse profile: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Essayez différentes structures
        if (data['user'] != null) {
          print('✅ Profil trouvé dans user');
          return Map<String, dynamic>.from(data['user'] as Map);
        } else if (data['data'] != null && data['data']['distributor'] != null) {
          // Structure du dashboard
          print('✅ Profil trouvé dans data.distributor');
          final distributor = data['data']['distributor'] as Map;
          return Map<String, dynamic>.from(distributor);
        } else if (data['distributor'] != null) {
          print('✅ Profil trouvé dans distributor');
          final distributor = data['distributor'] as Map;
          return Map<String, dynamic>.from(distributor);
        } else if (data is Map) {
          print('✅ Profil retourné directement');
          return Map<String, dynamic>.from(data as Map);
        } else {
          print('⚠️ Structure de profil non reconnue');
          return null;
        }
      } else {
        print('❌ Erreur fetchUserProfile: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Exception fetchUserProfile: $e');
      return null;
    }
  }

  // --- 7. GPS ---
  Future<Position> getCurrentLocation() async {
    print('📍 Demande de position GPS...');

    // Vérifier si les services de localisation sont activés
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('❌ Services de localisation désactivés');
      throw Exception('Les services de localisation sont désactivés.');
    }

    // Vérifier les permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      print('🔒 Demande de permission de localisation...');
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('❌ Permissions de localisation refusées');
        throw Exception('Les permissions de localisation sont refusées.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('❌ Permissions de localisation définitivement refusées');
      throw Exception('Les permissions de localisation sont définitivement refusées.');
    }

    print('✅ Permissions GPS OK, obtention de la position...');
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    print('📍 Position obtenue: ${position.latitude}, ${position.longitude}');
    return position;
  }

  // --- 8. DASHBOARDS ---

  // Dashboard distributeur principal
  Future<Map<String, dynamic>> fetchDistributorDashboard() async {
    print('📊 Chargement dashboard distributeur...');

    try {
      final response = await _makeRequest('GET', 'dashboard/distributor-stats', null);

      print('📡 Réponse distributor dashboard: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Dashboard distributeur chargé avec succès');
        return data;
      } else {
        print('❌ Erreur distributor dashboard: ${response.statusCode} - ${response.body}');
        throw Exception('Erreur dashboard distributeur: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception dans fetchDistributorDashboard: $e');
      rethrow;
    }
  }

  // Dashboard admin
  Future<Map<String, dynamic>> fetchAdminDashboard() async {
    print('👑 Chargement dashboard admin...');

    try {
      final response = await _makeRequest('GET', 'dashboard/admin-stats', null);

      print('📡 Réponse admin dashboard: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Dashboard admin chargé avec succès');
        return data;
      } else {
        print('❌ Erreur admin dashboard: ${response.statusCode} - ${response.body}');
        throw Exception('Erreur dashboard admin: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception dans fetchAdminDashboard: $e');
      rethrow;
    }
  }

  // Statistiques de cartes pour distributeur
  Future<Map<String, dynamic>> fetchCardsStats() async {
    print('🃏 Chargement stats cartes...');

    try {
      final response = await _makeRequest('GET', 'dashboard/cards-stats', null);

      print('📡 Réponse cards stats: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Stats cartes chargées avec succès');
        return data;
      } else {
        print('❌ Erreur cards stats: ${response.statusCode}');
        throw Exception('Erreur stats cartes: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception dans fetchCardsStats: $e');
      rethrow;
    }
  }

  // Résumé mensuel
  Future<Map<String, dynamic>> fetchMonthlySummary() async {
    print('📅 Chargement résumé mensuel...');

    try {
      final response = await _makeRequest('GET', 'dashboard/monthly-summary', null);

      print('📡 Réponse monthly summary: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Résumé mensuel chargé avec succès');
        return data;
      } else {
        print('❌ Erreur monthly summary: ${response.statusCode}');
        throw Exception('Erreur résumé mensuel: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception dans fetchMonthlySummary: $e');
      rethrow;
    }
  }

  // Activité personnelle
  Future<Map<String, dynamic>> fetchMyActivity() async {
    print('📈 Chargement activité personnelle...');

    try {
      final response = await _makeRequest('GET', 'dashboard/my-activity', null);

      print('📡 Réponse my activity: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Activité personnelle chargée avec succès');
        return data;
      } else {
        print('❌ Erreur my activity: ${response.statusCode}');
        throw Exception('Erreur activité personnelle: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception dans fetchMyActivity: $e');
      rethrow;
    }
  }

  // Stock de cartes
  Future<Map<String, dynamic>> fetchCardsStock() async {
    print('📦 Chargement stock cartes...');

    try {
      final response = await _makeRequest('GET', 'dashboard/cards-stock', null);

      print('📡 Réponse cards stock: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Stock cartes chargé avec succès');
        return data;
      } else {
        print('❌ Erreur cards stock: ${response.statusCode}');
        throw Exception('Erreur stock cartes: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception dans fetchCardsStock: $e');
      rethrow;
    }
  }

  // Vue d'ensemble admin
  Future<Map<String, dynamic>> fetchAdminOverview() async {
    print('👁️ Chargement vue d\'ensemble admin...');

    try {
      final response = await _makeRequest('GET', 'dashboard/overview', null);

      print('📡 Réponse admin overview: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Vue d\'ensemble admin chargée avec succès');
        return data;
      } else {
        print('❌ Erreur admin overview: ${response.statusCode}');
        throw Exception('Erreur vue d\'ensemble admin: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception dans fetchAdminOverview: $e');
      rethrow;
    }
  }

  // Statistiques par wilaya
  Future<Map<String, dynamic>> fetchWilayaStats() async {
    print('🗺️ Chargement stats wilayas...');

    try {
      final response = await _makeRequest('GET', 'dashboard/wilaya-stats', null);

      print('📡 Réponse wilaya stats: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Stats wilayas chargées avec succès');
        return data;
      } else {
        print('❌ Erreur wilaya stats: ${response.statusCode}');
        throw Exception('Erreur stats wilayas: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception dans fetchWilayaStats: $e');
      rethrow;
    }
  }

  // Top distributeurs
  Future<Map<String, dynamic>> fetchTopDistributors() async {
    print('🏆 Chargement top distributeurs...');

    try {
      final response = await _makeRequest('GET', 'dashboard/top-distributors', null);

      print('📡 Réponse top distributors: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Top distributeurs chargés avec succès');
        return data;
      } else {
        print('❌ Erreur top distributors: ${response.statusCode}');
        throw Exception('Erreur top distributeurs: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception dans fetchTopDistributors: $e');
      rethrow;
    }
  }

  // Top écoles
  Future<Map<String, dynamic>> fetchTopSchools() async {
    print('🥇 Chargement top écoles...');

    try {
      final response = await _makeRequest('GET', 'dashboard/top-schools', null);

      print('📡 Réponse top schools: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Top écoles chargées avec succès');
        return data;
      } else {
        print('❌ Erreur top schools: ${response.statusCode}');
        throw Exception('Erreur top écoles: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception dans fetchTopSchools: $e');
      rethrow;
    }
  }

  // Statistiques livraisons
  Future<Map<String, dynamic>> fetchDeliveryStats() async {
    print('📊 Chargement stats livraisons...');

    try {
      final response = await _makeRequest('GET', 'deliveries/stats/summary', null);

      print('📡 Réponse delivery stats: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Stats livraisons chargées avec succès');
        return data;
      } else {
        print('❌ Erreur delivery stats: ${response.statusCode}');
        throw Exception('Erreur stats livraisons: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Exception dans fetchDeliveryStats: $e');
      rethrow;
    }
  }

  // --- 9. MÉTHODES DE DÉBOGAGE ---
  Future<void> testAllEndpoints() async {
    print('🔍 TEST DE TOUS LES ENDPOINTS');

    try {
      // Test login
      print('1. Test login...');
      final schools = await fetchSchools();
      print('   ✅ Écoles: ${schools.length}');

      // Test dashboard distributeur
      print('2. Test dashboard distributeur...');
      try {
        final dashboard = await fetchDistributorDashboard();
        print('   ✅ Dashboard distributeur: ${dashboard.keys.toList()}');
      } catch (e) {
        print('   ⚠️ Dashboard distributeur non accessible: $e');
      }

      // Test dashboard admin
      print('3. Test dashboard admin...');
      try {
        final adminDashboard = await fetchAdminDashboard();
        print('   ✅ Dashboard admin: ${adminDashboard.keys.toList()}');
      } catch (e) {
        print('   ⚠️ Dashboard admin non accessible: $e');
      }

      // Test profile
      print('4. Test profile...');
      final profile = await fetchUserProfile();
      print('   ✅ Profile: ${profile != null ? "OK" : "NULL"}');

      // Test deliveries
      print('5. Test deliveries...');
      final deliveries = await fetchDeliveries();
      print('   ✅ Livraisons: ${deliveries.length}');

      // Test payments
      print('6. Test payments...');
      final payments = await fetchPayments();
      print('   ✅ Paiements: ${payments.length}');

      print('🎉 Tous les tests passés avec succès!');
    } catch (e) {
      print('❌ Erreur lors des tests: $e');
    }
  }

  // --- 10. NOUVELLE MÉTHODE POUR DÉBOGUER L'API SCHOOLS ---
  Future<void> debugSchoolsEndpoint() async {
    print('🔍 DEBUG: Test endpoint /schools');
    try {
      final response = await _makeRequest('GET', 'schools', null);
      print('🔍 DEBUG: Status: ${response.statusCode}');
      print('🔍 DEBUG: Headers: ${response.headers}');
      print('🔍 DEBUG: Body length: ${response.body.length}');
      print(
          '🔍 DEBUG: Body (first 1000 chars): ${response.body.length > 1000 ? response.body.substring(0, 1000) + "..." : response.body}');

      // Essayer de parser pour voir la structure
      try {
        final data = jsonDecode(response.body);
        print('🔍 DEBUG: Parsed type: ${data.runtimeType}');
        if (data is Map) {
          print('🔍 DEBUG: Map keys: ${data.keys.toList()}');
          // Vérifier récursivement la structure
          if (data.containsKey('data') && data['data'] is Map) {
            final inner = data['data'] as Map;
            print('🔍 DEBUG: data keys: ${inner.keys.toList()}');
            if (inner.containsKey('schools')) {
              print('🔍 DEBUG: schools type: ${inner['schools'].runtimeType}');
            }
          }
        }
      } catch (e) {
        print('🔍 DEBUG: JSON parsing error: $e');
      }
    } catch (e) {
      print('🔍 DEBUG: Error: $e');
    }
  }
}