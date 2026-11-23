import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/tenant_repository.dart';

// Events
abstract class TenantPaymentEvent extends Equatable {
  const TenantPaymentEvent();
  @override
  List<Object> get props => [];
}

class AddTenantPayment extends TenantPaymentEvent {
  final String tenantId;
  final double amount;
  final DateTime paymentDate;
  final String? notes;
  final String? leaseId;
  final String? paymentMethod;
  final String? transactionId;
  final bool isSecurityDeposit;

  const AddTenantPayment({
    required this.tenantId,
    required this.amount,
    required this.paymentDate,
    this.notes,
    this.leaseId,
    this.paymentMethod,
    this.transactionId,
    this.isSecurityDeposit = false,
  });

  @override
  List<Object> get props => [
        tenantId,
        amount,
        paymentDate,
        notes ?? '',
        leaseId ?? '',
        paymentMethod ?? '',
        transactionId ?? '',
        isSecurityDeposit,
      ];
}

class LoadTenantPayments extends TenantPaymentEvent {
  final String tenantId;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? leaseId;
  final bool isRefresh;
  final bool isLoadMore;
  final Completer<void>? completer;

  const LoadTenantPayments({
    required this.tenantId,
    this.startDate,
    this.endDate,
    this.leaseId,
    this.isRefresh = false,
    this.isLoadMore = false,
    this.completer,
  });

  @override
  List<Object> get props => [
        tenantId,
        startDate ?? '',
        endDate ?? '',
        leaseId ?? '',
        isRefresh,
        isLoadMore,
      ];
}

// States
abstract class TenantPaymentState extends Equatable {
  const TenantPaymentState();
  @override
  List<Object> get props => [];
}

class TenantPaymentInitial extends TenantPaymentState {}

class TenantPaymentLoading extends TenantPaymentState {}

class TenantPaymentsLoaded extends TenantPaymentState {
  final List<dynamic> payments;
  final double totalPaid;
  final double totalAmount;
  final double totalPending;
  final int currentPage;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final bool isRefreshing;

  const TenantPaymentsLoaded({
    required this.payments,
    required this.totalPaid,
    required this.totalAmount,
    required this.totalPending,
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
  });

  TenantPaymentsLoaded copyWith({
    List<dynamic>? payments,
    double? totalPaid,
    double? totalAmount,
    double? totalPending,
    int? currentPage,
    bool? hasReachedMax,
    bool? isLoadingMore,
    bool? isRefreshing,
  }) {
    return TenantPaymentsLoaded(
      payments: payments ?? this.payments,
      totalPaid: totalPaid ?? this.totalPaid,
      totalAmount: totalAmount ?? this.totalAmount,
      totalPending: totalPending ?? this.totalPending,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object> get props => [
        payments,
        totalPaid,
        totalAmount,
        totalPending,
        currentPage,
        hasReachedMax,
        isLoadingMore,
        isRefreshing,
      ];
}

class TenantPaymentOperationSuccess extends TenantPaymentState {
  final String message;
  const TenantPaymentOperationSuccess(this.message);
  @override
  List<Object> get props => [message];
}

class TenantPaymentError extends TenantPaymentState {
  final String message;
  const TenantPaymentError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class TenantPaymentBloc extends Bloc<TenantPaymentEvent, TenantPaymentState> {
  final TenantRepository _tenantRepository;

  TenantPaymentBloc(this._tenantRepository) : super(TenantPaymentInitial()) {
    on<LoadTenantPayments>(_onLoadTenantPayments);
    on<AddTenantPayment>(_onAddTenantPayment);
  }

  Future<void> _onLoadTenantPayments(
    LoadTenantPayments event,
    Emitter<TenantPaymentState> emit,
  ) async {
    final currentState = state;

    if (event.isRefresh && currentState is TenantPaymentsLoaded) {
      emit(currentState.copyWith(isRefreshing: true));
    } else if (currentState is! TenantPaymentsLoaded) {
      emit(TenantPaymentLoading());
    } else if (event.isLoadMore) {
      if (currentState.hasReachedMax || currentState.isLoadingMore) return;
      emit(currentState.copyWith(isLoadingMore: true));
    }

    try {
      final int pageToLoad = event.isRefresh
          ? 1
          : (event.isLoadMore && currentState is TenantPaymentsLoaded)
              ? currentState.currentPage + 1
              : 1;

      final result = await _tenantRepository.getTenantPayments(
        tenantId: event.tenantId,
        startDate: event.startDate,
        endDate: event.endDate,
        leaseId: event.leaseId,
        page: pageToLoad,
      );

      final List<dynamic> newPayments = result['payments'];
      final bool hasReachedMax = result['currentPage'] >= result['totalPages'];

      if (event.isLoadMore && currentState is TenantPaymentsLoaded) {
        emit(
          TenantPaymentsLoaded(
            payments: List.of(currentState.payments)..addAll(newPayments),
            totalPaid: (result['totalPaid'] as num? ?? 0).toDouble(),
            totalAmount: (result['totalAmount'] as num? ?? 0).toDouble(),
            totalPending: (result['totalPending'] as num? ?? 0).toDouble(),
            currentPage: result['currentPage'] as int,
            hasReachedMax: hasReachedMax,
          ),
        );
      } else {
        emit(
          TenantPaymentsLoaded(
            payments: newPayments,
            totalPaid: (result['totalPaid'] as num? ?? 0).toDouble(),
            totalAmount: (result['totalAmount'] as num? ?? 0).toDouble(),
            totalPending: (result['totalPending'] as num? ?? 0).toDouble(),
            currentPage: result['currentPage'] as int,
            hasReachedMax: hasReachedMax,
            isRefreshing: false,
          ),
        );
      }
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
    } catch (e) {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
      if (state is TenantPaymentsLoaded) {
        emit((state as TenantPaymentsLoaded).copyWith(isRefreshing: false));
      }
      emit(TenantPaymentError(e.toString()));
    }
  }

  Future<void> _onAddTenantPayment(
    AddTenantPayment event,
    Emitter<TenantPaymentState> emit,
  ) async {
    emit(TenantPaymentLoading());
    try {
      await _tenantRepository.addTenantPayment(
        tenantId: event.tenantId,
        amount: event.amount,
        paymentDate: event.paymentDate,
        notes: event.notes,
        leaseId: event.leaseId,
        paymentMethod: event.paymentMethod,
        transactionId: event.transactionId,
        isSecurityDeposit: event.isSecurityDeposit,
      );
      emit(const TenantPaymentOperationSuccess('Payment added successfully'));
      add(LoadTenantPayments(tenantId: event.tenantId, isRefresh: true));
    } catch (e) {
      emit(TenantPaymentError(e.toString()));
    }
  }
}
