import 'package:flutter_bloc/flutter_bloc.dart';
import 'lease_event.dart';
import 'lease_state.dart';
import '../../../data/repositories/lease_repository.dart';

class LeaseBloc extends Bloc<LeaseEvent, LeaseState> {
  final LeaseRepository _repository;

  LeaseBloc({required LeaseRepository repository})
      : _repository = repository,
        super(LeaseInitial()) {
    on<CreateLease>(_onCreateLease);
  }

  Future<void> _onCreateLease(
      CreateLease event, Emitter<LeaseState> emit) async {
    emit(LeaseLoading());
    try {
      await _repository.createLease(
        tenantId: event.tenantId,
        roomId: event.roomId,
        rentAmount: event.rentAmount,
        securityDeposit: event.securityDeposit,
        startDate: event.startDate,
        isRecurring: event.isRecurring,
        durationDays: event.durationDays,
      );
      emit(const LeaseSuccess('Lease created successfully'));
    } catch (e) {
      emit(LeaseError(e.toString()));
    }
  }
}
