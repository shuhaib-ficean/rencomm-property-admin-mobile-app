import 'package:flutter_bloc/flutter_bloc.dart';
import 'amenity_event.dart';
import 'amenity_state.dart';
import '../../../data/repositories/amenity_repository.dart';

class AmenityBloc extends Bloc<AmenityEvent, AmenityState> {
  final AmenityRepository _repository;

  AmenityBloc({required AmenityRepository repository})
      : _repository = repository,
        super(AmenityInitial()) {
    on<LoadAmenities>(_onLoadAmenities);
    on<CreateAmenity>(_onCreateAmenity);
    on<UpdateAmenity>(_onUpdateAmenity);
    on<DeleteAmenity>(_onDeleteAmenity);
  }

  Future<void> _onLoadAmenities(
      LoadAmenities event, Emitter<AmenityState> emit) async {
    emit(AmenityLoading());
    try {
      final amenities = await _repository.getAmenities();
      emit(AmenitiesLoaded(amenities));
    } catch (e) {
      emit(AmenityError(e.toString()));
    }
  }

  Future<void> _onCreateAmenity(
      CreateAmenity event, Emitter<AmenityState> emit) async {
    try {
      await _repository.createAmenity(
        name: event.name,
        category: event.category,
      );
      emit(const AmenitySuccess('Amenity created successfully'));
      add(LoadAmenities()); // Refresh list
    } catch (e) {
      emit(AmenityError(e.toString()));
    }
  }

  Future<void> _onUpdateAmenity(
      UpdateAmenity event, Emitter<AmenityState> emit) async {
    try {
      await _repository.updateAmenity(
        id: event.id,
        name: event.name,
        category: event.category,
      );
      emit(const AmenitySuccess('Amenity updated successfully'));
      add(LoadAmenities()); // Refresh list
    } catch (e) {
      emit(AmenityError(e.toString()));
    }
  }

  Future<void> _onDeleteAmenity(
      DeleteAmenity event, Emitter<AmenityState> emit) async {
    try {
      await _repository.deleteAmenity(event.id);
      emit(const AmenitySuccess('Amenity deleted successfully'));
      add(LoadAmenities()); // Refresh list
    } catch (e) {
      emit(AmenityError(e.toString()));
    }
  }
}
