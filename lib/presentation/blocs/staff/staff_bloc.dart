import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/models/user_model.dart';
import '../../../data/repositories/staff_repository.dart';

// Events
abstract class StaffEvent extends Equatable {
  const StaffEvent();
  @override
  List<Object> get props => [];
}

class LoadStaff extends StaffEvent {
  final bool isRefresh;
  final bool isLoadMore;
  final int limit;
  final bool? isActive;
  final bool? includeAdmin;
  final String? search;

  const LoadStaff({
    this.isRefresh = false,
    this.isLoadMore = false,
    this.limit = 10,
    this.isActive,
    this.includeAdmin,
    this.search,
  });

  @override
  List<Object> get props => [
        isRefresh,
        isLoadMore,
        limit,
        isActive ?? '',
        includeAdmin ?? '',
        search ?? ''
      ];
}

class CreateStaff extends StaffEvent {
  final Map<String, dynamic> staffData;
  const CreateStaff(this.staffData);
  @override
  List<Object> get props => [staffData];
}

class UpdateStaff extends StaffEvent {
  final String id;
  final Map<String, dynamic> staffData;
  const UpdateStaff(this.id, this.staffData);
  @override
  List<Object> get props => [id, staffData];
}

class DeleteStaff extends StaffEvent {
  final String id;
  const DeleteStaff(this.id);
  @override
  List<Object> get props => [id];
}

class GetStaffDetails extends StaffEvent {
  final String id;
  const GetStaffDetails(this.id);
  @override
  List<Object> get props => [id];
}

// States
abstract class StaffState extends Equatable {
  const StaffState();
  @override
  List<Object?> get props => [];
}

class StaffInitial extends StaffState {}

class StaffLoading extends StaffState {}

class StaffLoaded extends StaffState {
  final List<UserModel> staff;
  final int currentPage;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final UserModel? currentStaffDetail;
  final bool isOperationLoading;
  final String? operationError;
  final String? operationSuccess;
  final StaffOperationType? lastOperationType;
  final int? operationTimestamp;

  const StaffLoaded({
    required this.staff,
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.currentStaffDetail,
    this.isOperationLoading = false,
    this.operationError,
    this.operationSuccess,
    this.lastOperationType,
    this.operationTimestamp,
  });

  StaffLoaded copyWith({
    List<UserModel>? staff,
    int? currentPage,
    bool? hasReachedMax,
    bool? isLoadingMore,
    UserModel? currentStaffDetail,
    bool? isOperationLoading,
    String? operationError,
    String? operationSuccess,
    StaffOperationType? lastOperationType,
    int? operationTimestamp,
  }) {
    return StaffLoaded(
      staff: staff ?? this.staff,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      currentStaffDetail: currentStaffDetail ?? this.currentStaffDetail,
      isOperationLoading: isOperationLoading ?? this.isOperationLoading,
      operationError: operationError, // null by default if not provided
      operationSuccess: operationSuccess, // null by default if not provided
      lastOperationType: lastOperationType, // null by default if not provided
      operationTimestamp: operationTimestamp, // null by default if not provided
    );
  }

  @override
  List<Object?> get props => [
        staff,
        currentPage,
        hasReachedMax,
        isLoadingMore,
        currentStaffDetail,
        isOperationLoading,
        operationError,
        operationSuccess,
        lastOperationType,
        operationTimestamp,
      ];
}

class StaffError extends StaffState {
  final String message;
  const StaffError(this.message);
  @override
  List<Object> get props => [message];
}

enum StaffOperationType { create, update, delete }

class StaffOperationSuccess extends StaffState {
  final String message;
  final StaffOperationType type;

  const StaffOperationSuccess(this.message,
      {this.type = StaffOperationType.update});

  @override
  List<Object> get props => [message, type];
}

// Bloc
class StaffBloc extends Bloc<StaffEvent, StaffState> {
  final StaffRepository _staffRepository;

  StaffBloc(this._staffRepository) : super(StaffInitial()) {
    on<LoadStaff>(_onLoadStaff);
    on<CreateStaff>(_onCreateStaff);
    on<UpdateStaff>(_onUpdateStaff);
    on<DeleteStaff>(_onDeleteStaff);
    on<GetStaffDetails>(_onGetStaffDetails);
  }

