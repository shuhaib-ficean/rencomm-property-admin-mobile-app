import 'package:equatable/equatable.dart';

abstract class RepairEvent extends Equatable {
  const RepairEvent();

  @override
  List<Object?> get props => [];
}

class LoadRepairs extends RepairEvent {
  final String? status;

  const LoadRepairs({this.status});

  @override
  List<Object?> get props => [status];
}

class UpdateRepairStatus extends RepairEvent {
  final String id;
  final String status;

  const UpdateRepairStatus(this.id, this.status);

  @override
  List<Object?> get props => [id, status];
}

class CreateRepair extends RepairEvent {
  final Map<String, dynamic> data;

  const CreateRepair(this.data);

  @override
  List<Object?> get props => [data];
}

class AssignRepairStaff extends RepairEvent {
  final String id;
  final String staffId;

  const AssignRepairStaff(this.id, this.staffId);

  @override
  List<Object?> get props => [id, staffId];
}

class ResolveRepairRequest extends RepairEvent {
  final String id;
  final String status;
  final List<String>? completionImages;
  final String? completionNotes;

  const ResolveRepairRequest(
    this.id, {
    required this.status,
    this.completionImages,
    this.completionNotes,
  });

  @override
  List<Object?> get props => [id, status, completionImages, completionNotes];
}

