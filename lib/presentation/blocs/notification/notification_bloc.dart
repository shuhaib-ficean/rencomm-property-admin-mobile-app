import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../core/errors/failures.dart';
import '../../../data/repositories/notification_repository.dart';

// Events
abstract class NotificationEvent extends Equatable {
  const NotificationEvent();
  @override
  List<Object> get props => [];
}

class LoadNotifications extends NotificationEvent {}

class MarkNotificationRead extends NotificationEvent {
  final String id;
  const MarkNotificationRead(this.id);
  @override
  List<Object> get props => [id];
}

class MarkAllNotificationsRead extends NotificationEvent {}

// States
abstract class NotificationState extends Equatable {
  const NotificationState();
  @override
  List<Object> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<dynamic> notifications;
  const NotificationLoaded(this.notifications);
  @override
  List<Object> get props => [notifications];
}

class NotificationError extends NotificationState {
  final String message;
  const NotificationError(this.message);
  @override
  List<Object> get props => [message];
}

// Bloc
class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository _notificationRepository;

  NotificationBloc(this._notificationRepository)
      : super(NotificationInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<MarkNotificationRead>(_onMarkNotificationRead);
    on<MarkAllNotificationsRead>(_onMarkAllNotificationsRead);
  }

  String _getErrorMessage(dynamic e) {
    if (e is ServerFailure) return e.message;
    final str = e.toString();
    return str.replaceFirst(RegExp(r'^Exception:\s*'), '');
  }

  Future<void> _onLoadNotifications(
      LoadNotifications event, Emitter<NotificationState> emit) async {
    emit(NotificationLoading());
    try {
      final notifications = await _notificationRepository.getNotifications();
      emit(NotificationLoaded(notifications));
    } catch (e) {
      emit(NotificationError(_getErrorMessage(e)));
    }
  }

  Future<void> _onMarkNotificationRead(
      MarkNotificationRead event, Emitter<NotificationState> emit) async {
    try {
      await _notificationRepository.markAsRead(event.id);
      add(LoadNotifications());
    } catch (e) {
      emit(NotificationError(_getErrorMessage(e)));
    }
  }

  Future<void> _onMarkAllNotificationsRead(
      MarkAllNotificationsRead event, Emitter<NotificationState> emit) async {
    try {
      await _notificationRepository.markAllAsRead();
      add(LoadNotifications());
    } catch (e) {
      emit(NotificationError(_getErrorMessage(e)));
    }
  }
}
