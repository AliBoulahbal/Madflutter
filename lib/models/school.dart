// lib/models/school.dart
import 'dart:math';
import 'package:intl/intl.dart';

class School {
  final int id;
  final String name;
  final String district;
  final String commune;
  final String address;
  final String? phone;
  final String managerName;
  final int studentCount;
  final String wilaya;
  final double? latitude;
  final double? longitude;
  final double? radius;
  final bool isActive;
  final int deliveriesCount;
  final double? totalDelivered;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Propriétés calculées
  bool get hasCoordinates => latitude != null && longitude != null;

  String get coordinatesFormatted => hasCoordinates
      ? '${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}'
      : 'Non définies';

  String get radiusFormatted {
    if (radius == null) return '50m (défaut)';
    final meters = radius! * 1000;
    return meters < 1000
        ? '${meters.toStringAsFixed(0)}m'
        : '${radius!.toStringAsFixed(2)}km';
  }

  School({
    required this.id,
    required this.name,
    required this.district,
    required this.commune,
    required this.address,
    this.phone,
    required this.managerName,
    required this.studentCount,
    required this.wilaya,
    this.latitude,
    this.longitude,
    this.radius,
    required this.isActive,
    this.deliveriesCount = 0,
    this.totalDelivered = 0,
    this.createdAt,
    this.updatedAt,
  });

