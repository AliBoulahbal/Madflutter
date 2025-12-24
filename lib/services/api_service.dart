import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../models/user.dart';
import '../models/delivery.dart';
import '../models/school.dart';
import '../models/payment.dart';

class ApiService {
  // Utilisez 10.0.2.2 pour l'émulateur Android, 127.0.0.1 pour Chrome
  final String baseUrl = "http://127.0.0.1:8000/api";
  String? _token;

  // --- AUTHENTIFICATION ---
  bool get isAuthenticated => _token != null;

  Future<void> initToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
  }

  Future<Map<String, dynamic>> login(String email, String password, [String? device]) async {
    final response = await _makeRequest('POST', 'login', {
      'email': email,
      'password': password,
      'device_name': device ?? 'mobile_app',
    });
    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', data['token']);
      _token = data['token'];
      return data;
    }
    throw Exception(data['message'] ?? 'Erreur de connexion');
  }

  Future<Map<String, dynamic>> fetchUserProfile() async {
    final response = await _makeRequest('GET', 'user', null);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Session expirée');
  }

  Future<void> logout() async {
    await _makeRequest('POST', 'logout', null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _token = null;
  }

  // --- LOGIQUE DE REQUÊTE DE BASE ---
  Future<http.Response> _makeRequest(String method, String endpoint, dynamic body) async {
    final url = Uri.parse('$baseUrl/$endpoint');
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };

    try {
      print("🌐 API Request: $method $url");

      http.Response response;
      if (method == 'POST') {
        print("📦 Request body: $body");
        response = await http.post(url, headers: headers, body: jsonEncode(body));
      } else {
        response = await http.get(url, headers: headers);
      }

      // Debug de la réponse
      print("📡 API Response (${response.statusCode}): ${response.body}");

      return response;
    } catch (e) {
      print("❌ Network error: $e");
      throw Exception('Erreur réseau : $e');
    }
  }

  // --- DASHBOARDS ---
  Future<Map<String, dynamic>> fetchDistributorDashboard() async {
    final response = await _makeRequest('GET', 'dashboard/distributor-stats', null);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erreur dashboard');
  }

  Future<Map<String, dynamic>> fetchAdminDashboard() async {
    final response = await _makeRequest('GET', 'dashboard/admin-stats', null);
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erreur dashboard admin');
  }

  // --- ÉCOLES ---
  Future<dynamic> fetchSchools() async {
    try {
      // On récupère la réponse brute sans essayer de la transformer en List ici
      final response = await _makeRequest('GET', 'schools', null);
      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Erreur de connexion aux écoles: $e');
    }
  }

  // --- WILAYAS & COMMUNES ---
  Future<List<String>> fetchWilayas() async {
    final response = await _makeRequest('GET', 'wilayas', null);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map) return List<String>.from(data['wilayas'] ?? []);
      return List<String>.from(data);
    }
    return ["Alger", "Oran", "Constantine", "Djelfa", "Batna", "Skikda"];
  }

  Future<List<String>> getCommunesByWilaya(String wilaya) async {
    try {
      final response = await _makeRequest('GET', 'schools/communes?wilaya=$wilaya', null);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map && data.containsKey('communes')) {
          return List<String>.from(data['communes']);
        }
      }
      return [];
    } catch (e) {
      print("❌ Erreur chargement communes: $e");
      return [];
    }
  }

  // MÉTHODE UNIQUE addSchool avec fallback
  Future<bool> addSchool(Map<String, dynamic> data) async {
    try {
      // Essayer d'abord l'endpoint pour distributeur
      final response = await _makeRequest('POST', 'schools/distributor-store', data);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      }

      // Fallback à l'endpoint normal
      final response2 = await _makeRequest('POST', 'schools', data);
      return response2.statusCode == 201 || response2.statusCode == 200;
    } catch (e) {
      print("❌ Erreur ajout école: $e");
      rethrow;
    }
  }

  // --- LIVRAISONS ---
  Future<List<Delivery>> fetchDeliveries() async {
    final response = await _makeRequest('GET', 'deliveries', null);
    final data = jsonDecode(response.body);
    List list = data['deliveries'] ?? data['data'] ?? [];
    return list.map((item) => Delivery.fromJson(item)).toList();
  }

  // Utilisé par le Dropdown de l'écran de paiement
  Future<List<dynamic>> fetchDeliveriesRaw() async {
    try {
      final response = await _makeRequest('GET', 'deliveries', null);
      final dynamic data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Vérifier la structure de la réponse
        if (data is Map) {
          // Si la réponse est une Map avec une clé 'data' ou 'deliveries'
          if (data['deliveries'] != null && data['deliveries'] is List) {
            return List<dynamic>.from(data['deliveries']);
          } else if (data['data'] != null && data['data'] is List) {
            return List<dynamic>.from(data['data']);
          } else if (data['recentOrders'] != null && data['recentOrders'] is List) {
            return List<dynamic>.from(data['recentOrders']);
          } else {
            // Si c'est une Map directe, la mettre dans une liste
            return [data];
          }
        } else if (data is List) {
          // Si la réponse est directement une liste
          return List<dynamic>.from(data);
        }
      }

      // Retourner une liste vide par défaut
      return [];
    } catch (e) {
      print("❌ Erreur fetchDeliveriesRaw: $e");
      throw Exception('Erreur de chargement des livraisons: $e');
    }
  }

  Future<bool> addDelivery(Map<String, dynamic> data) async {
    final response = await _makeRequest('POST', 'deliveries/storeWithLocation', data);
    return response.statusCode == 201 || response.statusCode == 200;
  }

  // --- PAIEMENTS ---
  Future<List<Payment>> fetchPayments() async {
    final response = await _makeRequest('GET', 'payments', null);
    final data = jsonDecode(response.body);
    List list = data['payments'] ?? data['data'] ?? [];
    return list.map((item) => Payment.fromJson(item)).toList();
  }

  Future<bool> addPayment(Map<String, dynamic> data) async {
    final response = await _makeRequest('POST', 'payments', data);
    if (response.statusCode == 201 || response.statusCode == 200) return true;
    final err = jsonDecode(response.body);
    throw Exception(err['message'] ?? 'Erreur lors du paiement');
  }

  // --- GPS ---
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
    );
  }
}