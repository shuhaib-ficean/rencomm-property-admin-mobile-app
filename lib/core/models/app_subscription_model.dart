import 'package:equatable/equatable.dart';

class AppSubscriptionModel extends Equatable {
  final String id;
  final String planName;
  final double amount;
  final String status;
  final DateTime startDate;
  final DateTime endDate;

  const AppSubscriptionModel({
    required this.id,
    required this.planName,
    required this.amount,
    required this.status,
    required this.startDate,
    required this.endDate,
  });

  factory AppSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return AppSubscriptionModel(
      id: json['id'] ?? '',
      planName: json['planName'] ?? 'Unknown Plan',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Unknown',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate']) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        planName,
        amount,
        status,
        startDate,
        endDate,
      ];
}

class SubscriptionPaymentModel extends Equatable {
  final String id;
  final double amount;
  final String status;
  final DateTime paymentDate;

  const SubscriptionPaymentModel({
    required this.id,
    required this.amount,
    required this.status,
    required this.paymentDate,
  });

  factory SubscriptionPaymentModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPaymentModel(
      id: json['id'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Unknown',
      paymentDate: json['paymentDate'] != null
          ? DateTime.tryParse(json['paymentDate']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        amount,
        status,
        paymentDate,
      ];
}
