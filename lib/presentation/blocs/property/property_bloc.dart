import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/failures.dart';
import '../../../data/repositories/property_repository.dart';
import 'property_event.dart';
import 'property_state.dart';

export 'property_event.dart';
export 'property_state.dart';

class PropertyBloc extends Bloc<PropertyEvent, PropertyState> {
  final PropertyRepository _propertyRepository;

  PropertyBloc(this._propertyRepository) : super(const PropertyInitial()) {
    on<LoadProperties>(_onLoadProperties);
    on<RefreshProperties>(_onRefreshProperties);
    on<CreateProperty>(_onCreateProperty);
    on<UpdateProperty>(_onUpdateProperty);
    on<DeleteProperty>(_onDeleteProperty);
    on<UpdateRoom>(_onUpdateRoom);
    on<AddFloor>(_onAddFloor);
    on<UpdateFloor>(_onUpdateFloor);
    on<DeleteFloor>(_onDeleteFloor);
    on<AddRoom>(_onAddRoom);
    on<DeleteRoom>(_onDeleteRoom);
  }

  Future<void> _onRefreshProperties(
      RefreshProperties event, Emitter<PropertyState> emit) async {
    final currentState = state;
    try {
      final response = await _propertyRepository.getProperties(
        page: 1, // Reset to first page on refresh
        limit: 10, // Default limit
      );
      emit(PropertyLoaded(
        response.data,
        currentPage: response.currentPage,
        hasReachedMax: response.currentPage >= response.totalPages,
        isLoadingMore: false,
        vacantOnly:
            (currentState is PropertyLoaded ? currentState.vacantOnly : false),
      ));
      event.completer?.complete();
    } catch (e) {
      if (state is PropertyLoaded) {
        emit((state as PropertyLoaded).copyWith(
          operationError: e.toString(),
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(PropertyError(e.toString()));
      }
      event.completer?.complete();
    }
  }

  Future<void> _onLoadProperties(
      LoadProperties event, Emitter<PropertyState> emit) async {
    final currentState = state;

    if (event.isRefresh) {
      // Don't emit loading if we are just refreshing and already have data loaded
    } else if (currentState is! PropertyLoaded) {
      emit(const PropertyLoading());
    } else if (event.isLoadMore) {
      if (currentState.hasReachedMax || currentState.isLoadingMore) return;
      emit(currentState.copyWith(isLoadingMore: true));
    }

    try {
      final int pageToLoad = event.isRefresh
          ? 1
          : (currentState is PropertyLoaded && event.isLoadMore)
              ? currentState.currentPage + 1
              : 1;

      final response = await _propertyRepository.getProperties(
        page: pageToLoad,
        limit: event.limit,
        search: event.search,
        createdById: event.createdById,
        vacantOnly: event.vacantOnly,
      );

      if (event.isLoadMore && currentState is PropertyLoaded) {
        emit(currentState.copyWith(
          properties: [...currentState.properties, ...response.data],
          currentPage: response.currentPage,
          hasReachedMax: response.currentPage >= response.totalPages,
          isLoadingMore: false,
        ));
      } else {
        emit(PropertyLoaded(
          response.data,
          currentPage: response.currentPage,
          hasReachedMax: response.currentPage >= response.totalPages,
          vacantOnly: event.vacantOnly ?? false,
        ));
      }
    } catch (e) {
      if (state is PropertyLoaded) {
        emit((state as PropertyLoaded).copyWith(
          isLoadingMore: false,
          operationError: e.toString(),
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(PropertyError(e.toString()));
      }
    }
  }

  Future<void> _onCreateProperty(
      CreateProperty event, Emitter<PropertyState> emit) async {
    final currentState = state;
    if (currentState is PropertyLoaded) {
      // Clear previous success/error messages before starting new operation
      emit(currentState.copyWith(
        isOperationLoading: true,
        // Passing explicit null if supported, or wait, copyWith in Dart might ignore null.
        // Let's create a new PropertyLoaded if needed, but copyWith usually doesn't clear if null.
      ));
    } else {
      emit(const PropertyLoading());
    }

    try {
      await _propertyRepository.createProperty(event.propertyData);
      if (state is PropertyLoaded) {
        emit((state as PropertyLoaded).copyWith(
          isOperationLoading: false,
          operationSuccess: 'Property created successfully',
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(const PropertyOperationSuccess('Property created successfully'));
      }
      add(const LoadProperties()); // Reload list
    } catch (e) {
      if (state is PropertyLoaded) {
        emit((state as PropertyLoaded).copyWith(
          isOperationLoading: false,
          operationError: e.toString(),
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(PropertyError(e.toString()));
      }
    }
  }

  Future<void> _onUpdateProperty(
      UpdateProperty event, Emitter<PropertyState> emit) async {
    final currentState = state;
    if (currentState is PropertyLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
    } else {
      emit(const PropertyLoading());
    }

    try {
      await _propertyRepository.updateProperty(event.id, event.propertyData);
      if (state is PropertyLoaded) {
        emit((state as PropertyLoaded).copyWith(
          isOperationLoading: false,
          operationSuccess: 'Property updated successfully',
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(const PropertyOperationSuccess('Property updated successfully'));
      }
      add(const LoadProperties()); // Reload list
    } catch (e) {
      final errorMsg = e is Failure ? e.message : e.toString();
      if (state is PropertyLoaded) {
        emit((state as PropertyLoaded).copyWith(
          isOperationLoading: false,
          operationError: errorMsg,
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(PropertyError(errorMsg));
      }
    }
  }

  Future<void> _onDeleteProperty(
      DeleteProperty event, Emitter<PropertyState> emit) async {
    final currentState = state;
    if (currentState is PropertyLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
    } else {
      emit(const PropertyLoading());
    }

    try {
      await _propertyRepository.deleteProperty(event.id);
      if (state is PropertyLoaded) {
        emit((state as PropertyLoaded).copyWith(
          isOperationLoading: false,
          operationSuccess: 'Property deleted successfully',
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(const PropertyOperationSuccess('Property deleted successfully'));
      }
      add(const LoadProperties()); // Reload list
    } catch (e) {
      final errorMsg = e is Failure ? e.message : e.toString();
      if (state is PropertyLoaded) {
        emit((state as PropertyLoaded).copyWith(
          isOperationLoading: false,
          operationError: errorMsg,
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(PropertyError(errorMsg));
      }
    }
  }

  Future<void> _onUpdateRoom(
      UpdateRoom event, Emitter<PropertyState> emit) async {
    final currentState = state;
    if (currentState is PropertyLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
    }

    try {
      await _propertyRepository.updateRoom(event.roomId, event.roomData);
      if (state is PropertyLoaded) {
        emit((state as PropertyLoaded).copyWith(
          isOperationLoading: false,
          operationSuccess: 'Room updated successfully',
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(const PropertyOperationSuccess('Room updated successfully'));
      }
      add(const LoadProperties());
    } catch (e) {
      final errorMsg = e is Failure ? e.message : e.toString();
      if (state is PropertyLoaded) {
        emit((state as PropertyLoaded).copyWith(
          isOperationLoading: false,
          operationError: errorMsg,
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(PropertyError(errorMsg));
      }
    }
  }

  Future<void> _onAddFloor(
      AddFloor event, Emitter<PropertyState> emit) async {
    final currentState = state;
    if (currentState is PropertyLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
    }

    try {
      await _propertyRepository.addFloor(event.propertyId, event.floorNumber);
      if (state is PropertyLoaded) {
        emit((state as PropertyLoaded).copyWith(
          isOperationLoading: false,
          operationSuccess: 'Floor added successfully',
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(const PropertyOperationSuccess('Floor added successfully'));
      }
      add(const LoadProperties());
    } catch (e) {
      final errorMsg = e is Failure ? e.message : e.toString();
      if (state is PropertyLoaded) {
        emit((state as PropertyLoaded).copyWith(
          isOperationLoading: false,
          operationError: errorMsg,
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(PropertyError(errorMsg));
      }
    }
  }

  Future<void> _onUpdateFloor(
      UpdateFloor event, Emitter<PropertyState> emit) async {
    final currentState = state;
    if (currentState is PropertyLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
    }

    try {
      await _propertyRepository.updateFloor(event.floorId, event.floorNumber);
      if (state is PropertyLoaded) {
        emit((state as PropertyLoaded).copyWith(
          isOperationLoading: false,
          operationSuccess: 'Floor updated successfully',
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(const PropertyOperationSuccess('Floor updated successfully'));
      }
      add(const LoadProperties());
    } catch (e) {
      final errorMsg = e is Failure ? e.message : e.toString();
      if (state is PropertyLoaded) {
        emit((state as PropertyLoaded).copyWith(
          isOperationLoading: false,
          operationError: errorMsg,
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(PropertyError(errorMsg));
      }
    }
  }

  Future<void> _onDeleteFloor(
      DeleteFloor event, Emitter<PropertyState> emit) async {
    final currentState = state;
    if (currentState is PropertyLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
    }

    try {
      await _propertyRepository.deleteFloor(event.floorId);
      if (state is PropertyLoaded) {
        emit((state as PropertyLoaded).copyWith(
          isOperationLoading: false,
          operationSuccess: 'Floor deleted successfully',
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(const PropertyOperationSuccess('Floor deleted successfully'));
      }
      add(const LoadProperties());
    } catch (e) {
      final errorMsg = e is Failure ? e.message : e.toString();
      if (state is PropertyLoaded) {
        emit((state as PropertyLoaded).copyWith(
          isOperationLoading: false,
          operationError: errorMsg,
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(PropertyError(errorMsg));
      }
    }
  }

  Future<void> _onAddRoom(
      AddRoom event, Emitter<PropertyState> emit) async {
    final currentState = state;
    if (currentState is PropertyLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
    }

    try {
      await _propertyRepository.addRoom(event.propertyId, event.roomData);
      if (state is PropertyLoaded) {
        emit((state as PropertyLoaded).copyWith(
          isOperationLoading: false,
          operationSuccess: 'Room added successfully',
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(const PropertyOperationSuccess('Room added successfully'));
      }
      add(const LoadProperties());
    } catch (e) {
      final errorMsg = e is Failure ? e.message : e.toString();
      if (state is PropertyLoaded) {
        emit((state as PropertyLoaded).copyWith(
          isOperationLoading: false,
          operationError: errorMsg,
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(PropertyError(errorMsg));
      }
    }
  }

  Future<void> _onDeleteRoom(
      DeleteRoom event, Emitter<PropertyState> emit) async {
    final currentState = state;
    if (currentState is PropertyLoaded) {
      emit(currentState.copyWith(isOperationLoading: true));
    }

    try {
      await _propertyRepository.deleteRoom(event.roomId);
      if (state is PropertyLoaded) {
        emit((state as PropertyLoaded).copyWith(
          isOperationLoading: false,
          operationSuccess: 'Room deleted successfully',
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(const PropertyOperationSuccess('Room deleted successfully'));
      }
      add(const LoadProperties());
    } catch (e) {
      final errorMsg = e is Failure ? e.message : e.toString();
      if (state is PropertyLoaded) {
        emit((state as PropertyLoaded).copyWith(
          isOperationLoading: false,
          operationError: errorMsg,
          operationTimestamp: DateTime.now().millisecondsSinceEpoch,
        ));
      } else {
        emit(PropertyError(errorMsg));
      }
    }
  }
}
