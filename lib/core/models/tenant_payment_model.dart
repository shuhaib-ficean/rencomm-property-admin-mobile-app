class TenantPaymentModel {
  final String id;
  final String tenantId;
  final double amount;
  final DateTime paymentDate;
  final String? notes;
  final String? createdBy;

  TenantPaymentModel({
    required this.id,
    required this.tenantId,
    required this.amount,
    required this.paymentDate,
    this.notes,
    this.createdBy,
  });

  factory TenantPaymentModel.fromJson(Map<String, dynamic> json) {
    return TenantPaymentModel(
      id: json['id'],
      tenantId: json['tenantId'],
      amount: (json['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(json['paymentDate']),
      notes: json['notes'],
      createdBy: json['createdBy'] != null ? json['createdBy']['name'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'amount': amount,
      'paymentDate': paymentDate.toIso8601String(),
      'notes': notes,
    };
  }
}
