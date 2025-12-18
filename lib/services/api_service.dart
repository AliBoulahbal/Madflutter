import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

// Configuration de l'URL de base selon la plateforme
String getBaseUrl() {
  if (kIsWeb) {
    // Pour le web
    return 'http://localhost:8000/api';
  }

  if (Platform.isAndroid) {
    // Pour l'émulateur Android
    return 'http://10.0.2.2:8000/api';
  }

  if (Platform.isIOS) {
    // Pour le simulateur iOS
    return 'http://localhost:8000/api';
  }

  // Par défaut
  return 'http://localhost:8000/api';
}

String API_BASE_URL = getBaseUrl();

class ApiService {
  String? _token;

  bool get isAuthenticated => _token != null;

  // --- Constructeur ---
  ApiService() {
    print('🌐 URL API configurée: $API_BASE_URL');
    print('📱 Plateforme: ${kIsWeb ? 'Web' : Platform.operatingSystem}');
    initToken();
  }

  // --- Helpers HTTP ---
  Future<Map<String, String>> _getHeaders({bool requireAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      await initToken();
      if (_token != null) {
        headers['Authorization'] = 'Bearer $_token';
      }
    }
    return headers;
  }

  // --- Méthode de débogage ---
  void _debugResponse(http.Response response, String endpoint) {
    print('=== DEBUG RESPONSE ===');
    print('Endpoint: $endpoint');
    print('Status: ${response.statusCode}');
    print('Headers: ${response.headers}');

    // Limiter la taille du log pour éviter les débordements
    final body = response.body;
    final previewLength = body.length > 500 ? 500 : body.length;

    print('Body (preview $previewLength/${body.length} chars):');
    print(body.substring(0, previewLength));
    if (body.length > 500) {
      print('... (${body.length - 500} caractères supplémentaires)');
    }
    print('=== END DEBUG ===');
  }

