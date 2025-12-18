// lib/models/delivery.dart
import 'package:intl/intl.dart';

class Delivery {
  final int id;
  final String deliveryDate;
  final int quantity;
  final double finalPrice;
  final double? unitPrice;
  final String status;
  final String schoolName;
  final String? kioskName;
  final int? schoolId;
  final int? distributorId;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? paymentStatus;
  final double? paidAmount;
  final double? remainingAmount;

  // Propriétés calculées
  String get formattedDate {
    try {
      final date = DateTime.parse(deliveryDate);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return deliveryDate;
    }
  }

  String get formattedPrice => '${finalPrice.toStringAsFixed(2)} DZD';

  String get formattedQuantity => '$quantity unités';

  bool get isCompleted => status.toLowerCase() == 'completed' ||
      status.toLowerCase() == 'livré' ||
      status.toLowerCase() == 'terminé';

  bool get isPending => status.toLowerCase() == 'pending' ||
      status.toLowerCase() == 'en attente';

  bool get isInProgress => status.toLowerCase() == 'in_progress' ||
      status.toLowerCase() == 'en cours';

  bool get isCancelled => status.toLowerCase() == 'cancelled' ||
      status.toLowerCase() == 'annulé';

  bool get hasLocation => latitude != null && longitude != null;

  double get calculatedUnitPrice {
    if (unitPrice != null) return unitPrice!;
    if (quantity > 0) return finalPrice / quantity;
    return 0.0;
  }

  Delivery({
    required this.id,
    required this.deliveryDate,
    required this.quantity,
    required this.finalPrice,
    this.unitPrice,
    required this.status,
    required this.schoolName,
    this.kioskName,
    this.schoolId,
    this.distributorId,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
    this.paymentStatus,
    this.paidAmount,
    this.remainingAmount,
  });

