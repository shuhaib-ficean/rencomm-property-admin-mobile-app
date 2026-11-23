import 'package:equatable/equatable.dart';

class StaffCollectionModel extends Equatable {
  final String staffId;
  final String staffName;
  final String employeeId;
  final double totalAmount;
  final int paymentCount;

  const StaffCollectionModel({
    required this.staffId,
    required this.staffName,
    required this.employeeId,
    required this.totalAmount,
    required this.paymentCount,
  });

  factory StaffCollectionModel.fromJson(Map<String, dynamic> json) {
    return StaffCollectionModel(
      staffId: json['staffId']?.toString() ?? '',
      staffName: json['staffName']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? '',
      totalAmount:
          double.tryParse(json['totalAmount']?.toString() ?? '0') ?? 0.0,
      paymentCount: int.tryParse(json['paymentCount']?.toString() ?? '0') ?? 0,
    );
  }

  @override
  List<Object?> get props =>
      [staffId, staffName, employeeId, totalAmount, paymentCount];
}

class TenantSummaryModel extends Equatable {
  final int totalTenants;
  final double totalReceived;
  final double totalPending;
  final double totalExpected;
  final int totalVacantRooms;
  final int totalRooms;
  final int totalOccupiedRooms;
  final int totalPendingRepairs;

  const TenantSummaryModel({
    required this.totalTenants,
    required this.totalReceived,
    required this.totalPending,
    required this.totalExpected,
    required this.totalVacantRooms,
    required this.totalRooms,
    required this.totalOccupiedRooms,
    required this.totalPendingRepairs,
  });

  factory TenantSummaryModel.fromJson(Map<String, dynamic> json) {
    return TenantSummaryModel(
      totalTenants: int.tryParse(json['totalTenants']?.toString() ?? '0') ?? 0,
      totalReceived:
          double.tryParse(json['totalReceived']?.toString() ?? '0') ?? 0.0,
      totalPending:
          double.tryParse(json['totalPending']?.toString() ?? '0') ?? 0.0,
      totalExpected:
          double.tryParse(json['totalExpected']?.toString() ?? '0') ?? 0.0,
      totalVacantRooms:
          int.tryParse(json['totalVacantRooms']?.toString() ?? '0') ?? 0,
      totalRooms: int.tryParse(json['totalRooms']?.toString() ?? '0') ?? 0,
      totalOccupiedRooms: int.tryParse(json['totalOccupiedRooms']?.toString() ?? '0') ?? 0,
      totalPendingRepairs: int.tryParse(json['totalPendingRepairs']?.toString() ?? '0') ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        totalTenants,
        totalReceived,
        totalPending,
        totalExpected,
        totalVacantRooms,
        totalRooms,
        totalOccupiedRooms,
        totalPendingRepairs,
      ];
}

class PaymentHistoryItemModel extends Equatable {
  final String id;
  final String name;
  final String property;
  final DateTime date;
  final double amount;
  final String method;
  final String by;
  final String byFull;
  final String transactionId;
  final String receiptNumber;

  const PaymentHistoryItemModel({
    required this.id,
    required this.name,
    required this.property,
    required this.date,
    required this.amount,
    required this.method,
    required this.by,
    required this.byFull,
    required this.transactionId,
    required this.receiptNumber,
  });

  factory PaymentHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return PaymentHistoryItemModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      property: json['property'] ?? '',
      date: DateTime.parse(json['date']),
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      method: json['method'] ?? '',
      by: json['by'] ?? '',
      byFull: json['byFull'] ?? '',
      transactionId: json['transactionId'] ?? '',
      receiptNumber: json['receiptNumber'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        property,
        date,
        amount,
        method,
        by,
        byFull,
        transactionId,
        receiptNumber
      ];
}