  // --- 1. GESTION DU TOKEN ---
  Future<void> initToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      print(_token != null ? '✅ Token trouvé dans le stockage local' : '⚠️ Aucun token trouvé');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation du token: $e');
    }
  }

  Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);
      _token = token;
      print('✅ Token sauvegardé avec succès');
    } catch (e) {
      print('❌ Erreur lors de la sauvegarde du token: $e');
    }
  }

  Future<void> removeToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      _token = null;
      print('✅ Token supprimé');
    } catch (e) {
      print('❌ Erreur lors de la suppression du token: $e');
    }
  }

  // --- 2. AUTHENTIFICATION ---
  Future<Map<String, dynamic>> login(String email, String password, String deviceName) async {
    print('🔐 Tentative de connexion: $email');

    try {
      final url = Uri.parse('$API_BASE_URL/login');
      print('🌐 URL: $url');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'device_name': deviceName,
        }),
      );

      _debugResponse(response, 'login');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['token'] != null) {
          await saveToken(data['token']);
          print('✅ Connexion réussie');
          return data;
        } else {
          throw Exception('Token non reçu dans la réponse');
        }
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Échec de la connexion (${response.statusCode})';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Erreur de connexion: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    print('🚪 Déconnexion en cours...');
    try {
      if (isAuthenticated) {
        final url = Uri.parse('$API_BASE_URL/logout');
        final headers = await _getHeaders();
        final response = await http.post(url, headers: headers);

        if (response.statusCode == 200) {
          print('✅ Déconnexion réussie côté serveur');
        } else {
          print('⚠️ Problème côté serveur lors de la déconnexion: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('⚠️ Erreur lors de la déconnexion API (token supprimé localement): $e');
    } finally {
      await removeToken();
    }
  }

  // --- 3. PROFIL UTILISATEUR ---
  Future<Map<String, dynamic>> fetchUserProfile() async {
    print('👤 Chargement du profil utilisateur');

    try {
      final url = Uri.parse('$API_BASE_URL/user');
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers);
      _debugResponse(response, 'user');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await logout();
        throw Exception('Session expirée');
      } else {
        throw Exception('Erreur lors du chargement du profil: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur lors du chargement du profil: $e');
      rethrow;
    }
  }

  // --- 4. GESTION DES LIVRAISONS ---
  Future<Map<String, dynamic>> addDelivery({
    required int schoolId,
    required int quantity,
    required double unitPrice,
    required double finalPrice,
    required String deliveryDate,
    required double latitude,
    required double longitude,
    required String status,
  }) async {
    print('📦 Enregistrement d\'une nouvelle livraison');

    try {
      final url = Uri.parse('$API_BASE_URL/deliveries/storeWithLocation');
      final headers = await _getHeaders();

      final body = {
        'school_id': schoolId,
        'quantity': quantity,
        'unit_price': unitPrice,
        'final_price': finalPrice,
        'delivery_date': deliveryDate,
        'latitude': latitude,
        'longitude': longitude,
        'status': status,
      };

      print('📝 Données: $body');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      _debugResponse(response, 'deliveries/storeWithLocation');

      if (response.statusCode == 201) {
        print('✅ Livraison enregistrée avec succès');
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Erreur: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Erreur lors de l\'enregistrement de la livraison: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchMyDeliveries() async {
    print('📋 Chargement des livraisons');

    try {
      final url = Uri.parse('$API_BASE_URL/deliveries');
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Différents formats possibles selon l'API
        if (data is Map && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else {
          return [];
        }
      } else {
        print('⚠️ Erreur lors du chargement des livraisons: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Erreur fetchMyDeliveries: $e');
      return [];
    }
  }

  // --- 5. GESTION DES PAIEMENTS ---
  Future<Map<String, dynamic>> addPayment({
    required int deliveryId,
    required double amount,
    required String paymentMethod,
    String? reference, // note est optional dans votre API
    required String paymentDate, // Obligatoire selon votre validation
  }) async {
    print('💰 Enregistrement d\'un paiement');

    try {
      final url = Uri.parse('$API_BASE_URL/payments');
      final headers = await _getHeaders();

      // CORRECTION IMPORTANTE: Votre API attend 'amount_paid' et 'payment_method'
      final Map<String, dynamic> body = {
        'delivery_id': deliveryId,
        'amount_paid': amount, // CHANGÉ: 'amount_paid' au lieu de 'amount'
        'payment_method': paymentMethod,
        'payment_date': paymentDate, // Obligatoire
      };

      // Votre API accepte 'note' (pour référence), pas 'reference'
      if (reference != null && reference.isNotEmpty) {
        body['note'] = reference; // CHANGÉ: 'note' au lieu de 'reference'
      }

      // DEBUG: Afficher les données envoyées
      print('📤 Données envoyées au backend: $body');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      _debugResponse(response, 'payments');

      if (response.statusCode == 201) {
        print('✅ Paiement enregistré avec succès');
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Erreur: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Erreur lors de l\'enregistrement du paiement: $e');
      rethrow;
    }
  }

  // ADD THIS MISSING METHOD for payments list screen
  Future<List<Map<String, dynamic>>> fetchPayments() async {
    print('💰 Chargement des paiements');

    try {
      final url = Uri.parse('$API_BASE_URL/payments');
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle different response formats
        if (data is Map && data['data'] is List) {
          return List<Map<String, dynamic>>.from(data['data']);
        } else if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['payments'] is List) {
          return List<Map<String, dynamic>>.from(data['payments']);
        } else {
          print('⚠️ Format de réponse inattendu pour les paiements');
          return [];
        }
      } else {
        print('⚠️ Erreur fetchPayments: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Erreur fetchPayments: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> fetchCardsStock() async {
    print('🃏 Chargement du stock de cartes');

    try {
      final url = Uri.parse('$API_BASE_URL/dashboard/cards-stock');
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors du chargement du stock: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur fetchCardsStock: $e');
      rethrow;
    }
  }

  // --- 6. TABLEAU DE BORD ---
  Future<Map<String, dynamic>> fetchDistributorDashboard() async {
    print('📊 Chargement du tableau de bord distributeur');
    return await fetchDistributorStats();
  }

  Future<Map<String, dynamic>> fetchDistributorStats() async {
    print('📈 Chargement des statistiques distributeur');

    try {
      final url = Uri.parse('$API_BASE_URL/dashboard/distributor-stats');
      final headers = await _getHeaders();

      print('🌐 Appel API: $url');

      final response = await http.get(url, headers: headers);
      _debugResponse(response, 'dashboard/distributor-stats');

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          print('✅ Statistiques chargées avec succès');
          return data;
        } catch (e) {
          print('❌ Erreur de parsing JSON: $e');
          print('Corps complet de la réponse: ${response.body}');
          throw Exception('Réponse JSON invalide');
        }
      } else if (response.statusCode == 401) {
        await logout();
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        final errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['message'] ?? 'Échec du chargement: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Erreur fetchDistributorStats: $e');
      rethrow;
    }
  }

  // --- 7. GESTION DES ÉCOLES ---
  Future<List<String>> fetchWilayas() async {
    print('📍 Chargement des wilayas');

    try {
      final url = Uri.parse('$API_BASE_URL/wilayas');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['wilayas'] is List) {
          return List<String>.from(data['wilayas']);
        }
      }

      // Fallback: retourne une liste statique
      print('⚠️ Utilisation de la liste statique des wilayas');
      return [
        'Adrar', 'Chlef', 'Laghouat', 'Oum El Bouaghi', 'Batna', 'Béjaïa', 'Biskra',
        'Béchar', 'Blida', 'Bouira', 'Tamanrasset', 'Tébessa', 'Tlemcen', 'Tiaret',
        'Tizi Ouzou', 'Alger', 'Djelfa', 'Jijel', 'Sétif', 'Saïda', 'Skikda', 'Sidi Bel Abbès',
        'Annaba', 'Guelma', 'Constantine', 'Médéa', 'Mostaganem', 'M\'Sila', 'Mascara',
        'Ouargla', 'Oran', 'El Bayadh', 'Illizi', 'Bordj Bou Arréridj', 'Boumerdès', 'El Tarf',
        'Tindouf', 'Tissemsilt', 'El Oued', 'Khenchela', 'Souk Ahras', 'Tipaza', 'Mila',
        'Aïn Defla', 'Naâma', 'Aïn Témouchent', 'Ghardaïa', 'Relizane'
      ];
    } catch (e) {
      print('❌ Erreur fetchWilayas: $e');
      return [
        'Adrar', 'Chlef', 'Laghouat', 'Oum El Bouaghi', 'Batna', 'Béjaïa', 'Biskra',
        'Béchar', 'Blida', 'Bouira', 'Tamanrasset', 'Tébessa', 'Tlemcen', 'Tiaret',
        'Tizi Ouzou', 'Alger', 'Djelfa', 'Jijel', 'Sétif', 'Saïda', 'Skikda', 'Sidi Bel Abbès',
        'Annaba', 'Guelma', 'Constantine', 'Médéa', 'Mostaganem', 'M\'Sila', 'Mascara',
        'Ouargla', 'Oran', 'El Bayadh', 'Illizi', 'Bordj Bou Arréridj', 'Boumerdès', 'El Tarf',
        'Tindouf', 'Tissemsilt', 'El Oued', 'Khenchela', 'Souk Ahras', 'Tipaza', 'Mila',
        'Aïn Defla', 'Naâma', 'Aïn Témouchent', 'Ghardaïa', 'Relizane'
      ];
    }
  }

  Future<Map<String, dynamic>> addSchool(Map<String, dynamic> schoolData) async {
    print('🏫 Enregistrement d\'une nouvelle école');

    try {
      final url = Uri.parse('$API_BASE_URL/schools');
      final headers = await _getHeaders();

      print('📝 Données école: $schoolData');

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(schoolData),
      );

      _debugResponse(response, 'schools');

      if (response.statusCode == 201) {
        print('✅ École enregistrée avec succès');
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Erreur: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ Erreur lors de l\'enregistrement de l\'école: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchSchools({String? wilaya}) async {
    try {
      String urlString = '$API_BASE_URL/schools';
      if (wilaya != null && wilaya.isNotEmpty) {
        urlString += '?wilaya=$wilaya';
      }

      final url = Uri.parse(urlString);
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['schools'] != null && data['schools'] is List) {
          return List<Map<String, dynamic>>.from(data['schools']);
        } else if (data['schools'] != null && data['schools'] is Map) {
          if (data['schools']['data'] != null) {
            return List<Map<String, dynamic>>.from(data['schools']['data']);
          }
        }
      }
      return [];
    } catch (e) {
      print('❌ Erreur fetchSchools détaillée: $e');
      return [];
    }
  }

  // --- 8. GÉOLOCALISATION ---
  Future<Position> getCurrentLocation() async {
    print('📍 Récupération de la position actuelle');

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Les services de localisation sont désactivés.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Les permissions de localisation sont refusées.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Les permissions de localisation sont définitivement refusées.');
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      print('✅ Position obtenue: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('❌ Erreur getCurrentLocation: $e');
      rethrow;
    }
  }

  // --- 9. AUTRES MÉTHODES ---
  Future<List<dynamic>> fetchMyActivity() async {
    print('📋 Chargement de l\'activité récente');

    try {
      final url = Uri.parse('$API_BASE_URL/dashboard/my-activity');
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['activities'] is List) {
          return data['activities'];
        }
      }
      return [];
    } catch (e) {
      print('❌ Erreur fetchMyActivity: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> checkSchoolLocation({
    required int schoolId,
    required double latitude,
    required double longitude,
  }) async {
    print('📍 Vérification de la localisation pour l\'école $schoolId');

    try {
      final url = Uri.parse('$API_BASE_URL/schools/$schoolId/check-location');
      final headers = await _getHeaders();

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      _debugResponse(response, 'check-location');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Échec de la vérification de la localisation: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur checkSchoolLocation: $e');
      rethrow;
    }
  }

  // --- 10. TEST DE CONNEXION ---
  Future<bool> testConnection() async {
    print('🔗 Test de connexion à l\'API');

    try {
      final url = Uri.parse('$API_BASE_URL/sanctum/csrf-cookie');
      final response = await http.get(url);

      print('🌐 Test de connexion: ${response.statusCode}');
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (e) {
      print('❌ Erreur de connexion: $e');
      return false;
    }
  }

  // --- 11. NOUVELLES MÉTHODES POUR LES STATISTIQUES ---
  Future<Map<String, dynamic>> fetchMonthlySummary() async {
    print('📅 Chargement du résumé mensuel');

    try {
      final url = Uri.parse('$API_BASE_URL/dashboard/monthly-summary');
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors du chargement du résumé mensuel: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur fetchMonthlySummary: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchDeliveryStats() async {
    print('📊 Chargement des statistiques de livraison');

    try {
      final url = Uri.parse('$API_BASE_URL/deliveries/stats');
      final headers = await _getHeaders();

      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lors du chargement des stats de livraison: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur fetchDeliveryStats: $e');
      rethrow;
    }
  }
}