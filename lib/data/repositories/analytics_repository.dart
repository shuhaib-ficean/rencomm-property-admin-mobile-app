import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/models/analytics_model.dart';
import '../../core/models/property_analytics_model.dart';
import '../../core/network/api_client.dart';

class AnalyticsRepository {
  final ApiClient _apiClient;

  AnalyticsRepository(this._apiClient);

  Future<List<StaffCollectionModel>> getStaffCollections({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };

      final response = await _apiClient.dio.get(
        ApiConstants.analyticsStaffCollections,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> list = response.data['collections'];
        return list.map((json) => StaffCollectionModel.fromJson(json)).toList();
      } else {
        throw ServerFailure(
            response.data['message'] ?? 'Failed to fetch staff collections');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<TenantSummaryModel> getTenantSummary({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };

      final response = await _apiClient.dio.get(
        ApiConstants.analyticsTenantSummary,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return TenantSummaryModel.fromJson(response.data['summary']);
      } else {
        throw ServerFailure(
            response.data['message'] ?? 'Failed to fetch tenant summary');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<List<PaymentHistoryItemModel>> getPaymentHistory({
    int page = 1,
    int limit = 20,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'limit': limit,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };

      final response = await _apiClient.dio.get(
        ApiConstants.analyticsPaymentHistory,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> list = response.data['payments'];
        return list
            .map((json) => PaymentHistoryItemModel.fromJson(json))
            .toList();
      } else {
        throw ServerFailure(
            response.data['message'] ?? 'Failed to fetch payment history');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<List<PropertyAnalyticsModel>> getPropertyAnalytics({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = {
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
      };

      final response = await _apiClient.dio.get(
        ApiConstants.analyticsPropertyAnalytics,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> list = response.data['analytics'];
        return list
            .map((json) => PropertyAnalyticsModel.fromJson(json))
            .toList();
      } else {
        throw ServerFailure(
            response.data['message'] ?? 'Failed to fetch property analytics');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
