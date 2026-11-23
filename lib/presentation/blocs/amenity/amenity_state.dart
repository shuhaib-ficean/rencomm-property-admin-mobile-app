import 'package:equatable/equatable.dart';
import '../../../core/models/amenity_model.dart';

abstract class AmenityState extends Equatable {
  const AmenityState();

  @override
  List<Object?> get props => [];
}

class AmenityInitial extends AmenityState {}

class AmenityLoading extends AmenityState {}

class AmenitiesLoaded extends AmenityState {
  final List<AmenityModel> amenities;

  const AmenitiesLoaded(this.amenities);

  @override
  List<Object?> get props => [amenities];
}

class AmenitySuccess extends AmenityState {
  final String message;
  const AmenitySuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class AmenityError extends AmenityState {
  final String message;

  const AmenityError(this.message);

  @override
  List<Object?> get props => [message];
}
