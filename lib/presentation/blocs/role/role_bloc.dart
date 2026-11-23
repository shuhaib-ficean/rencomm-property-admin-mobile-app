import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/models/role_model.dart';
import '../../../data/repositories/role_repository.dart';

// Events
abstract class RoleEvent extends Equatable {
  const RoleEvent();
  @override
  List<Object> get props => [];
}

class LoadRoles extends RoleEvent {
  const LoadRoles();
}

class CreateRole extends RoleEvent {
  final Map<String, dynamic> roleData;
  const CreateRole(this.roleData);
  @override
  List<Object> get props => [roleData];
}

class UpdateRole extends RoleEvent {
  final String id;
  final Map<String, dynamic> roleData;
  const UpdateRole(this.id, this.roleData);
  @override
  List<Object> get props => [id, roleData];
}

class DeleteRole extends RoleEvent {
  final String id;
  const DeleteRole(this.id);
  @override
  List<Object> get props => [id];
}

// States
abstract class RoleState extends Equatable {
  const RoleState();
  @override
  List<Object> get props => [];
}

class RoleInitial extends RoleState {}

class RoleLoading extends RoleState {}

class RoleLoaded extends RoleState {
  final List<RoleModel> roles;
  const RoleLoaded(this.roles);
  @override
  List<Object> get props => [roles];
}

class RoleOperationSuccess extends RoleState {
  final String message;
  const RoleOperationSuccess(this.message);
  @override
  List<Object> get props => [message];
}

class RoleError extends RoleState {
  final String message;
  const RoleError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class RoleBloc extends Bloc<RoleEvent, RoleState> {
  final RoleRepository _roleRepository;

  RoleBloc(this._roleRepository) : super(RoleInitial()) {
    on<LoadRoles>(_onLoadRoles);
    on<CreateRole>(_onCreateRole);
    on<UpdateRole>(_onUpdateRole);
    on<DeleteRole>(_onDeleteRole);
  }

  Future<void> _onLoadRoles(LoadRoles event, Emitter<RoleState> emit) async {
    emit(RoleLoading());
    try {
      final roles = await _roleRepository.getRoles();
      emit(RoleLoaded(roles));
    } catch (e) {
      emit(RoleError(e.toString()));
    }
  }

  Future<void> _onCreateRole(CreateRole event, Emitter<RoleState> emit) async {
    emit(RoleLoading());
    try {
      await _roleRepository.createRole(event.roleData);
      emit(const RoleOperationSuccess('Role created successfully'));
      add(const LoadRoles());
    } catch (e) {
      emit(RoleError(e.toString()));
      add(const LoadRoles());
    }
  }

  Future<void> _onUpdateRole(UpdateRole event, Emitter<RoleState> emit) async {
    emit(RoleLoading());
    try {
      await _roleRepository.updateRole(event.id, event.roleData);
      emit(const RoleOperationSuccess('Role updated successfully'));
      add(const LoadRoles());
    } catch (e) {
      emit(RoleError(e.toString()));
      add(const LoadRoles());
    }
  }

  Future<void> _onDeleteRole(DeleteRole event, Emitter<RoleState> emit) async {
    emit(RoleLoading());
    try {
      await _roleRepository.deleteRole(event.id);
      emit(const RoleOperationSuccess('Role deleted successfully'));
      add(const LoadRoles());
    } catch (e) {
      emit(RoleError(e.toString()));
      add(const LoadRoles());
    }
  }
}
