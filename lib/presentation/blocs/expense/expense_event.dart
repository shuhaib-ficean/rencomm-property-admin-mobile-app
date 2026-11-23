import 'package:equatable/equatable.dart';
import '../../../core/models/expense_model.dart';

abstract class ExpenseEvent extends Equatable {
  const ExpenseEvent();

  @override
  List<Object?> get props => [];
}

class LoadExpenses extends ExpenseEvent {
  final bool isRefresh;
  const LoadExpenses({this.isRefresh = false});
  @override
  List<Object?> get props => [isRefresh];
}

class CreateExpense extends ExpenseEvent {
  final String title;
  final String category;
  final double amount;
  final String date;
  final String? propertyId;
  final dynamic receipt; // File?

  const CreateExpense({
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    this.propertyId,
    this.receipt,
  });

  @override
  List<Object?> get props => [title, category, amount, date, propertyId, receipt];
}

class UpdateExpense extends ExpenseEvent {
  final String id;
  final String? title;
  final String? category;
  final double? amount;
  final String? date;
  final String? propertyId;
  final dynamic receipt; // File?

  const UpdateExpense({
    required this.id,
    this.title,
    this.category,
    this.amount,
    this.date,
    this.propertyId,
    this.receipt,
  });

  @override
  List<Object?> get props => [id, title, category, amount, date, propertyId, receipt];
}

class DeleteExpense extends ExpenseEvent {
  final String id;
  const DeleteExpense(this.id);
  @override
  List<Object?> get props => [id];
}
