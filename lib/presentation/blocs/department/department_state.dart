import 'package:equatable/equatable.dart';
import '../../../../core/models/department_model.dart';

abstract class DepartmentState extends Equatable {
  const DepartmentState();
  
  @override
  List<Object?> get props => [];
}

class DepartmentInitial extends DepartmentState {}

class DepartmentLoading extends DepartmentState {}

class DepartmentLoaded extends DepartmentState {
  final List<DepartmentModel> departments;
  final String? operationSuccess;
  final String? operationError;

  const DepartmentLoaded(this.departments, {this.operationSuccess, this.operationError});

  @override
  List<Object?> get props => [departments, operationSuccess, operationError];
}

class DepartmentError extends DepartmentState {
  final String message;

  const DepartmentError(this.message);

  @override
  List<Object?> get props => [message];
}
