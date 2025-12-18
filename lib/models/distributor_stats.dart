// lib/models/distributor_stats.dart

class DistributorStats {
  final int totalDeliveries;
  final double totalDeliveredAmount;
  final double totalPaid;
  final double remaining;
  final int monthlyDeliveries;
  final double monthlyAmount;
  final int schoolsServed;

  // Nouveaux champs pour les cartes (avec valeurs par défaut)
  final int totalCards;
  final int cardsDelivered;
  final int cardsAvailable;
  final int cardsPending;

  // Statistiques de paiement
  final int totalPayments;
  final double lastPaymentAmount;
  final DateTime? lastPaymentDate;
  final double paymentRate;

  final List<RecentDelivery> recentDeliveries;
  final List<RecentPayment> recentPayments;

  // Constructeur principal
  DistributorStats({
    required this.totalDeliveries,
    required this.totalDeliveredAmount,
    required this.totalPaid,
    required this.remaining,
    required this.monthlyDeliveries,
    required this.monthlyAmount,
    required this.schoolsServed,
    required this.totalCards,
    required this.cardsDelivered,
    required this.cardsAvailable,
    required this.cardsPending,
    required this.totalPayments,
    required this.lastPaymentAmount,
    required this.lastPaymentDate,
    required this.paymentRate,
    required this.recentDeliveries,
    required this.recentPayments,
  });

  // Constructeur avec valeurs par défaut
  factory DistributorStats.empty() {
    return DistributorStats(
      totalDeliveries: 0,
      totalDeliveredAmount: 0.0,
      totalPaid: 0.0,
      remaining: 0.0,
      monthlyDeliveries: 0,
      monthlyAmount: 0.0,
      schoolsServed: 0,
      totalCards: 0,
      cardsDelivered: 0,
      cardsAvailable: 0,
      cardsPending: 0,
      totalPayments: 0,
      lastPaymentAmount: 0.0,
      lastPaymentDate: null,
      paymentRate: 0.0,
      recentDeliveries: [],
      recentPayments: [],
    );
  }

  factory DistributorStats.fromJson(Map<String, dynamic> json) {
    try {
      // Vérifier si la réponse a un champ 'success'
      if (json['success'] == false) {
        print('⚠️ API returned success: false');
        return DistributorStats.empty();
      }

      // Extraire les données - plusieurs formats possibles
      final Map<String, dynamic> data;

      if (json['data'] != null && json['data'] is Map) {
        data = Map<String, dynamic>.from(json['data']);
      } else if (json['stats'] != null && json['stats'] is Map) {
        data = Map<String, dynamic>.from(json['stats']);
      } else {
        data = Map<String, dynamic>.from(json);
      }

      print('📊 Parsing data keys: ${data.keys.toList()}');

      // Extraire les valeurs avec des méthodes sécurisées
      final totalDeliveries = _getInt(data, ['totalOrders', 'total_deliveries']);
      final totalRevenue = _getDouble(data, ['totalRevenue', 'total_delivered_amount']);
      final totalPaid = _getDouble(data, ['totalPaid', 'total_paid']);
      final remaining = _getDouble(data, ['remainingAmount', 'remaining']);

      // Statistiques des cartes
      final totalCards = _getInt(data, ['totalCards', 'total_cards']);
      final cardsDelivered = _getInt(data, ['cardsDelivered', 'cards_delivered', 'quantity_sum']);
      final cardsPending = _getInt(data, ['cardsPending', 'cards_pending']);

      // Calculer les cartes disponibles
      final calculatedCardsAvailable = totalCards - (cardsDelivered + cardsPending);
      final cardsAvailable = calculatedCardsAvailable > 0 ? calculatedCardsAvailable : 0;

      // Statistiques mensuelles
      final monthlyDeliveries = _getInt(data, ['monthlyDeliveries', 'monthly_deliveries']);
      final monthlyAmount = _getDouble(data, ['monthlyRevenue', 'monthly_amount']);
      final schoolsServed = _getInt(data, ['assignedSchools', 'schools_served']);

      // Statistiques de paiement
      final totalPayments = _getInt(data, ['totalPayments', 'total_payments']);
      final lastPaymentAmount = _getDouble(data, ['lastPaymentAmount', 'last_payment_amount']);

      // Date du dernier paiement
      DateTime? lastPaymentDate;
      final lastPaymentDateStr = _getString(data, ['lastPaymentDate', 'last_payment_date']);
      if (lastPaymentDateStr != null && lastPaymentDateStr.isNotEmpty) {
        lastPaymentDate = DateTime.tryParse(lastPaymentDateStr);
      }

      // Calcul du taux de paiement
      final paymentRate = totalRevenue > 0 ? (totalPaid / totalRevenue) * 100 : 0.0;

      // Livraisons récentes
      final List<dynamic> recentOrdersData = data['recentOrders'] is List
          ? List<dynamic>.from(data['recentOrders'])
          : [];

      final deliveriesList = recentOrdersData
          .map((i) => RecentDelivery.fromJson(i))
          .where((delivery) => delivery.school.isNotEmpty) // Filtrer les vides
          .toList();

      // Paiements récents
      final List<dynamic> recentPaymentsData = data['recentPayments'] is List
          ? List<dynamic>.from(data['recentPayments'])
          : [];

      final paymentsList = recentPaymentsData
          .map((i) => RecentPayment.fromJson(i))
          .where((payment) => payment.amount > 0) // Filtrer les paiements nuls
          .toList();

      return DistributorStats(
        totalDeliveries: totalDeliveries,
        totalDeliveredAmount: totalRevenue,
        totalPaid: totalPaid,
        remaining: remaining,
        monthlyDeliveries: monthlyDeliveries,
        monthlyAmount: monthlyAmount,
        schoolsServed: schoolsServed,
        totalCards: totalCards,
        cardsDelivered: cardsDelivered,
        cardsAvailable: cardsAvailable,
        cardsPending: cardsPending,
        totalPayments: totalPayments,
        lastPaymentAmount: lastPaymentAmount,
        lastPaymentDate: lastPaymentDate,
        paymentRate: paymentRate,
        recentDeliveries: deliveriesList,
        recentPayments: paymentsList,
      );
    } catch (e) {
      print('❌ Erreur critique dans DistributorStats.fromJson: $e');
      print('Stack trace: ${e.toString()}');
      print('JSON reçu: ${json.toString()}');
      return DistributorStats.empty();
    }
  }

