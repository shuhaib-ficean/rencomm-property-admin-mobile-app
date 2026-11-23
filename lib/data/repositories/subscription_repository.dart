import 'package:dio/dio.dart';
import '../../core/models/app_subscription_model.dart';
import '../../core/network/api_client.dart';
import '../../utils/debug_utils.dart';

class SubscriptionRepository {
  final ApiClient _apiClient;

  SubscriptionRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  Future<AppSubscriptionModel?> getMySubscription() async {
    try {
      final response = await _apiClient.dio.get('/subscriptions/my');
      if (response.statusCode == 200 && response.data != null) {
        if (response.data['subscription'] != null) {
          return AppSubscriptionModel.fromJson(response.data['subscription']);
        }
      }
      return null;
    } catch (e) {
      consoleLog('Error in getMySubscription: $e');
      rethrow;
    }
  }

  Future<List<SubscriptionPaymentModel>> getMyPayments() async {
    try {
      final response = await _apiClient.dio.get('/subscriptions/my/payments');
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['payments'] ?? [];
        return data.map((json) => SubscriptionPaymentModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      consoleLog('Error in getMyPayments: $e');
      rethrow;
    }
  }
}
