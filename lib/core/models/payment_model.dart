import 'package:equatable/equatable.dart';

class PaymentModel extends Equatable {
  final String id;
  final double amount;
  final String paymentMethod;
  final DateTime paymentDate;
  final String receiptNumber;
  final String? transactionId;
  final String? notes;
  final String? tenantId;
  final String? propertyId;
  final String? leaseId;
  final String? receivedById;
  final String? tenantName;
  final String? propertyName;
  final String? receivedByName;
  final String? createdByName;
  final DateTime? lastPaymentDate;
  final bool isSecurityDeposit;
  final DateTime createdAt;

  const PaymentModel({
    required this.id,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    required this.receiptNumber,
    this.transactionId,
    this.notes,
    this.tenantId,
    this.propertyId,
    this.leaseId,
    this.receivedById,
    this.tenantName,
    this.propertyName,
    this.receivedByName,
    this.createdByName,
    this.lastPaymentDate,
    this.isSecurityDeposit = false,
    required this.createdAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? '',
      paymentDate: DateTime.parse(json['paymentDate']),
      receiptNumber: json['receiptNumber'] ?? '',
      transactionId: json['transactionId'],
      notes: json['notes'],
      tenantId: json['tenantId'] ?? '',
      propertyId: json['propertyId'] ?? '',
      leaseId: json['leaseId'],
      receivedById: json['receivedById'] ?? '',
      tenantName: json['tenant']?['name'],
      propertyName: json['property']?['name'],
      receivedByName: json['receivedBy']?['name'],
      createdByName: json['createdBy']?['name'],
      isSecurityDeposit: json['isSecurityDeposit'] == true ||
          json['isSecurityDeposit'] == 'true',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentDate': paymentDate.toIso8601String(),
      'receiptNumber': receiptNumber,
      'transactionId': transactionId,
      'notes': notes,
      'tenantId': tenantId,
      'propertyId': propertyId,
      'leaseId': leaseId,
      'receivedById': receivedById,
      'isSecurityDeposit': isSecurityDeposit,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        amount,
        paymentMethod,
        paymentDate,
        receiptNumber,
        transactionId,
        notes,
        tenantId,
        propertyId,
        leaseId,
        receivedById,
        tenantName,
        propertyName,
        receivedByName,
        createdByName,
        isSecurityDeposit,
        createdAt,
      ];
}
