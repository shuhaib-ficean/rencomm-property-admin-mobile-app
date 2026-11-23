import 'package:equatable/equatable.dart';

abstract class LeaseState extends Equatable {
  const LeaseState();

  @override
  List<Object?> get props => [];
}

class LeaseInitial extends LeaseState {}

class LeaseLoading extends LeaseState {}

class LeaseSuccess extends LeaseState {
  final String message;
  const LeaseSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class LeaseError extends LeaseState {
  final String message;
  const LeaseError(this.message);

  @override
  List<Object?> get props => [message];
}
