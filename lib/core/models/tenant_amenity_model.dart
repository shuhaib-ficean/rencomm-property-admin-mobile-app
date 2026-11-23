import 'package:equatable/equatable.dart';

class TenantAmenityModel extends Equatable {
  final String id;
  final String description;
  final String providedAt;
  final String tenantId;
  final String createdAt;
  final String updatedAt;

  const TenantAmenityModel({
    required this.id,
    required this.description,
    required this.providedAt,
    required this.tenantId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TenantAmenityModel.fromJson(Map<String, dynamic> json) {
    return TenantAmenityModel(
      id: json['id'] ?? '',
      description: json['description'] ?? '',
      providedAt: json['providedAt'] ?? '',
      tenantId: json['tenantId'] ?? '',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'providedAt': providedAt,
      'tenantId': tenantId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  List<Object?> get props => [
        id,
        description,
        providedAt,
        tenantId,
        createdAt,
        updatedAt,
      ];
}