  // Constructeur fromJson robuste
  factory School.fromJson(Map<String, dynamic> json) {
    // Helper pour parser les dates
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        return null;
      }
    }

    return School(
      id: _parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      commune: json['commune']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString(),
      managerName: json['manager_name']?.toString() ??
          json['managerName']?.toString() ?? '',
      studentCount: _parseInt(json['student_count'] ?? json['studentCount']) ?? 0,
      wilaya: json['wilaya']?.toString() ?? '',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      radius: _parseDouble(json['radius']),
      isActive: _parseBool(json['is_active'] ?? json['isActive']) ?? true,
      deliveriesCount: _parseInt(json['deliveries_count'] ?? json['deliveriesCount']) ?? 0,
      totalDelivered: _parseDouble(json['total_delivered'] ?? json['totalDelivered']),
      createdAt: parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  // Helper methods pour le parsing
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is String) {
      return double.tryParse(value);
    }
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  static bool? _parseBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is num) {
      return value == 1;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'district': district,
      'commune': commune,
      'address': address,
      'phone': phone,
      'manager_name': managerName,
      'student_count': studentCount,
      'wilaya': wilaya,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'is_active': isActive,
      'deliveries_count': deliveriesCount,
      'total_delivered': totalDelivered,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Méthode pour calculer la distance
  double calculateDistance(double userLat, double userLng) {
    if (!hasCoordinates) return 0;

    const earthRadius = 6371.0; // km

    final dLat = _degreesToRadians(userLat - latitude!);
    final dLon = _degreesToRadians(userLng - longitude!);

    final a = sin(dLat/2) * sin(dLat/2) +
        cos(_degreesToRadians(latitude!)) * cos(_degreesToRadians(userLat)) *
            sin(dLon/2) * sin(dLon/2);

    final c = 2 * atan2(sqrt(a), sqrt(1-a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Vérifie si l'utilisateur est dans le rayon
  bool isWithinRadius(double userLat, double userLng) {
    if (!hasCoordinates) return true;

    final distance = calculateDistance(userLat, userLng);
    return distance <= (radius ?? 0.05);
  }

  // Crée un lien Google Maps
  String? get googleMapsLink {
    if (!hasCoordinates) return null;
    return "https://www.google.com/maps?q=$latitude,$longitude";
  }

  // Crée un lien OpenStreetMap
  String? get openStreetMapLink {
    if (!hasCoordinates) return null;
    return "https://www.openstreetmap.org/?mlat=$latitude&mlon=$longitude#map=18/$latitude/$longitude";
  }

  // Vérifie si c'est le rayon par défaut
  bool get isDefaultRadius => radius == null || radius == 0.05;

  // Getter pour le rayon effectif
  double get effectiveRadius => radius ?? 0.05;

  // Getter pour le statut GPS
  Map<String, dynamic> get gpsStatus {
    if (!hasCoordinates) {
      return {
        'status': 'missing',
        'label': 'Coordonnées manquantes',
        'color': 'danger',
        'icon': 'location_off',
      };
    }

    if (!isActive) {
      return {
        'status': 'inactive',
        'label': 'Coordonnées définies (inactive)',
        'color': 'warning',
        'icon': 'location_on',
      };
    }

    return {
      'status': 'active',
      'label': 'Coordonnées actives',
      'color': 'success',
      'icon': 'check_circle',
    };
  }

  // Méthode pour formater les coordonnées
  String? get latitudeFormatted => latitude?.toStringAsFixed(8);
  String? get longitudeFormatted => longitude?.toStringAsFixed(8);

  // Méthode pour créer un School pour l'API
  Map<String, dynamic> toApiJson() {
    return {
      'name': name,
      'district': district,
      'commune': commune,
      'address': address,
      'phone': phone,
      'manager_name': managerName,
      'student_count': studentCount,
      'wilaya': wilaya,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
    };
  }

  // Crée une copie avec des valeurs mises à jour
  School copyWith({
    int? id,
    String? name,
    String? district,
    String? commune,
    String? address,
    String? phone,
    String? managerName,
    int? studentCount,
    String? wilaya,
    double? latitude,
    double? longitude,
    double? radius,
    bool? isActive,
    int? deliveriesCount,
    double? totalDelivered,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return School(
      id: id ?? this.id,
      name: name ?? this.name,
      district: district ?? this.district,
      commune: commune ?? this.commune,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      managerName: managerName ?? this.managerName,
      studentCount: studentCount ?? this.studentCount,
      wilaya: wilaya ?? this.wilaya,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
      isActive: isActive ?? this.isActive,
      deliveriesCount: deliveriesCount ?? this.deliveriesCount,
      totalDelivered: totalDelivered ?? this.totalDelivered,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'School(id: $id, name: $name, wilaya: $wilaya, commune: $commune)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is School && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Pour la réponse paginée des écoles
class SchoolResponse {
  final List<School> schools;
  final int currentPage;
  final int total;
  final int perPage;
  final int lastPage;

  SchoolResponse({
    required this.schools,
    required this.currentPage,
    required this.total,
    required this.perPage,
    required this.lastPage,
  });

  factory SchoolResponse.fromJson(Map<String, dynamic> json) {
    // CORRECTION: Extraction flexible des données
    List<dynamic> schoolsData = [];

    // Format 1: { "schools": { "data": [...], "current_page": 1, ... } }
    if (json['schools'] is Map && json['schools']['data'] is List) {
      schoolsData = json['schools']['data'] as List<dynamic>;
    }
    // Format 2: { "data": [...] }
    else if (json['data'] is List) {
      schoolsData = json['data'] as List<dynamic>;
    }
    // Format 3: Directement une liste d'écoles
    else if (json['schools'] is List) {
      schoolsData = json['schools'] as List<dynamic>;
    }
    // Format 4: Liste directe (pour les réponses simples)
    else if (json is List) {
      // Dans ce cas, json est déjà une liste, pas une Map
      // On ne peut pas arriver ici car fromJson prend une Map
      schoolsData = [];
    }

    return SchoolResponse(
      schools: schoolsData.map((data) => School.fromJson(data)).toList(),
      currentPage: json['schools'] is Map ?
      (json['schools']['current_page'] as int? ?? 1) :
      (json['current_page'] as int? ?? 1),
      total: json['schools'] is Map ?
      (json['schools']['total'] as int? ?? 0) :
      (json['total'] as int? ?? 0),
      perPage: json['schools'] is Map ?
      (json['schools']['per_page'] as int? ?? 20) :
      (json['per_page'] as int? ?? 20),
      lastPage: json['schools'] is Map ?
      (json['schools']['last_page'] as int? ?? 1) :
      (json['last_page'] as int? ?? 1),
    );
  }
}
// Pour les statistiques d'une école
class SchoolStats {
  final int totalDeliveries;
  final int totalCards;
  final double totalAmount;
  final Map<String, dynamic>? lastDelivery;

  SchoolStats({
    required this.totalDeliveries,
    required this.totalCards,
    required this.totalAmount,
    this.lastDelivery,
  });

  factory SchoolStats.fromJson(Map<String, dynamic> json) {
    return SchoolStats(
      totalDeliveries: School._parseInt(json['total_deliveries']) ?? 0,
      totalCards: School._parseInt(json['total_cards']) ?? 0,
      totalAmount: School._parseDouble(json['total_amount']) ?? 0.0,
      lastDelivery: json['last_delivery'] != null
          ? Map<String, dynamic>.from(json['last_delivery'])
          : null,
    );
  }
}