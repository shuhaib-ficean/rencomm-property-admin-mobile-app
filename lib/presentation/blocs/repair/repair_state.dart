import 'package:equatable/equatable.dart';
import '../../../../core/models/repair_model.dart';

abstract class RepairState extends Equatable {
  const RepairState();

  @override
  List<Object?> get props => [];
}

class RepairInitial extends RepairState {}

class RepairLoading extends RepairState {}

class RepairLoaded extends RepairState {
  final List<RepairModel> repairs;
  final String? operationSuccess;
  final String? operationError;

  const RepairLoaded(this.repairs, {this.operationSuccess, this.operationError});

  @override
  List<Object?> get props => [repairs, operationSuccess, operationError];
}

class RepairError extends RepairState {
  final String message;

  const RepairError(this.message);

  @override
  List<Object?> get props => [message];
}
