import 'package:equatable/equatable.dart';

abstract class TenantEvent extends Equatable {
  const TenantEvent();

  @override
  List<Object?> get props => [];
}

class TenantLoadRequested extends TenantEvent {
  const TenantLoadRequested();
}

class TenantRefreshRequested extends TenantEvent {
  const TenantRefreshRequested();
}

class TenantCreateRequested extends TenantEvent {
  final Map<String, dynamic> tenantData;

  const TenantCreateRequested(this.tenantData);

  @override
  List<Object?> get props => [tenantData];
}

class TenantUpdateRequested extends TenantEvent {
  final String id;
  final Map<String, dynamic> tenantData;

  const TenantUpdateRequested({
    required this.id,
    required this.tenantData,
  });

  @override
  List<Object?> get props => [id, tenantData];
}

class TenantDeleteRequested extends TenantEvent {
  final String id;

  const TenantDeleteRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class TenantAssignPropertyRequested extends TenantEvent {
  final String tenantId;
  final String propertyId;

  const TenantAssignPropertyRequested({
    required this.tenantId,
    required this.propertyId,
  });

  @override
  List<Object?> get props => [tenantId, propertyId];
}

class AddTenantPayment extends TenantEvent {
  final String tenantId;
  final double amount;
  final DateTime paymentDate;
  final String? notes;

  const AddTenantPayment({
    required this.tenantId,
    required this.amount,
    required this.paymentDate,
    this.notes,
  });

  @override
  List<Object?> get props => [tenantId, amount, paymentDate, notes];
}

class LoadTenantPayments extends TenantEvent {
  final String tenantId;
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadTenantPayments({
    required this.tenantId,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [tenantId, startDate, endDate];
}