  Future<void> _onLoadStaff(LoadStaff event, Emitter<StaffState> emit) async {
    final currentState = state;
    if (event.isRefresh) {
      // Refreshing
    } else if (currentState is! StaffLoaded) {
      emit(StaffLoading());
    } else if (event.isLoadMore) {
      if (currentState.hasReachedMax || currentState.isLoadingMore) return;
      emit(currentState.copyWith(isLoadingMore: true));
    }

    try {
      final int pageToLoad = event.isRefresh
          ? 1
          : (currentState is StaffLoaded && event.isLoadMore)
              ? currentState.currentPage + 1
              : 1;

      final response = await _staffRepository.getStaff(
        page: pageToLoad,
        limit: event.limit,
        isActive: event.isActive,
        includeAdmin: event.includeAdmin,
        search: event.search,
      );

      if (event.isLoadMore && currentState is StaffLoaded) {
        emit(currentState.copyWith(
          staff: [...currentState.staff, ...response.data],
          currentPage: response.currentPage,
          hasReachedMax: response.currentPage >= response.totalPages,
          isLoadingMore: false,
        ));
      } else {
        emit(StaffLoaded(
          staff: response.data,
          currentPage: response.currentPage,
          hasReachedMax: response.currentPage >= response.totalPages,
        ));
      }
    } catch (e) {
      if (state is StaffLoaded) {
        emit((state as StaffLoaded).copyWith(
          isOperationLoading: false,
          isLoadingMore: false,
          operationError: e.toString(),
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(StaffError(e.toString()));
      }
    }
  }

  Future<void> _onCreateStaff(
      CreateStaff event, Emitter<StaffState> emit) async {
    final currentState = state;
    if (currentState is StaffLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
    } else {
      emit(StaffLoading());
    }

    try {
      await _staffRepository.createStaff(event.staffData);
      if (currentState is StaffLoaded) {
        emit(currentState.copyWith(
          isOperationLoading: false,
          operationSuccess: 'Staff created successfully',
          operationError: null,
          lastOperationType: StaffOperationType.create,
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(const StaffOperationSuccess('Staff created successfully',
            type: StaffOperationType.create));
      }
    } catch (e) {
      if (currentState is StaffLoaded) {
        emit(currentState.copyWith(
          isOperationLoading: false,
          operationError: e.toString(),
          operationSuccess: null,
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(StaffError(e.toString()));
      }
    }
  }

  Future<void> _onUpdateStaff(
      UpdateStaff event, Emitter<StaffState> emit) async {
    final currentState = state;
    if (currentState is StaffLoaded) {
      // Don't set type to null here, or maybe do to clear previous?
      // Better to clear previous success/type on start?
      // copyWith without args keeps previous values? No, my copyWith implementation keeps if null.
      // But here we want to clear old success.
      // Actually my copyWith:
      // operationSuccess: operationSuccess, // if passed
      // If I call copyWith(isOperationLoading: true), operationSuccess is undefined in args -> null?
      // No: operationSuccess: operationSuccess, // null by default if not provided
      // Wait, in build method:
      // operationSuccess: operationSuccess, // null by default if not provided
      // No, Dart optional params are null if not provided.
      // But inside copyWith body:
      // operationSuccess: operationSuccess,
      // If I don't pass `operationSuccess` to copyWith, it is null.
      // So passed value is null.
      // My copyWith implementation:
      // operationSuccess: operationSuccess,
      // This assigns the passed null to the field. So it clears it!
      // EXCEPT:
      // operationSuccess: operationSuccess ?? this.operationSuccess ??
      // Wait, let's look at previous file content I wrote in step 582.
      // operationSuccess: operationSuccess, // null by default if not provided
      // This comment suggests I am passing it directly.
      // `operationSuccess` arg is nullable.
      // If I say `operationSuccess: null`, I mean clear it?
      // No, `operationError: operationError`.
      // If `operationError` ref is null (not passed), it passes null.
      // So it CLEARS the field.
      // This is correct behavior for starting a new operation!
      emit(currentState.copyWith(isOperationLoading: true));
    } else {
      emit(StaffLoading());
    }

    try {
      final updatedStaff =
          await _staffRepository.updateStaff(event.id, event.staffData);
      if (currentState is StaffLoaded) {
        // Update the list
        final updatedList = currentState.staff.map((s) {
          return s.id == event.id ? updatedStaff : s;
        }).toList();

        // Also update the currentStaffDetail if it matches or if it's the one being viewed
        // Actually if we are in details view of this person, we MUST update it.
        UserModel? currentDetail = currentState.currentStaffDetail;
        if (currentDetail != null && currentDetail.id == event.id) {
          currentDetail = updatedStaff;
        }

        emit(currentState.copyWith(
          staff: updatedList,
          currentStaffDetail: currentDetail,
          isOperationLoading: false,
          operationSuccess: 'Staff updated successfully',
          operationError: null,
          lastOperationType: StaffOperationType.update,
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(const StaffOperationSuccess('Staff updated successfully',
            type: StaffOperationType.update));
      }
    } catch (e) {
      if (currentState is StaffLoaded) {
        emit(currentState.copyWith(
          isOperationLoading: false,
          operationError: e.toString(),
          operationSuccess: null,
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(StaffError(e.toString()));
      }
    }
  }

  Future<void> _onDeleteStaff(
      DeleteStaff event, Emitter<StaffState> emit) async {
    final currentState = state;
    if (currentState is StaffLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
    } else {
      emit(StaffLoading());
    }

    try {
      await _staffRepository.deleteStaff(event.id);
      if (currentState is StaffLoaded) {
        emit(currentState.copyWith(
          isOperationLoading: false,
          operationSuccess: 'Staff deleted successfully',
          operationError: null,
          lastOperationType: StaffOperationType.delete,
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
        add(const LoadStaff()); // Refresh list after delete
      } else {
        emit(const StaffOperationSuccess('Staff deleted successfully',
            type: StaffOperationType.delete));
        add(const LoadStaff());
      }
    } catch (e) {
      if (currentState is StaffLoaded) {
        emit(currentState.copyWith(
          isOperationLoading: false,
          operationError: e.toString(),
          operationSuccess: null,
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {}
    }
  }

  Future<void> _onGetStaffDetails(
      GetStaffDetails event, Emitter<StaffState> emit) async {
    final currentState = state;
    try {
      final staff = await _staffRepository.getStaffById(event.id);
      if (currentState is StaffLoaded) {
        emit(currentState.copyWith(currentStaffDetail: staff));
      } else {
        emit(StaffLoaded(staff: const [], currentStaffDetail: staff));
      }
    } catch (e) {
      emit(StaffError(e.toString()));
    }
  }
}
