import 'package:dio/dio.dart';
import '../../core/errors/failures.dart';
import '../../core/network/api_client.dart';

class NotificationRepository {
  // ignore: unused_field
  final ApiClient _apiClient;

  NotificationRepository(this._apiClient);

  Future<List<dynamic>> getNotifications() async {
    try {
      final response = await _apiClient.dio.get('/notifications');
      return response.data['notifications'] ?? [];
    } on DioException catch (e) {
      final message =
          e.response?.data is Map ? e.response?.data['message'] : null;
      throw ServerFailure(message ??
          'Unable to connect to the server. Please ensure the backend is running and you are connected.');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _apiClient.dio.put('/notifications/$id/read');
    } on DioException catch (e) {
      final message =
          e.response?.data is Map ? e.response?.data['message'] : null;
      throw ServerFailure(message ?? 'Failed to mark notification as read');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiClient.dio.put('/notifications/read-all');
    } on DioException catch (e) {
      final message =
          e.response?.data is Map ? e.response?.data['message'] : null;
      throw ServerFailure(
          message ?? 'Failed to mark all notifications as read');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
