import 'package:flutter_bloc/flutter_bloc.dart';
import 'expense_event.dart';
import 'expense_state.dart';
import '../../../data/repositories/expense_repository.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final ExpenseRepository _repository;

  ExpenseBloc({required ExpenseRepository repository})
      : _repository = repository,
        super(ExpenseInitial()) {
    on<LoadExpenses>(_onLoadExpenses);
    on<CreateExpense>(_onCreateExpense);
    on<UpdateExpense>(_onUpdateExpense);
    on<DeleteExpense>(_onDeleteExpense);
  }

  Future<void> _onLoadExpenses(
      LoadExpenses event, Emitter<ExpenseState> emit) async {
    if (!event.isRefresh) {
      emit(ExpenseLoading());
    }

    try {
      final expenses = await _repository.getExpenses();
      emit(ExpenseLoaded(expenses: expenses));
    } catch (e) {
      emit(ExpenseError(e.toString()));
    }
  }

  Future<void> _onCreateExpense(
      CreateExpense event, Emitter<ExpenseState> emit) async {
    final currentState = state;
    List<dynamic> currentExpenses = [];
    if (currentState is ExpenseLoaded) {
      currentExpenses = currentState.expenses;
    }

    try {
      await _repository.createExpense(
        title: event.title,
        category: event.category,
        amount: event.amount,
        date: event.date,
        propertyId: event.propertyId,
        receipt: event.receipt,
      );
      
      final expenses = await _repository.getExpenses();
      emit(ExpenseLoaded(
        expenses: expenses,
        operationSuccess: 'Expense created successfully',
      ));
    } catch (e) {
      if (currentState is ExpenseLoaded) {
        emit(ExpenseLoaded(
          expenses: currentState.expenses,
          operationError: 'Failed to create expense: $e',
        ));
      } else {
        emit(ExpenseError(e.toString()));
      }
    }
  }

  Future<void> _onUpdateExpense(
      UpdateExpense event, Emitter<ExpenseState> emit) async {
    final currentState = state;
    
    try {
      await _repository.updateExpense(
        id: event.id,
        title: event.title,
        category: event.category,
        amount: event.amount,
        date: event.date,
        propertyId: event.propertyId,
        receipt: event.receipt,
      );
      
      final expenses = await _repository.getExpenses();
      emit(ExpenseLoaded(
        expenses: expenses,
        operationSuccess: 'Expense updated successfully',
      ));
    } catch (e) {
      if (currentState is ExpenseLoaded) {
        emit(ExpenseLoaded(
          expenses: currentState.expenses,
          operationError: 'Failed to update expense: $e',
        ));
      } else {
        emit(ExpenseError(e.toString()));
      }
    }
  }

  Future<void> _onDeleteExpense(
      DeleteExpense event, Emitter<ExpenseState> emit) async {
    final currentState = state;
    
    try {
      await _repository.deleteExpense(event.id);
      
      final expenses = await _repository.getExpenses();
      emit(ExpenseLoaded(
        expenses: expenses,
        operationSuccess: 'Expense deleted successfully',
      ));
    } catch (e) {
      if (currentState is ExpenseLoaded) {
        emit(ExpenseLoaded(
          expenses: currentState.expenses,
          operationError: 'Failed to delete expense: $e',
        ));
      } else {
        emit(ExpenseError(e.toString()));
      }
    }
  }
}
