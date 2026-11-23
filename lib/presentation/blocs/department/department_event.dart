import 'package:equatable/equatable.dart';

abstract class DepartmentEvent extends Equatable {
  const DepartmentEvent();

  @override
  List<Object?> get props => [];
}

class LoadDepartments extends DepartmentEvent {}

class CreateDepartment extends DepartmentEvent {
  final Map<String, dynamic> data;

  const CreateDepartment(this.data);

  @override
  List<Object?> get props => [data];
}

class UpdateDepartment extends DepartmentEvent {
  final String id;
  final Map<String, dynamic> data;

  const UpdateDepartment(this.id, this.data);

  @override
  List<Object?> get props => [id, data];
}

class DeleteDepartment extends DepartmentEvent {
  final String id;

  const DeleteDepartment(this.id);

  @override
  List<Object?> get props => [id];
}
