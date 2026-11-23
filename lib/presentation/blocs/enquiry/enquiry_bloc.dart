import 'package:flutter_bloc/flutter_bloc.dart';
import 'enquiry_event.dart';
import 'enquiry_state.dart';
import '../../../core/services/enquiry_service.dart';
import '../../../core/utils/storage_helper.dart';

class EnquiryBloc extends Bloc<EnquiryEvent, EnquiryState> {
  final EnquiryService enquiryService;

  EnquiryBloc({required this.enquiryService}) : super(EnquiryInitial()) {
    on<LoadEnquiries>(_onLoadEnquiries);
    on<UpdateEnquiryStatus>(_onUpdateEnquiryStatus);
  }

  Future<void> _onLoadEnquiries(
    LoadEnquiries event,
    Emitter<EnquiryState> emit,
  ) async {
    emit(EnquiryLoading());
    try {
      final token = await StorageHelper.getToken() ?? '';
      
      final enquiries = await enquiryService.getEnquiries(token);
      emit(EnquiryLoaded(enquiries: enquiries));
    } catch (e) {
      emit(EnquiryError(message: e.toString()));
    }
  }

  Future<void> _onUpdateEnquiryStatus(
    UpdateEnquiryStatus event,
    Emitter<EnquiryState> emit,
  ) async {
    final currentState = state;
    if (currentState is EnquiryLoaded) {
      try {
        final token = await StorageHelper.getToken() ?? '';
        
        await enquiryService.updateEnquiryStatus(token, event.id, event.status);
        
        // Optimistically update the list
        final updatedEnquiries = currentState.enquiries.map((enquiry) {
          if (enquiry.id == event.id) {
            return enquiry.copyWith(status: event.status);
          }
          return enquiry;
        }).toList();
        
        emit(EnquiryLoaded(enquiries: updatedEnquiries));
      } catch (e) {
        emit(EnquiryError(message: e.toString()));
        emit(currentState); // revert back to previous loaded state
      }
    }
  }
}
