import 'package:equatable/equatable.dart';
import '../../../core/models/property_model.dart';

abstract class EnquiryState extends Equatable {
  const EnquiryState();
  
  @override
  List<Object> get props => [];
}

class EnquiryInitial extends EnquiryState {}

class EnquiryLoading extends EnquiryState {}

class EnquiryLoaded extends EnquiryState {
  final List<EnquiryModel> enquiries;

  const EnquiryLoaded({required this.enquiries});

  @override
  List<Object> get props => [enquiries];
}

class EnquiryError extends EnquiryState {
  final String message;

  const EnquiryError({required this.message});

  @override
  List<Object> get props => [message];
}

class EnquiryStatusUpdating extends EnquiryState {}

class EnquiryStatusUpdated extends EnquiryState {
  final EnquiryModel enquiry;
  
  const EnquiryStatusUpdated({required this.enquiry});
  
  @override
  List<Object> get props => [enquiry];
}
