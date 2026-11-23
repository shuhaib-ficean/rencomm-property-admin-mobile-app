import 'package:equatable/equatable.dart';

abstract class EnquiryEvent extends Equatable {
  const EnquiryEvent();

  @override
  List<Object> get props => [];
}

class LoadEnquiries extends EnquiryEvent {}

class UpdateEnquiryStatus extends EnquiryEvent {
  final String id;
  final String status;

  const UpdateEnquiryStatus({required this.id, required this.status});

  @override
  List<Object> get props => [id, status];
}
