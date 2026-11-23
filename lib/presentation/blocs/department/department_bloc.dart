import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/department_service.dart';
import '../../../../core/utils/storage_helper.dart';
import 'department_event.dart';
import 'department_state.dart';

class DepartmentBloc extends Bloc<DepartmentEvent, DepartmentState> {
  final DepartmentService departmentService;

  DepartmentBloc({required this.departmentService}) : super(DepartmentInitial()) {
    on<LoadDepartments>(_onLoadDepartments);
    on<CreateDepartment>(_onCreateDepartment);
    on<UpdateDepartment>(_onUpdateDepartment);
    on<DeleteDepartment>(_onDeleteDepartment);
  }

  Future<void> _onLoadDepartments(LoadDepartments event, Emitter<DepartmentState> emit) async {
    emit(DepartmentLoading());
    try {
      final token = await StorageHelper.getToken();
      if (token == null) throw Exception('Not authenticated');

      final departments = await departmentService.getDepartments(token);
      emit(DepartmentLoaded(departments));
    } catch (e) {
      emit(DepartmentError(e.toString()));
    }
  }

  Future<void> _onCreateDepartment(CreateDepartment event, Emitter<DepartmentState> emit) async {
    try {
      final token = await StorageHelper.getToken();
      if (token == null) throw Exception('Not authenticated');

      await departmentService.createDepartment(token, event.data);
      
      final departments = await departmentService.getDepartments(token);
      emit(DepartmentLoaded(departments, operationSuccess: 'Department created successfully'));
    } catch (e) {
      if (state is DepartmentLoaded) {
        emit(DepartmentLoaded((state as DepartmentLoaded).departments, operationError: e.toString()));
      } else {
        emit(DepartmentError(e.toString()));
      }
    }
  }

  Future<void> _onUpdateDepartment(UpdateDepartment event, Emitter<DepartmentState> emit) async {
    try {
      final token = await StorageHelper.getToken();
      if (token == null) throw Exception('Not authenticated');

      await departmentService.updateDepartment(token, event.id, event.data);
      
      final departments = await departmentService.getDepartments(token);
      emit(DepartmentLoaded(departments, operationSuccess: 'Department updated successfully'));
    } catch (e) {
      if (state is DepartmentLoaded) {
        emit(DepartmentLoaded((state as DepartmentLoaded).departments, operationError: e.toString()));
      } else {
        emit(DepartmentError(e.toString()));
      }
    }
  }

  Future<void> _onDeleteDepartment(DeleteDepartment event, Emitter<DepartmentState> emit) async {
    try {
      final token = await StorageHelper.getToken();
      if (token == null) throw Exception('Not authenticated');

      await departmentService.deleteDepartment(token, event.id);
      
      final departments = await departmentService.getDepartments(token);
      emit(DepartmentLoaded(departments, operationSuccess: 'Department deleted successfully'));
    } catch (e) {
      if (state is DepartmentLoaded) {
        emit(DepartmentLoaded((state as DepartmentLoaded).departments, operationError: e.toString()));
      } else {
        emit(DepartmentError(e.toString()));
      }
    }
  }
}
