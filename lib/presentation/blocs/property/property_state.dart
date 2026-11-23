import 'package:equatable/equatable.dart';
import '../../../core/models/property_model.dart';

abstract class PropertyState extends Equatable {
  const PropertyState();
  @override
  List<Object?> get props => [];
}

class PropertyInitial extends PropertyState {
  const PropertyInitial();
}

class PropertyLoading extends PropertyState {
  const PropertyLoading();
}

class PropertyLoaded extends PropertyState {
  final List<PropertyModel> properties;
  final int currentPage;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final bool isOperationLoading;
  final String? operationError;
  final String? operationSuccess;
  final int? operationTimestamp;
  final bool vacantOnly;

  const PropertyLoaded(
    this.properties, {
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.isOperationLoading = false,
    this.operationError,
    this.operationSuccess,
    this.operationTimestamp,
    this.vacantOnly = false,
  });

  PropertyLoaded copyWith({
    List<PropertyModel>? properties,
    int? currentPage,
    bool? hasReachedMax,
    bool? isLoadingMore,
    bool? isOperationLoading,
    String? operationError,
    String? operationSuccess,
    int? operationTimestamp,
    bool? vacantOnly,
  }) {
    return PropertyLoaded(
      properties ?? this.properties,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isOperationLoading: isOperationLoading ?? this.isOperationLoading,
      operationError: operationError,
      operationSuccess: operationSuccess,
      operationTimestamp: operationTimestamp ?? this.operationTimestamp,
      vacantOnly: vacantOnly ?? this.vacantOnly,
    );
  }

  @override
  List<Object?> get props => [
        properties,
        currentPage,
        hasReachedMax,
        isLoadingMore,
        isOperationLoading,
        operationError,
        operationSuccess,
        operationTimestamp,
        vacantOnly,
      ];
}

class PropertyOperationSuccess extends PropertyState {
  final String message;
  const PropertyOperationSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class PropertyError extends PropertyState {
  final String message;
  const PropertyError(this.message);
  @override
  List<Object?> get props => [message];
}
