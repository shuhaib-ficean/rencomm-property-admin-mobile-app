import 'package:equatable/equatable.dart';
import 'lease_model.dart';
import 'property_model.dart';
import 'tenant_amenity_model.dart';

class TenantModel extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String phone;
  final String? qatarId;

  /// Passport front page images
  final List<String>? passportFrontImages;

  /// Passport back page images
  final List<String>? passportBackImages;

  /// Qatar ID images
  final List<String>? qatarIdImages;
  final double rentAmount;
  final double securityDeposit;
  final String? securityDepositPaymentId;
  final DateTime contractStartDate;
  final DateTime? contractEndDate;
  final String status;
  final String? assignedPropertyId;
  final PropertyModel? property;
  final String? assignedRoomId;
  final RoomModel? assignedRoom;
  final Financials? financials;
  final DateTime? lastPaymentDate;
  final List<LeaseModel>? leaseList;
  final List<TenantAmenityModel>? amenities;
  final String? createdById;
  final String? createdByName;

  const TenantModel({
    required this.id,
    required this.name,
    this.email,
    required this.phone,
    this.qatarId,
    this.passportFrontImages,
    this.passportBackImages,
    this.qatarIdImages,
    required this.rentAmount,
    required this.securityDeposit,
    this.securityDepositPaymentId,
    required this.contractStartDate,
    this.contractEndDate,
    required this.status,
    this.assignedPropertyId,
    this.property,
    this.assignedRoomId,
    this.assignedRoom,
    this.financials,
    this.lastPaymentDate,
    this.leaseList,
    this.amenities,
    this.createdById,
    this.createdByName,
  });

  double get totalPaid => financials?.totalPaid ?? 0.0;
  double get totalAmount => financials?.totalAmount ?? 0.0;
  double get totalPending => financials?.totalPending ?? 0.0;

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'],
      phone: json['phone'] ?? '',
      qatarId: json['qatarId'],
      passportFrontImages: json['passportFrontImages'] != null
          ? List<String>.from(json['passportFrontImages'])
          : (json['passportFrontDoc'] != null
              ? (json['passportFrontDoc'] is List
                  ? List<String>.from(json['passportFrontDoc'])
                  : [json['passportFrontDoc'] as String])
              : null),
      passportBackImages: json['passportBackImages'] != null
          ? List<String>.from(json['passportBackImages'])
          : (json['passportBackDoc'] != null
              ? (json['passportBackDoc'] is List
                  ? List<String>.from(json['passportBackDoc'])
                  : [json['passportBackDoc'] as String])
              : null),
      qatarIdImages: json['qatarIdImages'] != null
          ? List<String>.from(json['qatarIdImages'])
          : (json['qatarIdDoc'] != null
              ? (json['qatarIdDoc'] is List
                  ? List<String>.from(json['qatarIdDoc'])
                  : [json['qatarIdDoc'] as String])
              : null),
      rentAmount: (json['rentAmount'] is num
                  ? json['rentAmount']
                  : double.tryParse(json['rentAmount']?.toString() ?? '0'))
              ?.toDouble() ??
          0.0,
      securityDeposit: (json['securityDeposit'] is num
                  ? json['securityDeposit']
                  : double.tryParse(json['securityDeposit']?.toString() ?? '0'))
              ?.toDouble() ??
          0.0,
      securityDepositPaymentId: json['securityDepositPaymentId'],
      contractStartDate: json['contractStartDate'] != null
          ? DateTime.tryParse(json['contractStartDate']) ?? DateTime.now()
          : DateTime.now(),
      contractEndDate: json['contractEndDate'] != null
          ? DateTime.tryParse(json['contractEndDate'])
          : null,
      status: json['status'] ?? 'active',
      assignedPropertyId: json['assignedPropertyId'] ?? json['propertyId'],
      property: json['property'] != null
          ? PropertyModel.fromJson(json['property'])
          : null,
      assignedRoomId: json['assignedRoomId'],
      assignedRoom: json['assignedRoom'] != null
          ? RoomModel.fromJson(json['assignedRoom'])
          : null,
      financials: json['financials'] != null
          ? Financials.fromJson(json['financials'])
          : null,
      lastPaymentDate: json['lastPaymentDate'] != null
          ? DateTime.tryParse(json['lastPaymentDate'])
          : null,
      leaseList: json['leases'] != null
          ? (json['leases'] as List).map((l) => LeaseModel.fromJson(l)).toList()
          : null,
      amenities: json['amenities'] != null
          ? (json['amenities'] as List)
              .map((a) => TenantAmenityModel.fromJson(a))
              .toList()
          : null,
      createdById: json['createdById'],
      createdByName: json['createdBy']?['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'qatarId': qatarId,
      'passportFrontImages': passportFrontImages,
      'passportBackImages': passportBackImages,
      'qatarIdImages': qatarIdImages,
      'rentAmount': rentAmount,
      'securityDeposit': securityDeposit,
      'securityDepositPaymentId': securityDepositPaymentId,
      'contractStartDate': contractStartDate.toIso8601String(),
      'contractEndDate': contractEndDate?.toIso8601String(),
      'status': status,
      'assignedPropertyId': assignedPropertyId,
      'propertyId': assignedPropertyId,
      'property': property?.toJson(),
      'assignedRoomId': assignedRoomId,
      'assignedRoom': assignedRoom?.toJson(),
      'financials': financials?.toJson(),
      'leases': leaseList?.map((l) => l.toJson()).toList(),
      'amenities': amenities?.map((a) => a.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        qatarId,
        passportFrontImages,
        passportBackImages,
        qatarIdImages,
        rentAmount,
        securityDeposit,
        securityDepositPaymentId,
        contractStartDate,
        contractEndDate,
        status,
        assignedPropertyId,
        property,
        assignedRoomId,
        assignedRoom,
        financials,
        lastPaymentDate,
        leaseList,
        amenities,
        createdById,
        createdByName,
      ];
}

class Financials extends Equatable {
  final double totalAmount;
  final double totalPaid;
  final double totalPending;

  const Financials({
    required this.totalAmount,
    required this.totalPaid,
    required this.totalPending,
  });

  factory Financials.fromJson(Map<String, dynamic> json) {
    return Financials(
      totalAmount: (json['totalAmount'] as num).toDouble(),
      totalPaid: (json['totalPaid'] as num).toDouble(),
      totalPending: (json['totalPending'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalAmount': totalAmount,
      'totalPaid': totalPaid,
      'totalPending': totalPending,
    };
  }

  @override
  List<Object?> get props => [totalAmount, totalPaid, totalPending];
}
