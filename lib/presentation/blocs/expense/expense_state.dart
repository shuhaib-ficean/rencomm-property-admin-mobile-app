import 'package:equatable/equatable.dart';
import '../../../core/models/expense_model.dart';

abstract class ExpenseState extends Equatable {
  const ExpenseState();
  
  @override
  List<Object?> get props => [];
}

class ExpenseInitial extends ExpenseState {}

class ExpenseLoading extends ExpenseState {}

class ExpenseLoaded extends ExpenseState {
  final List<ExpenseModel> expenses;
  final String? operationSuccess;
  final String? operationError;

  const ExpenseLoaded({
    required this.expenses,
    this.operationSuccess,
    this.operationError,
  });

  @override
  List<Object?> get props => [expenses, operationSuccess, operationError];
}

class ExpenseError extends ExpenseState {
  final String message;

  const ExpenseError(this.message);

  @override
  List<Object?> get props => [message];
}
