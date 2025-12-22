import 'dart:math';

class DistributorStats {
  final int totalCards;
  final int cardsDelivered;
  final int cardsAvailable;
  final int cardsPending;
  final double totalPaid;
  final double remaining;
  final double paymentRate;
  final double totalDeliveredAmount;
  final int schoolsServed;
  final List<RecentDelivery> recentDeliveries;
  final List<RecentPayment> recentPayments;

  DistributorStats({
    required this.totalCards,
    required this.cardsDelivered,
    required this.cardsAvailable,
    required this.cardsPending,
    required this.totalPaid,
    required this.remaining,
    required this.paymentRate,
    required this.totalDeliveredAmount,
    required this.schoolsServed,
    required this.recentDeliveries,
    required this.recentPayments,
  });

  factory DistributorStats.fromJson(Map<String, dynamic> json) {
    return DistributorStats(
      totalCards: json['total_cards'] ?? 0,
      cardsDelivered: json['cards_delivered'] ?? 0,
      cardsAvailable: json['cards_available'] ?? 0,
      cardsPending: json['cards_pending'] ?? 0,
      totalPaid: (json['total_paid'] ?? 0).toDouble(),
      remaining: (json['remaining'] ?? 0).toDouble(),
      paymentRate: (json['payment_rate'] ?? 0).toDouble(),
      totalDeliveredAmount: (json['total_delivered_amount'] ?? 0).toDouble(),
      schoolsServed: json['schools_served'] ?? 0,
      recentDeliveries: (json['recent_deliveries'] as List? ?? [])
          .map((e) => RecentDelivery.fromJson(e))
          .toList(),
      recentPayments: (json['recent_payments'] as List? ?? [])
          .map((e) => RecentPayment.fromJson(e))
          .toList(),
    );
  }

  static DistributorStats empty() {
    return DistributorStats(
      totalCards: 0,
      cardsDelivered: 0,
      cardsAvailable: 0,
      cardsPending: 0,
      totalPaid: 0,
      remaining: 0,
      paymentRate: 0,
      totalDeliveredAmount: 0,
      schoolsServed: 0,
      recentDeliveries: [],
      recentPayments: [],
    );
  }

  // NOUVELLE MÉTHODE POUR METTRE À JOUR
  DistributorStats copyWith({
    int? totalCards,
    int? cardsDelivered,
    int? cardsAvailable,
    int? cardsPending,
    double? totalPaid,
    double? remaining,
    double? paymentRate,
    double? totalDeliveredAmount,
    int? schoolsServed,
    List<RecentDelivery>? recentDeliveries,
    List<RecentPayment>? recentPayments,
  }) {
    return DistributorStats(
      totalCards: totalCards ?? this.totalCards,
      cardsDelivered: cardsDelivered ?? this.cardsDelivered,
      cardsAvailable: cardsAvailable ?? this.cardsAvailable,
      cardsPending: cardsPending ?? this.cardsPending,
      totalPaid: totalPaid ?? this.totalPaid,
      remaining: remaining ?? this.remaining,
      paymentRate: paymentRate ?? this.paymentRate,
      totalDeliveredAmount: totalDeliveredAmount ?? this.totalDeliveredAmount,
      schoolsServed: schoolsServed ?? this.schoolsServed,
      recentDeliveries: recentDeliveries ?? this.recentDeliveries,
      recentPayments: recentPayments ?? this.recentPayments,
    );
  }

  // Méthode pour ajouter un paiement
  DistributorStats addPayment(double amount, String method, String schoolName) {
    final newPayment = RecentPayment(
      method: method,
      date: DateTime.now().toIso8601String().split('T')[0],
      amount: amount,
      reference: 'Paiement - $schoolName',
    );

    final newTotalPaid = totalPaid + amount;
    final newRemaining = max(0, remaining - amount);
    final newPaymentRate = totalDeliveredAmount > 0
        ? ((newTotalPaid / totalDeliveredAmount) * 100)
        : 0;

    return copyWith(
      totalPaid: newTotalPaid,
      remaining: newRemaining.toDouble(), // Convertir en double
      paymentRate: newPaymentRate.toDouble(), // Convertir en double
      recentPayments: [newPayment, ...recentPayments.take(4)],
    );
  }

  // Méthode pour ajouter une livraison
  DistributorStats addDelivery(int quantity, double amount, String schoolName) {
    final newDelivery = RecentDelivery(
      school: schoolName,
      date: DateTime.now().toIso8601String().split('T')[0],
      quantity: quantity,
      amount: amount,
      status: 'completed',
    );

    final newCardsDelivered = cardsDelivered + quantity;
    final newCardsAvailable = max(0, cardsAvailable - quantity);
    final newTotalDelivered = totalDeliveredAmount + amount;
    final newRemaining = remaining + amount;

    // Recalculer le taux de paiement
    final newPaymentRate = newTotalDelivered > 0
        ? (totalPaid / newTotalDelivered * 100)
        : 0;

    return copyWith(
      cardsDelivered: newCardsDelivered,
      cardsAvailable: newCardsAvailable,
      totalDeliveredAmount: newTotalDelivered,
      remaining: newRemaining,
      paymentRate: newPaymentRate.toDouble(), // Convertir en double
      recentDeliveries: [newDelivery, ...recentDeliveries.take(4)],
    );
  }
}

class RecentDelivery {
  final String school;
  final String date;
  final int quantity;
  final double amount;
  final String status;

  RecentDelivery({
    required this.school,
    required this.date,
    required this.quantity,
    required this.amount,
    required this.status,
  });

  factory RecentDelivery.fromJson(Map<String, dynamic> json) {
    return RecentDelivery(
      school: json['school'] ?? 'École inconnue',
      date: json['date'] ?? '',
      quantity: json['quantity'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
    );
  }
}

class RecentPayment {
  final String method;
  final String date;
  final double amount;
  final String? reference;

  RecentPayment({
    required this.method,
    required this.date,
    required this.amount,
    this.reference,
  });

  factory RecentPayment.fromJson(Map<String, dynamic> json) {
    return RecentPayment(
      method: json['method'] ?? 'cash',
      date: json['date'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      reference: json['reference'],
    );
  }
}