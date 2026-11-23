import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../data/repositories/analytics_repository.dart';
import '../../../core/models/analytics_model.dart';
import '../../../core/models/property_analytics_model.dart';

// Events
abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

class LoadAnalyticsOverview extends AnalyticsEvent {
  final DateTime? startDate;
  final DateTime? endDate;

  const LoadAnalyticsOverview({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}

// States
abstract class AnalyticsState extends Equatable {
  const AnalyticsState();

  @override
  List<Object?> get props => [];
}

class AnalyticsInitial extends AnalyticsState {}

class AnalyticsLoading extends AnalyticsState {}

class AnalyticsLoaded extends AnalyticsState {
  final TenantSummaryModel summary;
  final List<StaffCollectionModel> staffCollections;
  final List<PropertyAnalyticsModel> propertyAnalytics;
  final bool isOperationLoading;
  final String? operationError;
  final String? operationSuccess;
  final int? operationTimestamp;

  const AnalyticsLoaded({
    required this.summary,
    required this.staffCollections,
    required this.propertyAnalytics,
    this.isOperationLoading = false,
    this.operationError,
    this.operationSuccess,
    this.operationTimestamp,
  });

  AnalyticsLoaded copyWith({
    TenantSummaryModel? summary,
    List<StaffCollectionModel>? staffCollections,
    List<PropertyAnalyticsModel>? propertyAnalytics,
    bool? isOperationLoading,
    String? operationError,
    String? operationSuccess,
    int? operationTimestamp,
  }) {
    return AnalyticsLoaded(
      summary: summary ?? this.summary,
      staffCollections: staffCollections ?? this.staffCollections,
      propertyAnalytics: propertyAnalytics ?? this.propertyAnalytics,
      isOperationLoading: isOperationLoading ?? this.isOperationLoading,
      operationError: operationError,
      operationSuccess: operationSuccess,
      operationTimestamp: operationTimestamp ?? this.operationTimestamp,
    );
  }

  @override
  List<Object?> get props => [
        summary,
        staffCollections,
        propertyAnalytics,
        isOperationLoading,
        operationError,
        operationSuccess,
        operationTimestamp,
      ];
}

class AnalyticsError extends AnalyticsState {
  final String message;

  const AnalyticsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Bloc
class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final AnalyticsRepository _repository;

  AnalyticsBloc(this._repository) : super(AnalyticsInitial()) {
    on<LoadAnalyticsOverview>(_onLoadAnalyticsOverview);
  }

  Future<void> _onLoadAnalyticsOverview(
    LoadAnalyticsOverview event,
    Emitter<AnalyticsState> emit,
  ) async {
    final currentState = state;
    if (currentState is AnalyticsLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
    } else {
      emit(AnalyticsLoading());
    }

    try {
      final startDateStr = event.startDate?.toIso8601String();
      final endDateStr = event.endDate?.toIso8601String();

      final results = await Future.wait([
        _repository.getTenantSummary(
            startDate: startDateStr, endDate: endDateStr),
        _repository.getStaffCollections(
            startDate: startDateStr, endDate: endDateStr),
        _repository.getPropertyAnalytics(
            startDate: startDateStr, endDate: endDateStr),
      ]);

      emit(AnalyticsLoaded(
        summary: results[0] as TenantSummaryModel,
        staffCollections: results[1] as List<StaffCollectionModel>,
        propertyAnalytics: results[2] as List<PropertyAnalyticsModel>,
      ));
    } catch (e) {
      if (state is AnalyticsLoaded) {
        emit((state as AnalyticsLoaded).copyWith(
          isOperationLoading: false,
          operationError: e.toString(),
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(AnalyticsError(e.toString()));
      }
    }
  }
}
