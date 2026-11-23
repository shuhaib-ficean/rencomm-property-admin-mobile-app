import 'package:equatable/equatable.dart';

class AmenityModel extends Equatable {
  final String id;
  final String name;
  final String category;
  final int repairsRequested;
  final int repairsCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AmenityModel({
    required this.id,
    required this.name,
    required this.category,
    required this.repairsRequested,
    required this.repairsCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AmenityModel.fromJson(Map<String, dynamic> json) {
    return AmenityModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      category: json['category'] ?? 'Other',
      repairsRequested: json['repairsRequested'] ?? 0,
      repairsCompleted: json['repairsCompleted'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'repairsRequested': repairsRequested,
      'repairsCompleted': repairsCompleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        repairsRequested,
        repairsCompleted,
        createdAt,
        updatedAt,
      ];
}
