import 'dart:async'; // Add this import

import 'package:equatable/equatable.dart';

abstract class PropertyEvent extends Equatable {
  const PropertyEvent();

  @override
  List<Object?> get props => [];
}

class LoadProperties extends PropertyEvent {
  final bool isRefresh;
  final bool isLoadMore;
  final int limit;
  final String? search;
  final String? createdById;
  final bool? vacantOnly;

  const LoadProperties({
    this.isRefresh = false,
    this.isLoadMore = false,
    this.limit = 10,
    this.search,
    this.createdById,
    this.vacantOnly,
  });

  @override
  List<Object?> get props =>
      [isRefresh, isLoadMore, limit, search ?? '', createdById ?? '', vacantOnly];
}

class RefreshProperties extends PropertyEvent {
  final Completer<void>? completer;

  const RefreshProperties({this.completer});

  @override
  List<Object?> get props => [completer];
}

class CreateProperty extends PropertyEvent {
  final Map<String, dynamic> propertyData;
  const CreateProperty(this.propertyData);
  @override
  List<Object?> get props => [propertyData];
}

class UpdateProperty extends PropertyEvent {
  final String id;
  final Map<String, dynamic> propertyData;
  const UpdateProperty(this.id, this.propertyData);
  @override
  List<Object?> get props => [id, propertyData];
}

class DeleteProperty extends PropertyEvent {
  final String id;
  const DeleteProperty(this.id);
  @override
  List<Object?> get props => [id];
}

class UpdateRoom extends PropertyEvent {
  final String propertyId;
  final String roomId;
  final Map<String, dynamic> roomData;
  const UpdateRoom({
    required this.propertyId,
    required this.roomId,
    required this.roomData,
  });
  @override
  List<Object?> get props => [propertyId, roomId, roomData];
}

class AddFloor extends PropertyEvent {
  final String propertyId;
  final String floorNumber;
  const AddFloor({required this.propertyId, required this.floorNumber});
  @override
  List<Object?> get props => [propertyId, floorNumber];
}

class UpdateFloor extends PropertyEvent {
  final String floorId;
  final String floorNumber;
  const UpdateFloor({required this.floorId, required this.floorNumber});
  @override
  List<Object?> get props => [floorId, floorNumber];
}

class DeleteFloor extends PropertyEvent {
  final String floorId;
  const DeleteFloor(this.floorId);
  @override
  List<Object?> get props => [floorId];
}

class AddRoom extends PropertyEvent {
  final String propertyId;
  final Map<String, dynamic> roomData;
  const AddRoom({required this.propertyId, required this.roomData});
  @override
  List<Object?> get props => [propertyId, roomData];
}

class DeleteRoom extends PropertyEvent {
  final String roomId;
  const DeleteRoom(this.roomId);
  @override
  List<Object?> get props => [roomId];
}

