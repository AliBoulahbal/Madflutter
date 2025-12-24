import 'dart:convert';

class Delivery {
  final int id;
  final int? schoolId;
  final String schoolName;
  final int quantity;
  final double unitPrice;
  final double finalPrice;
  final double paidAmount;
  final double remainingAmount;
  final String status;
  final String? deliveryDate;
  final double? latitude;
  final double? longitude;

  Delivery({
    required this.id,
    this.schoolId,
    required this.schoolName,
    required this.quantity,
    required this.unitPrice,
    required this.finalPrice,
    required this.paidAmount,
    required this.remainingAmount,
    required this.status,
    this.deliveryDate,
    this.latitude,
    this.longitude,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    // Calcul automatique du reste à payer si le serveur ne l'envoie pas explicitement
    double fPrice = _parseDouble(json['final_price'] ?? json['total_price']);
    double pAmount = _parseDouble(json['paid_amount'] ?? 0);
    double rAmount = json['remaining_amount'] != null
        ? _parseDouble(json['remaining_amount'])
        : (fPrice - pAmount);

    return Delivery(
      id: json['id'] ?? 0,
      schoolId: json['school_id'],
      // Support pour les deux structures possibles (relation 'school' ou champ plat)
      schoolName: json['school'] != null
          ? (json['school']['name'] ?? 'École')
          : (json['school_name'] ?? 'École'),
      quantity: json['quantity'] ?? 0,
      unitPrice: _parseDouble(json['unit_price']),
      finalPrice: fPrice,
      paidAmount: pAmount,
      remainingAmount: rAmount,
      status: json['status'] ?? 'pending',
      deliveryDate: json['delivery_date'],
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
    );
  }

  // MÉTHODE DE SÉCURITÉ : Convertit n'importe quel type vers double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'final_price': finalPrice,
      'delivery_date': deliveryDate,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }
}