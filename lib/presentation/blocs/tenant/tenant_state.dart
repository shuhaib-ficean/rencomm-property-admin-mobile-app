import 'package:equatable/equatable.dart';

abstract class TenantState extends Equatable {
  const TenantState();

  @override
  List<Object?> get props => [];
}

class TenantInitial extends TenantState {
  const TenantInitial();
}

class TenantLoading extends TenantState {
  const TenantLoading();
}

class TenantLoaded extends TenantState {
  final List<dynamic> tenants;

  const TenantLoaded(this.tenants);

  @override
  List<Object?> get props => [tenants];
}

class TenantError extends TenantState {
  final String message;

  const TenantError(this.message);

  @override
  List<Object?> get props => [message];
}

class TenantSuccess extends TenantState {
  final String message;

  const TenantSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

