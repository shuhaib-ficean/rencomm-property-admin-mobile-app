import 'package:equatable/equatable.dart';

class PropertyModel extends Equatable {
  final String id;
  final String name;
  final String type; // Flat / Villa
  final String? description;
  final String? address;
  final String? lat;
  final String? long;
  final String? country;
  final String? state;
  final String? city;
  final String? pincode;
  final String? currency;
  final List<String> images;
  final List<String> amenities;
  final String status; // Active / Inactive
  final String createdAt;
  final String updatedAt;
  final String? createdByName;
  final String? createdById;
  final String? managerName;
  final String? managerPhone;
  final String? managerEmail;
  final List<FloorModel> floors;
  final List<RoomModel> rooms;
  final List<ExpenseModel> propertyExpenses;
  final List<EnquiryModel> enquiries;

  const PropertyModel({
    required this.id,
    required this.name,
    required this.type,
    this.description,
    this.address,
    this.lat,
    this.long,
    this.country,
    this.state,
    this.city,
    this.pincode,
    this.currency,
    this.images = const [],
    this.amenities = const [],
    this.status = 'Active',
    required this.createdAt,
    required this.updatedAt,
    this.managerName,
    this.managerPhone,
    this.managerEmail,
    this.createdByName,
    this.createdById,
    this.floors = const [],
    this.rooms = const [],
    this.propertyExpenses = const [],
    this.enquiries = const [],
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      description: json['description'],
      address: json['address'],
      lat: json['lat'],
      long: json['long'],
      country: json['country'],
      state: json['state'],
      city: json['city'],
      pincode: json['pincode'],
      currency: json['currency'],
      images: (json['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      amenities: (json['amenities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      status: json['status'] ?? 'Active',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      createdByName: json['createdBy']?['name'],
      createdById: json['createdById'],
      managerName: json['managerName'],
      managerPhone: json['managerPhone'],
      managerEmail: json['managerEmail'],
      floors: (json['floors'] as List<dynamic>?)?.map((e) => FloorModel.fromJson(e)).toList() ?? [],
      rooms: (json['rooms'] as List<dynamic>?)?.map((e) => RoomModel.fromJson(e)).toList() ?? [],
      propertyExpenses: (json['propertyExpenses'] as List<dynamic>?)?.map((e) => ExpenseModel.fromJson(e)).toList() ?? [],
      enquiries: (json['enquiries'] as List<dynamic>?)?.map((e) => EnquiryModel.fromJson(e)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'description': description,
      'address': address,
      'lat': lat,
      'long': long,
      'country': country,
      'state': state,
      'city': city,
      'pincode': pincode,
      'currency': currency,
      'images': images,
      'amenities': amenities,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'managerName': managerName,
      'managerPhone': managerPhone,
      'managerEmail': managerEmail,
      'floors': floors.map((e) => e.toJson()).toList(),
      'rooms': rooms.map((e) => e.toJson()).toList(),
      'propertyExpenses': propertyExpenses.map((e) => e.toJson()).toList(),
      'enquiries': enquiries.map((e) => e.toJson()).toList(),
    };
  }

  bool get hasActiveTenants {
    for (final floor in floors) {
      for (final room in floor.rooms) {
        if (room.activeTenantsCount > 0 || room.status.toLowerCase() == 'occupied') {
          return true;
        }
      }
    }
    for (final room in rooms) {
      if (room.activeTenantsCount > 0 || room.status.toLowerCase() == 'occupied') {
        return true;
      }
    }
    return false;
  }

  int get totalRoomsCount {
    int count = rooms.length;
    for (final f in floors) {
      count += f.rooms.length;
    }
    return count;
  }

  int get occupiedRoomsCount {
    int count = 0;
    for (final r in rooms) {
      if (r.activeTenantsCount > 0 || r.status.toLowerCase() == 'occupied') {
        count++;
      }
    }
    for (final f in floors) {
      for (final r in f.rooms) {
        if (r.activeTenantsCount > 0 || r.status.toLowerCase() == 'occupied') {
          count++;
        }
      }
    }
    return count;
  }

  int get vacantRoomsCount {
    return (totalRoomsCount - occupiedRoomsCount).clamp(0, totalRoomsCount);
  }

  bool get hasVacantRooms {
    if (totalRoomsCount == 0) return true;
    return vacantRoomsCount > 0;
  }

  @override
  List<Object?> get props => [
        id, name, type, description, address, lat, long, country, state, city, pincode,
        currency, images, amenities, status, createdAt, updatedAt, managerName, managerPhone, managerEmail, createdByName, createdById,
        floors, rooms, propertyExpenses, enquiries
      ];
}

class FloorModel extends Equatable {
  final String id;
  final String number;
  final String propertyId;
  final List<RoomModel> rooms;

  const FloorModel({
    required this.id,
    required this.number,
    required this.propertyId,
    this.rooms = const [],
  });

  factory FloorModel.fromJson(Map<String, dynamic> json) {
    return FloorModel(
      id: json['id'] ?? '',
      number: json['number'] ?? '',
      propertyId: json['propertyId'] ?? '',
      rooms: (json['rooms'] as List<dynamic>?)?.map((e) => RoomModel.fromJson(e)).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'propertyId': propertyId,
      'rooms': rooms.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [id, number, propertyId, rooms];
}

class RoomModel extends Equatable {
  final String id;
  final String number;
  final String type; // e.g. Luxury suit, Royal suit, Balcony view
  final String? floorId;
  final String? floorName;
  final String propertyId;
  final String status;
  final double? defaultRent;
  final double? defaultDeposit;
  final List<String> amenities;
  final List<RoomTenantModel> tenants;
  final List<ExpenseModel> roomExpenses;
  final int activeTenantsCount;

  const RoomModel({
    required this.id,
    required this.number,
    required this.type,
    this.floorId,
    this.floorName,
    required this.propertyId,
    this.status = 'Available',
    this.defaultRent,
    this.defaultDeposit,
    this.amenities = const [],
    this.tenants = const [],
    this.roomExpenses = const [],
    this.activeTenantsCount = 0,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    final rawTenants = (json['tenants'] as List<dynamic>?)
            ?.map((e) => RoomTenantModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return RoomModel(
      id: json['id'] ?? '',
      number: json['number'] ?? '',
      type: json['type'] ?? '',
      floorId: json['floorId'],
      floorName: json['floorName'],
      propertyId: json['propertyId'] ?? '',
      status: json['status'] ?? 'Available',
      defaultRent: json['defaultRent'] != null ? (json['defaultRent'] as num).toDouble() : null,
      defaultDeposit: json['defaultDeposit'] != null ? (json['defaultDeposit'] as num).toDouble() : null,
      amenities: (json['amenities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      tenants: rawTenants,
      roomExpenses: (json['roomExpenses'] as List<dynamic>?)?.map((e) => ExpenseModel.fromJson(e)).toList() ?? [],
      activeTenantsCount: rawTenants.isNotEmpty ? rawTenants.length : (json['activeTenantsCount'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'type': type,
      'floorId': floorId,
      'floorName': floorName,
      'propertyId': propertyId,
      'status': status,
      'defaultRent': defaultRent,
      'defaultDeposit': defaultDeposit,
      'amenities': amenities,
      'tenants': tenants.map((e) => e.toJson()).toList(),
      'roomExpenses': roomExpenses.map((e) => e.toJson()).toList(),
      'activeTenantsCount': activeTenantsCount,
    };
  }

  @override
  List<Object?> get props => [
        id, number, type, floorId, floorName, propertyId, status,
        defaultRent, defaultDeposit, amenities, tenants, roomExpenses, activeTenantsCount,
      ];
}

class RoomTenantModel extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String phone;
  final String? qatarId;
  final double? rentAmount;
  final double? securityDeposit;
  final String status;
  final String? contractStartDate;
  final String? contractEndDate;

  const RoomTenantModel({
    required this.id,
    required this.name,
    this.email,
    required this.phone,
    this.qatarId,
    this.rentAmount,
    this.securityDeposit,
    this.status = 'active',
    this.contractStartDate,
    this.contractEndDate,
  });

  factory RoomTenantModel.fromJson(Map<String, dynamic> json) {
    return RoomTenantModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString() ?? '',
      qatarId: json['qatarId']?.toString(),
      rentAmount: json['rentAmount'] != null ? (json['rentAmount'] as num).toDouble() : null,
      securityDeposit: json['securityDeposit'] != null ? (json['securityDeposit'] as num).toDouble() : null,
      status: json['status']?.toString() ?? 'active',
      contractStartDate: json['contractStartDate']?.toString(),
      contractEndDate: json['contractEndDate']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'qatarId': qatarId,
      'rentAmount': rentAmount,
      'securityDeposit': securityDeposit,
      'status': status,
      'contractStartDate': contractStartDate,
      'contractEndDate': contractEndDate,
    };
  }

  @override
  List<Object?> get props => [
        id, name, email, phone, qatarId, rentAmount, securityDeposit, status,
        contractStartDate, contractEndDate,
      ];
}

class ExpenseModel extends Equatable {
  final String id;
  final String name;
  final double amount;
  final String? type; // 'room' or 'property'

  const ExpenseModel({
    required this.id,
    required this.name,
    required this.amount,
    this.type,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'type': type,
    };
  }

  @override
  List<Object?> get props => [id, name, amount, type];
}

class EnquiryModel extends Equatable {
  final String id;
  final String date;
  final String name;
  final String phone;
  final String type;
  final String? details;
  final String status;

  const EnquiryModel({
    required this.id,
    required this.date,
    required this.name,
    required this.phone,
    required this.type,
    this.details,
    required this.status,
  });

  factory EnquiryModel.fromJson(Map<String, dynamic> json) {
    return EnquiryModel(
      id: json['id'] ?? '',
      date: json['date'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      type: json['type'] ?? '',
      details: json['details'],
      status: json['status'] ?? 'Pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'name': name,
      'phone': phone,
      'type': type,
      'details': details,
      'status': status,
    };
  }

  EnquiryModel copyWith({
    String? id,
    String? date,
    String? name,
    String? phone,
    String? type,
    String? details,
    String? status,
  }) {
    return EnquiryModel(
      id: id ?? this.id,
      date: date ?? this.date,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      details: details ?? this.details,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [id, date, name, phone, type, details, status];
}
