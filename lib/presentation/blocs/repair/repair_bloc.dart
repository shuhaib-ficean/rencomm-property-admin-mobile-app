import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../data/repositories/repair_repository.dart';
import 'repair_event.dart';
import 'repair_state.dart';

@injectable
class RepairBloc extends Bloc<RepairEvent, RepairState> {
  final RepairRepository _repository;

  RepairBloc(this._repository) : super(RepairInitial()) {
    on<LoadRepairs>(_onLoadRepairs);
    on<UpdateRepairStatus>(_onUpdateRepairStatus);
    on<CreateRepair>(_onCreateRepair);
    on<AssignRepairStaff>(_onAssignRepairStaff);
    on<ResolveRepairRequest>(_onResolveRepairRequest);
  }

  Future<void> _onLoadRepairs(LoadRepairs event, Emitter<RepairState> emit) async {
    emit(RepairLoading());
    try {
      final repairs = await _repository.getRepairs(status: event.status);
      emit(RepairLoaded(repairs));
    } catch (e) {
      emit(RepairError(e.toString()));
    }
  }

  Future<void> _onUpdateRepairStatus(UpdateRepairStatus event, Emitter<RepairState> emit) async {
    final currentState = state;
    try {
      await _repository.updateRepairStatus(event.id, event.status);
      
      // Reload repairs after update
      final repairs = await _repository.getRepairs();
      emit(RepairLoaded(repairs, operationSuccess: 'Repair status updated successfully'));
    } catch (e) {
      if (currentState is RepairLoaded) {
        emit(RepairLoaded(currentState.repairs, operationError: e.toString()));
      } else {
        emit(RepairError(e.toString()));
      }
    }
  }

  Future<void> _onResolveRepairRequest(ResolveRepairRequest event, Emitter<RepairState> emit) async {
    final currentState = state;
    try {
      await _repository.resolveRepairRequest(
        event.id,
        status: event.status,
        completionImages: event.completionImages,
        completionNotes: event.completionNotes,
      );
      
      final repairs = await _repository.getRepairs();
      emit(RepairLoaded(repairs, operationSuccess: 'Repair marked as resolved with proof'));
    } catch (e) {
      if (currentState is RepairLoaded) {
        emit(RepairLoaded(currentState.repairs, operationError: e.toString()));
      } else {
        emit(RepairError(e.toString()));
      }
    }
  }

  Future<void> _onCreateRepair(CreateRepair event, Emitter<RepairState> emit) async {
    final currentState = state;
    emit(RepairLoading());
    try {
      await _repository.createRepairRequest(event.data);
      final repairs = await _repository.getRepairs();
      emit(RepairLoaded(repairs, operationSuccess: 'Repair request created successfully'));
    } catch (e) {
      if (currentState is RepairLoaded) {
        emit(RepairLoaded(currentState.repairs, operationError: e.toString()));
      } else {
        emit(RepairError(e.toString()));
      }
    }
  }

  Future<void> _onAssignRepairStaff(AssignRepairStaff event, Emitter<RepairState> emit) async {
    final currentState = state;
    try {
      await _repository.assignStaff(event.id, event.staffId);
      
      final repairs = await _repository.getRepairs();
      emit(RepairLoaded(repairs, operationSuccess: 'Staff assigned successfully'));
    } catch (e) {
      if (currentState is RepairLoaded) {
        emit(RepairLoaded(currentState.repairs, operationError: e.toString()));
      } else {
        emit(RepairError(e.toString()));
      }
    }
  }
}
