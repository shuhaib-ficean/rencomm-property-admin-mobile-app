import 'package:flutter_bloc/flutter_bloc.dart';
import 'billing_event.dart';
import 'billing_state.dart';
import '../../../data/repositories/subscription_repository.dart';

class BillingBloc extends Bloc<BillingEvent, BillingState> {
  final SubscriptionRepository _repository;

  BillingBloc({required SubscriptionRepository repository})
      : _repository = repository,
        super(BillingInitial()) {
    on<LoadBillingInfo>(_onLoadBillingInfo);
  }

  Future<void> _onLoadBillingInfo(
      LoadBillingInfo event, Emitter<BillingState> emit) async {
    emit(BillingLoading());
    try {
      final subscription = await _repository.getMySubscription();
      final payments = await _repository.getMyPayments();
      emit(BillingLoaded(subscription: subscription, payments: payments));
    } catch (e) {
      emit(BillingError(e.toString()));
    }
  }
}
