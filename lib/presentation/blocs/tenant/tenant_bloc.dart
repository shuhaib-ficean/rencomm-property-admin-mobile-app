import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/models/tenant_model.dart';
import '../../../core/models/lease_model.dart';
import '../../../data/repositories/tenant_repository.dart';

// Events
abstract class TenantEvent extends Equatable {
  const TenantEvent();
  @override
  List<Object?> get props => [];
}

class LoadTenants extends TenantEvent {
  final bool isRefresh;
  final bool isLoadMore;
  final int limit;
  final String? status;
  final String? search;
  final String? propertyId;
  final String? createdById;

  const LoadTenants({
    this.isRefresh = false,
    this.isLoadMore = false,
    this.limit = 10,
    this.status,
    this.search,
    this.propertyId,
    this.createdById,
  });

  @override
  List<Object> get props => [
        isRefresh,
        isLoadMore,
        limit,
        status ?? '',
        search ?? '',
        propertyId ?? '',
        createdById ?? ''
      ];
}

class CreateTenant extends TenantEvent {
  final Map<String, dynamic> tenantData;
  const CreateTenant(this.tenantData);
  @override
  List<Object> get props => [tenantData];
}

class UpdateTenant extends TenantEvent {
  final String id;
  final Map<String, dynamic> tenantData;
  const UpdateTenant(this.id, this.tenantData);
  @override
  List<Object> get props => [id, tenantData];
}

class DeleteTenant extends TenantEvent {
  final String id;
  const DeleteTenant(this.id);
  @override
  List<Object> get props => [id];
}

// class AssignProperty extends TenantEvent {
//   final String tenantId;
//   final String propertyId;
//   const AssignProperty(this.tenantId, this.propertyId);
//   @override
//   List<Object> get props => [tenantId, propertyId];
// }

class AssignRoom extends TenantEvent {
  final String tenantId;
  final String roomId;
  final double? rentAmount;
  final double? securityDeposit;
  final String? startDate;
  final bool? isRecurring;
  final int? durationDays;
  const AssignRoom(
    this.tenantId,
    this.roomId, {
    this.rentAmount,
    this.securityDeposit,
    this.startDate,
    this.isRecurring,
    this.durationDays,
  });
  @override
  List<Object?> get props => [
        tenantId,
        roomId,
        rentAmount,
        securityDeposit,
        startDate,
        isRecurring,
        durationDays,
      ];
}

class UnassignRoom extends TenantEvent {
  final String tenantId;
  final String roomId;
  final String propertyId;
  const UnassignRoom(this.tenantId, this.roomId, this.propertyId);
  @override
  List<Object> get props => [tenantId, roomId, propertyId];
}

/// Update tenant documents. Each list can contain String (URLs) or File (to upload).
class UpdateTenantDocuments extends TenantEvent {
  final String tenantId;
  final TenantModel tenant;
  final List<dynamic> passportFrontImages;
  final List<dynamic> passportBackImages;
  final List<dynamic> qatarIdImages;

  const UpdateTenantDocuments({
    required this.tenantId,
    required this.tenant,
    required this.passportFrontImages,
    required this.passportBackImages,
    required this.qatarIdImages,
  });

  @override
  List<Object> get props => [
        tenantId,
        passportFrontImages,
        passportBackImages,
        qatarIdImages,
      ];
}

class AddTenantAmenity extends TenantEvent {
  final String tenantId;
  final String description;
  final DateTime providedAt;

  const AddTenantAmenity({
    required this.tenantId,
    required this.description,
    required this.providedAt,
  });

  @override
  List<Object> get props => [tenantId, description, providedAt];
}

class DeleteTenantAmenity extends TenantEvent {
  final String tenantId;
  final String amenityId;

  const DeleteTenantAmenity({
    required this.tenantId,
    required this.amenityId,
  });

  @override
  List<Object> get props => [tenantId, amenityId];
}

