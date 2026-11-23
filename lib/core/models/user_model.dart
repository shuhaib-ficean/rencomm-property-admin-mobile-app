import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final List<String> permissions;
  final String? employeeId;
  final String? department;
  final bool isActive;
  final String phone;
  final String? roleId;
  final String? roleName;
  final String? password;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.permissions,
    this.employeeId,
    this.department,
    this.isActive = true,
    required this.phone,
    this.roleId,
    this.roleName,
    this.password,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      permissions: List<String>.from(json['permissions'] ?? []),
      employeeId: json['employeeId']?.toString(),
      department: json['department'],
      isActive: json['isActive'] ?? true,
      phone: json['phone']?.toString() ?? '',
      roleId: json['appRoleId']?.toString() ?? json['roleId']?.toString(),
      roleName: json['roleName'],
      password: json['password'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'permissions': permissions,
      'employeeId': employeeId,
      'department': department,
      'isActive': isActive,
      'phone': phone,
      'roleId': roleId,
      'roleName': roleName,
      'password': password,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        role,
        permissions,
        employeeId,
        department,
        isActive,
        phone,
        roleId,
        roleName,
      ];
}
