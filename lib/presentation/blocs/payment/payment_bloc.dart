import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/models/payment_model.dart';
import '../../../data/repositories/payment_repository.dart';

// Events
abstract class PaymentEvent extends Equatable {
  const PaymentEvent();
  @override
  List<Object> get props => [];
}

class LoadPayments extends PaymentEvent {
  final bool isRefresh;
  final bool isLoadMore;
  final int limit;
  final String? tenantId;
  final String? propertyId;
  final String? leaseId;
  final String? startDate;
  final String? endDate;
  final String? receivedBy;
  final String? type;

  final Completer<void>? completer;

  const LoadPayments({
    this.isRefresh = false,
    this.isLoadMore = false,
    this.limit = 10,
    this.tenantId,
    this.propertyId,
    this.leaseId,
    this.startDate,
    this.endDate,
    this.receivedBy,
    this.type,
    this.completer,
  });

  @override
  List<Object> get props => [
        isRefresh,
        isLoadMore,
        limit,
        tenantId ?? '',
        propertyId ?? '',
        leaseId ?? '',
        startDate ?? '',
        endDate ?? '',
        receivedBy ?? '',
        type ?? '',
      ];
}

class AddPayment extends PaymentEvent {
  final Map<String, dynamic> paymentData;
  const AddPayment(this.paymentData);
  @override
  List<Object> get props => [paymentData];
}

class UpdatePayment extends PaymentEvent {
  final String id;
  final Map<String, dynamic> paymentData;
  const UpdatePayment(this.id, this.paymentData);
  @override
  List<Object> get props => [id, paymentData];
}

class DeletePayment extends PaymentEvent {
  final String id;
  const DeletePayment(this.id);
  @override
  List<Object> get props => [id];
}

// States
abstract class PaymentState extends Equatable {
  const PaymentState();
  @override
  List<Object> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentLoaded extends PaymentState {
  final List<PaymentModel> payments;
  final int currentPage;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final bool isRefreshing;
  final bool isOperationLoading;
  final String? operationError;
  final String? operationSuccess;
  final int? operationTimestamp;

  // Persistent filters
  final String? startDate;
  final String? endDate;
  final String? tenantId;
  final String? propertyId;
  final String? leaseId;
  final String? receivedBy;
  final String? type;

  const PaymentLoaded(
    this.payments, {
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.isOperationLoading = false,
    this.operationError,
    this.operationSuccess,
    this.operationTimestamp,
    this.startDate,
    this.endDate,
    this.tenantId,
    this.propertyId,
    this.leaseId,
    this.receivedBy,
    this.type,
  });

  PaymentLoaded copyWith({
    List<PaymentModel>? payments,
    int? currentPage,
    bool? hasReachedMax,
    bool? isLoadingMore,
    bool? isRefreshing,
    bool? isOperationLoading,
    String? operationError,
    String? operationSuccess,
    int? operationTimestamp,
    String? startDate,
    String? endDate,
    String? tenantId,
    String? propertyId,
    String? leaseId,
    String? receivedBy,
    String? type,
  }) {
    return PaymentLoaded(
      payments ?? this.payments,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isOperationLoading: isOperationLoading ?? this.isOperationLoading,
      operationError: operationError,
      operationSuccess: operationSuccess,
      operationTimestamp: operationTimestamp ?? this.operationTimestamp,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      tenantId: tenantId ?? this.tenantId,
      propertyId: propertyId ?? this.propertyId,
      leaseId: leaseId ?? this.leaseId,
      receivedBy: receivedBy ?? this.receivedBy,
      type: type ?? this.type,
    );
  }

  @override
  List<Object> get props => [
        payments,
        currentPage,
        hasReachedMax,
        isLoadingMore,
        isRefreshing,
        isOperationLoading,
        operationError ?? '',
        operationSuccess ?? '',
        operationTimestamp ?? 0,
        startDate ?? '',
        endDate ?? '',
        tenantId ?? '',
        propertyId ?? '',
        leaseId ?? '',
        receivedBy ?? '',
        type ?? '',
      ];
}

class PaymentOperationSuccess extends PaymentState {
  final String message;
  const PaymentOperationSuccess(this.message);
  @override
  List<Object> get props => [message];
}

class PaymentError extends PaymentState {
  final String message;
  final bool isOperationError;
  const PaymentError(this.message, {this.isOperationError = false});
  @override
  List<Object> get props => [message, isOperationError];
}

// Bloc
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository _paymentRepository;

  PaymentBloc(this._paymentRepository) : super(PaymentInitial()) {
    on<LoadPayments>(_onLoadPayments);
    on<AddPayment>(_onAddPayment);
    on<UpdatePayment>(_onUpdatePayment);
    on<DeletePayment>(_onDeletePayment);
  }