class UpdateTenantAmenity extends TenantEvent {
  final String tenantId;
  final String amenityId;
  final String description;
  final DateTime providedAt;

  const UpdateTenantAmenity({
    required this.tenantId,
    required this.amenityId,
    required this.description,
    required this.providedAt,
  });

  @override
  List<Object> get props => [tenantId, amenityId, description, providedAt];
}

class GetTenantDetails extends TenantEvent {
  final String id;
  const GetTenantDetails(this.id);
  @override
  List<Object> get props => [id];
}

class GetTenantLeases extends TenantEvent {
  final String tenantId;
  const GetTenantLeases(this.tenantId);
  @override
  List<Object> get props => [tenantId];
}

// States
abstract class TenantState extends Equatable {
  const TenantState();
  @override
  List<Object?> get props => [];
}

class TenantInitial extends TenantState {}

class TenantLoading extends TenantState {}

class TenantLoaded extends TenantState {
  final List<TenantModel> tenants;
  final int currentPage;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final bool isOperationLoading;
  final String? operationError;
  final String? operationSuccess;
  final TenantOperation? lastOperation;
  final int? operationTimestamp;
  final TenantModel? currentTenantDetail;
  final List<LeaseModel>? currentTenantLeases;
  final bool isDetailLoading;
  final bool isLeasesLoading;

  const TenantLoaded({
    required this.tenants,
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.isOperationLoading = false,
    this.operationError,
    this.operationSuccess,
    this.lastOperation,
    this.operationTimestamp,
    this.currentTenantDetail,
    this.currentTenantLeases,
    this.isDetailLoading = false,
    this.isLeasesLoading = false,
  });

  TenantLoaded copyWith({
    List<TenantModel>? tenants,
    int? currentPage,
    bool? hasReachedMax,
    bool? isLoadingMore,
    bool? isOperationLoading,
    String? operationError,
    String? operationSuccess,
    TenantOperation? lastOperation,
    int? operationTimestamp,
    TenantModel? currentTenantDetail,
    List<LeaseModel>? currentTenantLeases,
    bool? isDetailLoading,
    bool? isLeasesLoading,
  }) {
    return TenantLoaded(
      tenants: tenants ?? this.tenants,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isOperationLoading: isOperationLoading ?? this.isOperationLoading,
      operationError: operationError,
      operationSuccess: operationSuccess,
      lastOperation: lastOperation ?? this.lastOperation,
      operationTimestamp: operationTimestamp ?? this.operationTimestamp,
      currentTenantDetail: currentTenantDetail ?? this.currentTenantDetail,
      currentTenantLeases: currentTenantLeases ?? this.currentTenantLeases,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      isLeasesLoading: isLeasesLoading ?? this.isLeasesLoading,
    );
  }

  @override
  List<Object?> get props => [
        tenants,
        currentPage,
        hasReachedMax,
        isLoadingMore,
        isOperationLoading,
        operationError,
        operationSuccess,
        lastOperation,
        operationTimestamp,
        currentTenantDetail,
        currentTenantLeases,
        isDetailLoading,
        isLeasesLoading,
      ];
}

enum TenantOperation { create, update, delete, assignRoom, unassignRoom }

class TenantOperationSuccess extends TenantState {
  final String message;
  final TenantOperation operation;
  const TenantOperationSuccess(this.message, this.operation);
  @override
  List<Object> get props => [message, operation];
}

class TenantError extends TenantState {
  final String message;
  final bool isOperationError; // New field
  const TenantError(this.message, {this.isOperationError = false});
  @override
  List<Object> get props => [message, isOperationError];
}

// Bloc
class TenantBloc extends Bloc<TenantEvent, TenantState> {
  final TenantRepository _tenantRepository;

