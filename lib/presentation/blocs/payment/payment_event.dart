import 'package:equatable/equatable.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class PaymentLoadRequested extends PaymentEvent {
  const PaymentLoadRequested();
}

class PaymentRefreshRequested extends PaymentEvent {
  const PaymentRefreshRequested();
}

class PaymentCreateRequested extends PaymentEvent {
  final Map<String, dynamic> paymentData;

  const PaymentCreateRequested(this.paymentData);

  @override
  List<Object?> get props => [paymentData];
}

class PaymentLoadByTenantRequested extends PaymentEvent {
  final String tenantId;

  const PaymentLoadByTenantRequested(this.tenantId);

  @override
  List<Object?> get props => [tenantId];
}

class PaymentAnalyticsRequested extends PaymentEvent {
  const PaymentAnalyticsRequested();
}

