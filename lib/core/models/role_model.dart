import 'package:equatable/equatable.dart';

class RoleModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final List<String> permissions;

  const RoleModel({
    required this.id,
    required this.name,
    this.description,
    required this.permissions,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      permissions: List<String>.from(json['permissions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'permissions': permissions,
    };
  }

  @override
  List<Object?> get props => [id, name, description, permissions];
}
