import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String role;
  final List<String> permissions;
  final String? employeeId;
  final String? department;
  final bool isActive;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.permissions,
    this.employeeId,
    this.department,
    this.isActive = true,
  });

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
      ];
}
