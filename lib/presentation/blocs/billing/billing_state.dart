import 'package:equatable/equatable.dart';
import '../../../core/models/app_subscription_model.dart';

abstract class BillingState extends Equatable {
  const BillingState();

  @override
  List<Object?> get props => [];
}

class BillingInitial extends BillingState {}

class BillingLoading extends BillingState {}

class BillingLoaded extends BillingState {
  final AppSubscriptionModel? subscription;
  final List<SubscriptionPaymentModel> payments;

  const BillingLoaded({
    this.subscription,
    required this.payments,
  });

  @override
  List<Object?> get props => [subscription, payments];
}

class BillingError extends BillingState {
  final String message;

  const BillingError(this.message);

  @override
  List<Object?> get props => [message];
}
