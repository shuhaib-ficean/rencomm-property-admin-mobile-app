import 'package:equatable/equatable.dart';

abstract class AmenityEvent extends Equatable {
  const AmenityEvent();

  @override
  List<Object?> get props => [];
}

class LoadAmenities extends AmenityEvent {}

class CreateAmenity extends AmenityEvent {
  final String name;
  final String category;

  const CreateAmenity({required this.name, required this.category});

  @override
  List<Object?> get props => [name, category];
}

class UpdateAmenity extends AmenityEvent {
  final String id;
  final String? name;
  final String? category;

  const UpdateAmenity({required this.id, this.name, this.category});

  @override
  List<Object?> get props => [id, name, category];
}

class DeleteAmenity extends AmenityEvent {
  final String id;

  const DeleteAmenity(this.id);

  @override
  List<Object?> get props => [id];
}