  // Méthodes helper pour l'extraction sécurisée
  static int _getInt(Map<String, dynamic> data, List<String> keys) {
    for (var key in keys) {
      if (data[key] != null) {
        final value = data[key];
        if (value is int) return value;
        if (value is double) return value.toInt();
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
    }
    return 0;
  }

  static double _getDouble(Map<String, dynamic> data, List<String> keys) {
    for (var key in keys) {
      if (data[key] != null) {
        final value = data[key];
        if (value is double) return value;
        if (value is int) return value.toDouble();
        if (value is String) {
          final parsed = double.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
    }
    return 0.0;
  }

  static String? _getString(Map<String, dynamic> data, List<String> keys) {
    for (var key in keys) {
      if (data[key] != null) {
        final value = data[key];
        if (value is String) return value;
        return value.toString();
      }
    }
    return null;
  }
}

class RecentDelivery {
  final String date;
  final String school;
  final double amount;
  final String status;
  final int quantity;

  RecentDelivery({
    required this.date,
    required this.school,
    required this.amount,
    required this.status,
    required this.quantity,
  });

  factory RecentDelivery.fromJson(Map<String, dynamic> json) {
    try {
      return RecentDelivery(
        date: json['date']?.toString() ?? '',
        school: json['customer']?.toString() ?? json['school_name']?.toString() ?? 'Inconnu',
        amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
        status: json['status']?.toString() ?? 'N/A',
        quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      );
    } catch (e) {
      print('❌ Erreur dans RecentDelivery.fromJson: $e');
      return RecentDelivery(
        date: '',
        school: 'Inconnu',
        amount: 0.0,
        status: 'N/A',
        quantity: 0,
      );
    }
  }
}

class RecentPayment {
  final String date;
  final double amount;
  final String method;
  final String? reference;

  RecentPayment({
    required this.date,
    required this.amount,
    required this.method,
    this.reference,
  });

  factory RecentPayment.fromJson(Map<String, dynamic> json) {
    try {
      return RecentPayment(
        date: json['payment_date']?.toString() ?? json['date']?.toString() ?? '',
        amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
        method: json['method']?.toString() ?? json['payment_method']?.toString() ?? 'Non spécifié',
        reference: json['reference']?.toString() ?? json['reference_number']?.toString(),
      );
    } catch (e) {
      print('❌ Erreur dans RecentPayment.fromJson: $e');
      return RecentPayment(
        date: '',
        amount: 0.0,
        method: 'Non spécifié',
        reference: null,
      );
    }
  }
}