  // Constructeur fromJson robuste
  factory Delivery.fromJson(Map<String, dynamic> json) {
    // Helper pour parser les dates
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        return null;
      }
    }

    // Helper pour parser les doubles
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is String) return double.tryParse(value);
      if (value is num) return value.toDouble();
      return null;
    }

    // Helper pour parser les ints
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is num) return value.toInt();
      return null;
    }

    return Delivery(
      id: parseInt(json['id']) ?? 0,
      deliveryDate: json['delivery_date']?.toString() ??
          json['deliveryDate']?.toString() ?? '',
      quantity: parseInt(json['quantity']) ?? 0,
      finalPrice: parseDouble(json['final_price'] ?? json['finalPrice']) ?? 0.0,
      unitPrice: parseDouble(json['unit_price'] ?? json['unitPrice']),
      status: json['status']?.toString() ?? 'pending',
      schoolName: json['school_name']?.toString() ??
          json['schoolName']?.toString() ??
          json['school']?['name']?.toString() ?? 'N/A',
      kioskName: json['kiosk_name']?.toString() ??
          json['kioskName']?.toString() ??
          json['kiosk']?['name']?.toString(),
      schoolId: parseInt(json['school_id'] ?? json['schoolId']),
      distributorId: parseInt(json['distributor_id'] ?? json['distributorId']),
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      createdAt: parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: parseDateTime(json['updated_at'] ?? json['updatedAt']),
      paymentStatus: json['payment_status']?.toString() ??
          json['paymentStatus']?.toString(),
      paidAmount: parseDouble(json['paid_amount'] ?? json['paidAmount']),
      remainingAmount: parseDouble(json['remaining_amount'] ?? json['remainingAmount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'delivery_date': deliveryDate,
      'quantity': quantity,
      'final_price': finalPrice,
      'unit_price': unitPrice,
      'status': status,
      'school_name': schoolName,
      'kiosk_name': kioskName,
      'school_id': schoolId,
      'distributor_id': distributorId,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'payment_status': paymentStatus,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
    };
  }

  // Méthode pour créer une livraison pour l'API
  Map<String, dynamic> toApiJson() {
    return {
      'school_id': schoolId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'final_price': finalPrice,
      'delivery_date': deliveryDate,
      'status': status,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
  }

  // Méthode pour le statut avec couleur
  Map<String, dynamic> get statusInfo {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'livré':
      case 'terminé':
        return {
          'text': 'Terminé',
          'color': 0xFF4CAF50, // Vert
          'icon': 'check_circle',
        };
      case 'pending':
      case 'en attente':
        return {
          'text': 'En attente',
          'color': 0xFFFF9800, // Orange
          'icon': 'pending',
        };
      case 'in_progress':
      case 'en cours':
        return {
          'text': 'En cours',
          'color': 0xFF2196F3, // Bleu
          'icon': 'local_shipping',
        };
      case 'cancelled':
      case 'annulé':
        return {
          'text': 'Annulé',
          'color': 0xFFF44336, // Rouge
          'icon': 'cancel',
        };
      default:
        return {
          'text': status,
          'color': 0xFF9E9E9E, // Gris
          'icon': 'help',
        };
    }
  }

  // Méthode pour le statut de paiement
  Map<String, dynamic> get paymentStatusInfo {
    final remaining = remainingAmount ?? finalPrice - (paidAmount ?? 0);

    if (remaining <= 0) {
      return {
        'text': 'Payé',
        'color': 0xFF4CAF50, // Vert
        'icon': 'check_circle',
        'percentage': 100,
      };
    } else if (paidAmount != null && paidAmount! > 0) {
      final percentage = ((paidAmount! / finalPrice) * 100).toInt();
      return {
        'text': 'Partiellement payé',
        'color': 0xFFFF9800, // Orange
        'icon': 'payments',
        'percentage': percentage,
      };
    } else {
      return {
        'text': 'Non payé',
        'color': 0xFFF44336, // Rouge
        'icon': 'money_off',
        'percentage': 0,
      };
    }
  }

  // Crée une copie avec des valeurs mises à jour
  Delivery copyWith({
    int? id,
    String? deliveryDate,
    int? quantity,
    double? finalPrice,
    double? unitPrice,
    String? status,
    String? schoolName,
    String? kioskName,
    int? schoolId,
    int? distributorId,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? paymentStatus,
    double? paidAmount,
    double? remainingAmount,
  }) {
    return Delivery(
      id: id ?? this.id,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      quantity: quantity ?? this.quantity,
      finalPrice: finalPrice ?? this.finalPrice,
      unitPrice: unitPrice ?? this.unitPrice,
      status: status ?? this.status,
      schoolName: schoolName ?? this.schoolName,
      kioskName: kioskName ?? this.kioskName,
      schoolId: schoolId ?? this.schoolId,
      distributorId: distributorId ?? this.distributorId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paidAmount: paidAmount ?? this.paidAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
    );
  }

  // Méthode pour formater les détails
  String get detailsSummary {
    return '$formattedDate - $schoolName - $formattedQuantity - $formattedPrice';
  }

  @override
  String toString() {
    return 'Delivery(id: $id, date: $deliveryDate, school: $schoolName, status: $status, amount: $finalPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Delivery && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Pour la réponse paginée des livraisons
class DeliveryResponse {
  final List<Delivery> deliveries;
  final int currentPage;
  final int total;
  final int perPage;
  final int lastPage;

  DeliveryResponse({
    required this.deliveries,
    required this.currentPage,
    required this.total,
    required this.perPage,
    required this.lastPage,
  });

  factory DeliveryResponse.fromJson(Map<String, dynamic> json) {
    // CORRECTION: Extraction flexible des données
    List<dynamic> deliveriesData = [];

    // Format 1: { "deliveries": { "data": [...], "current_page": 1, ... } }
    if (json['deliveries'] is Map && json['deliveries']['data'] is List) {
      deliveriesData = json['deliveries']['data'] as List<dynamic>;
    }
    // Format 2: { "data": [...] }
    else if (json['data'] is List) {
      deliveriesData = json['data'] as List<dynamic>;
    }
    // Format 3: Directement une liste de livraisons
    else if (json['deliveries'] is List) {
      deliveriesData = json['deliveries'] as List<dynamic>;
    }
    // Format 4: Liste directe (ne peut pas arriver car json est une Map)

    return DeliveryResponse(
      deliveries: deliveriesData.map((data) => Delivery.fromJson(data)).toList(),
      currentPage: json['deliveries'] is Map ?
      (json['deliveries']['current_page'] as int? ?? 1) :
      (json['current_page'] as int? ?? 1),
      total: json['deliveries'] is Map ?
      (json['deliveries']['total'] as int? ?? 0) :
      (json['total'] as int? ?? 0),
      perPage: json['deliveries'] is Map ?
      (json['deliveries']['per_page'] as int? ?? 20) :
      (json['per_page'] as int? ?? 20),
      lastPage: json['deliveries'] is Map ?
      (json['deliveries']['last_page'] as int? ?? 1) :
      (json['last_page'] as int? ?? 1),
    );
  }
}

// Pour les statistiques de livraison
class DeliveryStats {
  final int totalDeliveries;
  final int pendingDeliveries;
  final int completedDeliveries;
  final double totalAmount;
  final double paidAmount;
  final double remainingAmount;
  final int todaysDeliveries;
  final int monthlyDeliveries;

  DeliveryStats({
    required this.totalDeliveries,
    required this.pendingDeliveries,
    required this.completedDeliveries,
    required this.totalAmount,
    required this.paidAmount,
    required this.remainingAmount,
    required this.todaysDeliveries,
    required this.monthlyDeliveries,
  });

  factory DeliveryStats.fromJson(Map<String, dynamic> json) {
    // Helper pour parser
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is num) return value.toInt();
      return 0;
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is String) return double.tryParse(value) ?? 0.0;
      if (value is num) return value.toDouble();
      return 0.0;
    }

    return DeliveryStats(
      totalDeliveries: parseInt(json['total_deliveries'] ?? json['totalDeliveries']),
      pendingDeliveries: parseInt(json['pending_deliveries'] ?? json['pendingDeliveries']),
      completedDeliveries: parseInt(json['completed_deliveries'] ?? json['completedDeliveries']),
      totalAmount: parseDouble(json['total_amount'] ?? json['totalAmount']),
      paidAmount: parseDouble(json['paid_amount'] ?? json['paidAmount']),
      remainingAmount: parseDouble(json['remaining_amount'] ?? json['remainingAmount']),
      todaysDeliveries: parseInt(json['todays_deliveries'] ?? json['todaysDeliveries']),
      monthlyDeliveries: parseInt(json['monthly_deliveries'] ?? json['monthlyDeliveries']),
    );
  }
}