  TenantBloc(this._tenantRepository) : super(TenantInitial()) {
    on<LoadTenants>(_onLoadTenants);
    on<CreateTenant>(_onCreateTenant);
    on<UpdateTenant>(_onUpdateTenant);
    on<DeleteTenant>(_onDeleteTenant);
    // on<AssignProperty>(_onAssignProperty);
    on<AssignRoom>(_onAssignRoom);
    on<UnassignRoom>(_onUnassignRoom);
    on<UpdateTenantDocuments>(_onUpdateTenantDocuments);
    on<AddTenantAmenity>(_onAddTenantAmenity);
    on<DeleteTenantAmenity>(_onDeleteTenantAmenity);
    on<GetTenantDetails>(_onGetTenantDetails);
    on<GetTenantLeases>(_onGetTenantLeases);
    on<UpdateTenantAmenity>(_onUpdateTenantAmenity);
  }

  Future<void> _onLoadTenants(
    LoadTenants event,
    Emitter<TenantState> emit,
  ) async {
    final currentState = state;
    if (event.isRefresh) {
      // Don't emit loading if refreshing
    } else if (currentState is! TenantLoaded || currentState.tenants.isEmpty) {
      emit(TenantLoading());
    } else if (event.isLoadMore) {
      if (currentState.hasReachedMax || currentState.isLoadingMore) return;
      emit(currentState.copyWith(isLoadingMore: true));
    }

    try {
      final int pageToLoad = event.isRefresh
          ? 1
          : (currentState is TenantLoaded && event.isLoadMore)
              ? currentState.currentPage + 1
              : 1;

      final response = await _tenantRepository.getTenants(
        page: pageToLoad,
        limit: event.limit,
        status: event.status,
        search: event.search,
        propertyId: event.propertyId,
        createdById: event.createdById,
      );

      if (event.isLoadMore && currentState is TenantLoaded) {
        emit(
          currentState.copyWith(
            tenants: [...currentState.tenants, ...response.data],
            currentPage: response.currentPage,
            hasReachedMax: response.currentPage >= response.totalPages,
            isLoadingMore: false,
          ),
        );
      } else {
        if (state is TenantLoaded) {
          emit(
            (state as TenantLoaded).copyWith(
              tenants: response.data,
              currentPage: response.currentPage,
              hasReachedMax: response.currentPage >= response.totalPages,
              isDetailLoading: false,
            ),
          );
        } else {
          emit(TenantLoaded(
            tenants: response.data,
            currentPage: response.currentPage,
            hasReachedMax: response.currentPage >= response.totalPages,
          ));
        }
      }
    } catch (e) {
      if (state is TenantLoaded) {
        emit(
          (state as TenantLoaded).copyWith(
            isOperationLoading: false,
            isLoadingMore: false,
            operationError: e.toString(),
            operationTimestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } else {
        emit(TenantError(e.toString()));
      }
    }
  }

  Future<void> _onCreateTenant(
    CreateTenant event,
    Emitter<TenantState> emit,
  ) async {
    final currentState = state;
    if (currentState is TenantLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
    } else {
      emit(TenantLoading());
    }

    try {
      final newTenant = await _tenantRepository.createTenant(event.tenantData);

      if (currentState is TenantLoaded) {
        final updatedTenants = [newTenant, ...currentState.tenants];
        emit(
          currentState.copyWith(
            tenants: updatedTenants,
            isOperationLoading: false,
            operationSuccess: 'Tenant created successfully',
            lastOperation: TenantOperation.create,
            operationTimestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } else {
        emit(
          const TenantOperationSuccess(
            'Tenant created successfully',
            TenantOperation.create,
          ),
        );
      }
    } catch (e) {
      if (currentState is TenantLoaded) {
        emit(
          currentState.copyWith(
            isOperationLoading: false,
            operationError: e.toString(),
            operationTimestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } else {
        emit(TenantError(e.toString(), isOperationError: true));
      }
    }
  }

  Future<void> _onUpdateTenant(
    UpdateTenant event,
    Emitter<TenantState> emit,
  ) async {
    final currentState = state;
    if (currentState is TenantLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
    } else {
      emit(TenantLoading());
    }

    try {
      final updatedTenant = await _tenantRepository.updateTenant(
        event.id,
        event.tenantData,
      );
      if (currentState is TenantLoaded) {
        emit(
          currentState.copyWith(
            isOperationLoading: false,
            operationSuccess: 'Tenant updated successfully',
            lastOperation: TenantOperation.update,
            operationTimestamp: DateTime.now().millisecondsSinceEpoch,
            currentTenantDetail: updatedTenant,
          ),
        );
      } else {
        emit(
          const TenantOperationSuccess(
            'Tenant updated successfully',
            TenantOperation.update,
          ),
        );
      }
    } catch (e) {
      if (currentState is TenantLoaded) {
        emit(
          currentState.copyWith(
            isOperationLoading: false,
            operationError: e.toString(),
            operationTimestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } else {
        emit(TenantError(e.toString(), isOperationError: true));
      }
    }
  }

  Future<void> _onDeleteTenant(
    DeleteTenant event,
    Emitter<TenantState> emit,
  ) async {
    final currentState = state;
    if (currentState is TenantLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
    } else {
      emit(TenantLoading());
    }

    try {
      await _tenantRepository.deleteTenant(event.id);
      if (currentState is TenantLoaded) {
        emit(
          currentState.copyWith(
            isOperationLoading: false,
            operationSuccess: 'Tenant deleted successfully',
            lastOperation: TenantOperation.delete,
            operationTimestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } else {
        emit(
          const TenantOperationSuccess(
            'Tenant deleted successfully',
            TenantOperation.delete,
          ),
        );
      }
      add(const LoadTenants());
    } catch (e) {
      if (currentState is TenantLoaded) {
        emit(
          currentState.copyWith(
            isOperationLoading: false,
            operationError: e.toString(),
            operationTimestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } else {
        emit(TenantError(e.toString(), isOperationError: true));
      }
    }
  }

  Future<void> _onAssignRoom(
    AssignRoom event,
    Emitter<TenantState> emit,
  ) async {
    final currentState = state;
    if (currentState is TenantLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
    } else {
      emit(TenantLoading());
    }

    try {
      await _tenantRepository.assignRoom(
        event.tenantId,
        event.roomId,
        rentAmount: event.rentAmount,
        securityDeposit: event.securityDeposit,
        startDate: event.startDate,
        isRecurring: event.isRecurring,
        durationDays: event.durationDays,
      );
      if (currentState is TenantLoaded) {
        emit(
          currentState.copyWith(
            isOperationLoading: false,
            operationSuccess: 'Room assigned successfully',
            lastOperation: TenantOperation.assignRoom,
            operationTimestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } else {
        emit(
          const TenantOperationSuccess(
            'Room assigned successfully',
            TenantOperation.assignRoom,
          ),
        );
      }
      add(const LoadTenants());
      add(GetTenantDetails(event.tenantId));
    } catch (e) {
      if (currentState is TenantLoaded) {
        emit(
          currentState.copyWith(
            isOperationLoading: false,
            operationError: e.toString(),
            operationTimestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } else {
        emit(TenantError(e.toString(), isOperationError: true));
      }
    }
  }

  Future<void> _onUnassignRoom(
    UnassignRoom event,
    Emitter<TenantState> emit,
  ) async {
    final currentState = state;
    if (currentState is TenantLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
    } else {
      emit(TenantLoading());
    }

    try {
      await _tenantRepository.unassignRoom(
        event.tenantId,
        event.roomId,
        event.propertyId,
      );
      if (currentState is TenantLoaded) {
        emit(
          currentState.copyWith(
            isOperationLoading: false,
            operationSuccess: 'Room unassigned successfully',
            lastOperation: TenantOperation.unassignRoom,
            operationTimestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } else {
        emit(
          const TenantOperationSuccess(
            'Room unassigned successfully',
            TenantOperation.unassignRoom,
          ),
        );
      }
      add(const LoadTenants());
      add(GetTenantDetails(event.tenantId));
    } catch (e) {
      if (currentState is TenantLoaded) {
        emit(
          currentState.copyWith(
            isOperationLoading: false,
            operationError: e.toString(),
            operationTimestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } else {
        emit(TenantError(e.toString(), isOperationError: true));
      }
    }
  }

  Future<void> _onUpdateTenantDocuments(
    UpdateTenantDocuments event,
    Emitter<TenantState> emit,
  ) async {
    final currentState = state;
    if (currentState is TenantLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
    } else {
      emit(TenantLoading());
    }

    try {
      const keys = [
        'passportFrontImages',
        'passportBackImages',
        'qatarIdImages',
      ];
      final lists = [
        event.passportFrontImages,
        event.passportBackImages,
        event.qatarIdImages,
      ];
      final List<List<String>> resultUrls = [];

      // Helper to get original list by index
      List<String> getOriginalList(int index) {
        if (index == 0) return event.tenant.passportFrontImages ?? [];
        if (index == 1) return event.tenant.passportBackImages ?? [];
        if (index == 2) return event.tenant.qatarIdImages ?? [];
        return [];
      }

      for (int i = 0; i < keys.length; i++) {
        final existingUrls = lists[i].whereType<String>().toList();
        final newFiles = lists[i].whereType<File>().toList();
        if (newFiles.isNotEmpty) {
          try {
            final serverList = await _tenantRepository
                .uploadTenantDocumentFiles(event.tenantId, keys[i], newFiles);

            final originalList = getOriginalList(i);
            // Identify newly created URLs by checking what wasn't in the original list
            final newUrls =
                serverList.where((url) => !originalList.contains(url)).toList();

            resultUrls.add([...existingUrls, ...newUrls]);
          } catch (e) {
            // On failure, keep user's current valid URLs (deletions preserved, additions failed)
            resultUrls.add(existingUrls);
          }
        } else {
          resultUrls.add(existingUrls);
        }
      }
      final tenantData = {
        ...event.tenant.toJson(),
        'passportFrontImages': resultUrls[0],
        'passportBackImages': resultUrls[1],
        'qatarIdImages': resultUrls[2],
      };
      await _tenantRepository.updateTenant(event.tenantId, tenantData);

      if (currentState is TenantLoaded) {
        emit(
          currentState.copyWith(
            isOperationLoading: false,
            operationSuccess: 'Documents saved successfully',
            lastOperation: TenantOperation.update,
            operationTimestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } else {
        emit(
          const TenantOperationSuccess(
            'Documents saved successfully',
            TenantOperation.update,
          ),
        );
      }
      add(const LoadTenants());
      add(GetTenantDetails(event.tenantId));
    } catch (e) {
      if (currentState is TenantLoaded) {
        emit(
          currentState.copyWith(
            isOperationLoading: false,
            operationError: e.toString(),
            operationTimestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } else {
        emit(TenantError(e.toString(), isOperationError: true));
      }
    }
  }

  Future<void> _onGetTenantDetails(
    GetTenantDetails event,
    Emitter<TenantState> emit,
  ) async {
    final currentState = state;
    if (currentState is TenantLoaded) {
      emit(currentState.copyWith(isDetailLoading: true));
    }

    try {
      final tenant = await _tenantRepository.getTenantById(event.id);
      if (state is TenantLoaded) {
        emit(
          (state as TenantLoaded).copyWith(
            currentTenantDetail: tenant,
            isDetailLoading: false,
          ),
        );
      } else {
        emit(TenantLoaded(tenants: const [], currentTenantDetail: tenant));
      }
    } catch (e) {
      if (state is TenantLoaded) {
        emit(
          (state as TenantLoaded).copyWith(
            isDetailLoading: false,
            operationError: e.toString(),
          ),
        );
      } else {
        emit(TenantError(e.toString()));
      }
    }
  }

  Future<void> _onGetTenantLeases(
    GetTenantLeases event,
    Emitter<TenantState> emit,
  ) async {
    final currentState = state;
    if (currentState is TenantLoaded) {
      emit(currentState.copyWith(isLeasesLoading: true));
    }

    try {
      final leases = await _tenantRepository.getLeasesByTenantId(
        event.tenantId,
      );
      if (state is TenantLoaded) {
        emit(
          (state as TenantLoaded).copyWith(
            currentTenantLeases: leases,
            isLeasesLoading: false,
          ),
        );
      } else {
        emit(TenantLoaded(tenants: const [], currentTenantLeases: leases));
      }
    } catch (e) {
      if (state is TenantLoaded) {
        emit(
          (state as TenantLoaded).copyWith(
            isLeasesLoading: false,
            operationError: e.toString(),
          ),
        );
      } else {
        emit(TenantError(e.toString()));
      }
    }
  }

  Future<void> _onAddTenantAmenity(
    AddTenantAmenity event,
    Emitter<TenantState> emit,
  ) async {
    final currentState = state;
    if (currentState is TenantLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
    } else {
      emit(TenantLoading());
    }

    try {
      await _tenantRepository.addTenantAmenity(
        event.tenantId,
        event.description,
        event.providedAt,
      );

      if (currentState is TenantLoaded) {
        emit(
          currentState.copyWith(
            isOperationLoading: false,
            operationSuccess: 'Amenity added successfully',
            lastOperation: TenantOperation.update,
            operationTimestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } else {
        emit(
          const TenantOperationSuccess(
            'Amenity added successfully',
            TenantOperation.update,
          ),
        );
      }
      add(GetTenantDetails(event.tenantId));
    } catch (e) {
      if (currentState is TenantLoaded) {
        emit(
          currentState.copyWith(
            isOperationLoading: false,
            operationError: e.toString(),
            operationTimestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } else {
        emit(TenantError(e.toString(), isOperationError: true));
      }
    }
  }

  Future<void> _onDeleteTenantAmenity(
    DeleteTenantAmenity event,
    Emitter<TenantState> emit,
  ) async {
    final currentState = state;
    if (currentState is TenantLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
    } else {
      emit(TenantLoading());
    }

    try {
      await _tenantRepository.removeTenantAmenity(
        event.tenantId,
        event.amenityId,
      );

      if (currentState is TenantLoaded) {
        emit(
          currentState.copyWith(
            isOperationLoading: false,
            operationSuccess: 'Amenity removed successfully',
            lastOperation: TenantOperation.update,
            operationTimestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } else {
        emit(
          const TenantOperationSuccess(
            'Amenity removed successfully',
            TenantOperation.update,
          ),
        );
      }
      add(GetTenantDetails(event.tenantId));
    } catch (e) {
      if (currentState is TenantLoaded) {
        emit(
          currentState.copyWith(
            isOperationLoading: false,
            operationError: e.toString(),
            operationTimestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } else {
        emit(TenantError(e.toString(), isOperationError: true));
      }
    }
  }

  Future<void> _onUpdateTenantAmenity(
    UpdateTenantAmenity event,
    Emitter<TenantState> emit,
  ) async {
    final currentState = state;
    if (currentState is TenantLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
    } else {
      emit(TenantLoading());
    }

    try {
      await _tenantRepository.updateTenantAmenity(
        event.tenantId,
        event.amenityId,
        event.description,
        event.providedAt,
      );

      if (currentState is TenantLoaded) {
        emit(
          currentState.copyWith(
            isOperationLoading: false,
            operationSuccess: 'Amenity updated successfully',
            lastOperation: TenantOperation.update,
            operationTimestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } else {
        emit(
          const TenantOperationSuccess(
            'Amenity updated successfully',
            TenantOperation.update,
          ),
        );
      }
      add(GetTenantDetails(event.tenantId));
    } catch (e) {
      if (currentState is TenantLoaded) {
        emit(
          currentState.copyWith(
            isOperationLoading: false,
            operationError: e.toString(),
            operationTimestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      } else {
        emit(TenantError(e.toString(), isOperationError: true));
      }
    }
  }
}
