class Payment {
  final int id;
  final String studentId;
  final double amountPaid;
  final bool status;
  final int semester;
  final DateTime createdAt;
  final String? gatewayPaymentId;

  Payment({
    required this.id,
    required this.studentId,
    required this.amountPaid,
    required this.status,
    required this.semester,
    required this.createdAt,
    this.gatewayPaymentId,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as int,
      studentId: json['student_id'] as String,
      amountPaid: (json['amount_paid'] as num).toDouble(),
      status: json['status'] as bool? ?? false,
      semester: json['semester'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      gatewayPaymentId: json['gateway_payment_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'amount_paid': amountPaid,
      'status': status,
      'semester': semester,
      'created_at': createdAt.toIso8601String(),
      'gateway_payment_id': gatewayPaymentId,
    };
  }
}
