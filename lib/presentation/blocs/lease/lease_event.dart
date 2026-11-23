import 'package:equatable/equatable.dart';

abstract class LeaseEvent extends Equatable {
  const LeaseEvent();

  @override
  List<Object?> get props => [];
}

class CreateLease extends LeaseEvent {
  final String tenantId;
  final String roomId;
  final double rentAmount;
  final double securityDeposit;
  final String startDate;
  final bool isRecurring;
  final int? durationDays;

  const CreateLease({
    required this.tenantId,
    required this.roomId,
    required this.rentAmount,
    required this.securityDeposit,
    required this.startDate,
    required this.isRecurring,
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
