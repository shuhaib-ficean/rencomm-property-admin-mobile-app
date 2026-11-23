import 'package:equatable/equatable.dart';

class PropertyAnalyticsModel extends Equatable {
  final String id;
  final String name;
  final double revenue;
  final double occupancyRate;
  final int totalUnits;
  final int occupiedUnits;

  const PropertyAnalyticsModel({
    required this.id,
    required this.name,
    required this.revenue,
    required this.occupancyRate,
    required this.totalUnits,
    required this.occupiedUnits,
  });

  factory PropertyAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return PropertyAnalyticsModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      revenue: double.tryParse(json['revenue']?.toString() ?? '0') ?? 0.0,
      occupancyRate:
          double.tryParse(json['occupancyRate']?.toString() ?? '0') ?? 0.0,
      totalUnits: int.tryParse(json['totalUnits']?.toString() ?? '0') ?? 0,
      occupiedUnits:
          int.tryParse(json['occupiedUnits']?.toString() ?? '0') ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        revenue,
        occupancyRate,
        totalUnits,
        occupiedUnits,
      ];
}
