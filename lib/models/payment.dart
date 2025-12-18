import 'package:intl/intl.dart'; // Pour DateFormat

class Payment {
  final int id;
  final double amount;
  final String paymentDate;
  final String method;
  final String? referenceNumber;

  Payment({
    required this.id,
    required this.amount,
    required this.paymentDate,
    required this.method,
    this.referenceNumber,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      paymentDate: json['payment_date']?.toString() ?? '',
      method: json['method']?.toString() ?? 'cash',
      referenceNumber: json['reference_number']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'payment_date': paymentDate,
      'method': method,
      'reference_number': referenceNumber,
    };
  }
}