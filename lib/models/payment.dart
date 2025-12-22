class Payment {
  final int id;
  final int deliveryId;
  final double amount;
  final String method;
  final String paymentDate;
  final String? note;
  final String? status; // Add this field
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Payment({
    required this.id,
    required this.deliveryId,
    required this.amount,
    required this.method,
    required this.paymentDate,
    this.note,
    this.status, // Add this
    this.createdAt,
    this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] ?? 0,
      deliveryId: json['delivery_id'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      method: json['payment_method'] ?? json['method'] ?? 'cash',
      paymentDate: json['payment_date'] ?? json['date'] ?? '',
      note: json['note'],
      status: json['status'], // Add this
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }
}