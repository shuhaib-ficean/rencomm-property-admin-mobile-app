import 'package:equatable/equatable.dart';
import 'property_model.dart';

class LeaseModel extends Equatable {
  final String id;
  final String tenantId;
  final String? roomId;
  final String? propertyId;
  final double rentAmount;
  final double securityDeposit;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isRecurring;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PropertyModel? propertyDetails;
  final RoomModel? roomDetails;
  final double? totalDue;
  final double? totalPaid;
  final double? totalPending;

  const LeaseModel({
    required this.id,
    required this.tenantId,
    this.roomId,
    this.propertyId,
    required this.rentAmount,
    required this.securityDeposit,
    required this.startDate,
    this.endDate,
    this.isRecurring = true,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.propertyDetails,
    this.roomDetails,
    this.totalDue,
    this.totalPaid,
    this.totalPending,
  });

  factory LeaseModel.fromJson(Map<String, dynamic> json) {
    return LeaseModel(
      id: json['id'] ?? '',
      tenantId: json['tenantId'] ?? '',
      roomId: json['roomId'],
      propertyId: json['propertyId'],
      rentAmount: (json['rentAmount'] is num
          ? (json['rentAmount'] as num).toDouble()
          : double.tryParse(json['rentAmount']?.toString() ?? '0') ?? 0.0),
      securityDeposit: (json['securityDeposit'] is num
          ? (json['securityDeposit'] as num).toDouble()
          : double.tryParse(json['securityDeposit']?.toString() ?? '0') ?? 0.0),
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate']) ?? DateTime.now()
          : DateTime.now(),
      endDate:
          json['endDate'] != null ? DateTime.tryParse(json['endDate']) : null,
      isRecurring: json['isRecurring'] ?? true,
      status: json['status'] ?? 'active',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
      propertyDetails: json['property'] != null
          ? PropertyModel.fromJson(json['property'])
          : null,
      roomDetails:
          json['room'] != null ? RoomModel.fromJson(json['room']) : null,
      totalDue: (json['totalDue'] as num?)?.toDouble(),
      totalPaid: (json['totalPaid'] as num?)?.toDouble(),
      totalPending: (json['totalPending'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tenantId': tenantId,
      'roomId': roomId,
      'propertyId': propertyId,
      'rentAmount': rentAmount,
      'securityDeposit': securityDeposit,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isRecurring': isRecurring,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'property': propertyDetails?.toJson(),
      'room': roomDetails?.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        tenantId,
        roomId,
        propertyId,
        rentAmount,
        securityDeposit,
        startDate,
        endDate,
        isRecurring,
        status,
        createdAt,
        updatedAt,
        propertyDetails,
        roomDetails,
        totalDue,
        totalPaid,
        totalPending,
      ];
}