  Future<void> _onLoadPayments(
      LoadPayments event, Emitter<PaymentState> emit) async {
    final currentState = state;
    if (event.isRefresh && currentState is PaymentLoaded) {
      emit(currentState.copyWith(isRefreshing: true));
    } else if (currentState is! PaymentLoaded) {
      emit(PaymentLoading());
    } else if (event.isLoadMore) {
      if (currentState.hasReachedMax || currentState.isLoadingMore) return;
      emit(currentState.copyWith(isLoadingMore: true));
    }

    try {
      final int pageToLoad = event.isRefresh
          ? 1
          : (currentState is PaymentLoaded && event.isLoadMore)
              ? currentState.currentPage + 1
              : 1;

      // Use persistent filters if not provided in event
      final String? effectiveStartDate = event.startDate ??
          (currentState is PaymentLoaded ? currentState.startDate : null);
      final String? effectiveEndDate = event.endDate ??
          (currentState is PaymentLoaded ? currentState.endDate : null);
      final String? effectivePropertyId = event.propertyId ??
          (currentState is PaymentLoaded ? currentState.propertyId : null);
      final String? effectiveTenantId = event.tenantId ??
          (currentState is PaymentLoaded ? currentState.tenantId : null);
      final String? effectiveLeaseId = event.leaseId ??
          (currentState is PaymentLoaded ? currentState.leaseId : null);
      final String? effectiveReceivedBy = event.receivedBy ??
          (currentState is PaymentLoaded ? currentState.receivedBy : null);
      final String? effectiveType = event.type ??
          (currentState is PaymentLoaded ? currentState.type : null);

      final response = await _paymentRepository.getPayments(
        page: pageToLoad,
        limit: event.limit,
        tenantId: effectiveTenantId,
        propertyId: effectivePropertyId,
        leaseId: effectiveLeaseId,
        startDate: effectiveStartDate,
        endDate: effectiveEndDate,
        receivedBy: effectiveReceivedBy,
        type: effectiveType,
      );

      if (event.isLoadMore && currentState is PaymentLoaded) {
        final newState = currentState.copyWith(
          payments: [...currentState.payments, ...response.data],
          currentPage: response.currentPage,
          hasReachedMax: response.currentPage >= response.totalPages,
          isLoadingMore: false,
        );
        emit(newState);
      } else {
        final newState = PaymentLoaded(
          response.data,
          currentPage: response.currentPage,
          hasReachedMax: response.currentPage >= response.totalPages,
          isRefreshing: false,
          startDate: effectiveStartDate,
          endDate: effectiveEndDate,
          tenantId: effectiveTenantId,
          propertyId: effectivePropertyId,
          leaseId: effectiveLeaseId,
          receivedBy: effectiveReceivedBy,
          type: effectiveType,
        );
        emit(newState);
      }
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
    } catch (e) {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
      if (state is PaymentLoaded) {
        emit((state as PaymentLoaded).copyWith(
          isOperationLoading: false,
          isLoadingMore: false,
          isRefreshing: false,
          operationError: e.toString(),
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(PaymentError(e.toString()));
      }
    }
  }

  Future<void> _onAddPayment(
      AddPayment event, Emitter<PaymentState> emit) async {
    final currentState = state;
    if (currentState is PaymentLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
    } else {
      emit(PaymentLoading());
    }

    try {
      await _paymentRepository.addPayment(event.paymentData);
      if (currentState is PaymentLoaded) {
        emit(currentState.copyWith(
          isOperationLoading: false,
          operationSuccess: 'Payment added successfully',
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(const PaymentOperationSuccess('Payment added successfully'));
      }
      add(const LoadPayments());
    } catch (e) {
      if (currentState is PaymentLoaded) {
        emit(currentState.copyWith(
          isOperationLoading: false,
          operationError: e.toString(),
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(PaymentError(e.toString(), isOperationError: true));
      }
    }
  }

  Future<void> _onUpdatePayment(
      UpdatePayment event, Emitter<PaymentState> emit) async {
    final currentState = state;
    if (currentState is PaymentLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
    }

    try {
      await _paymentRepository.updatePayment(event.id, event.paymentData);
      if (currentState is PaymentLoaded) {
        emit(currentState.copyWith(
          isOperationLoading: false,
          operationSuccess: 'Payment updated successfully',
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(const PaymentOperationSuccess('Payment updated successfully'));
      }
      add(const LoadPayments());
    } catch (e) {
      if (currentState is PaymentLoaded) {
        emit(currentState.copyWith(
          isOperationLoading: false,
          operationError: e.toString(),
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(PaymentError(e.toString(), isOperationError: true));
      }
    }
  }

  Future<void> _onDeletePayment(
      DeletePayment event, Emitter<PaymentState> emit) async {
    final currentState = state;
    if (currentState is PaymentLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
    }

    try {
      await _paymentRepository.deletePayment(event.id);
      if (currentState is PaymentLoaded) {
        emit(currentState.copyWith(
          isOperationLoading: false,
          operationSuccess: 'Payment deleted successfully',
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(const PaymentOperationSuccess('Payment deleted successfully'));
      }
      add(const LoadPayments());
    } catch (e) {
      if (currentState is PaymentLoaded) {
        emit(currentState.copyWith(
          isOperationLoading: false,
          operationError: e.toString(),
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(PaymentError(e.toString(), isOperationError: true));
      }
    }
  }
}
