import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/models/payment_model.dart';
import '../../core/models/paginated_response.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/storage_helper.dart';

class PaymentRepository {
  final ApiClient _apiClient;

  PaymentRepository(this._apiClient);

  Future<PaginatedResponse<PaymentModel>> getPayments({
    int page = 1,
    int limit = 10,
    String? tenantId,
    String? propertyId,
    String? leaseId,
    String? startDate,
    String? endDate,
    String? receivedBy,
    String? type,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'limit': limit,
        if (tenantId != null) 'tenant': tenantId,
        if (propertyId != null) 'property': propertyId,
        if (leaseId != null) 'lease': leaseId,
        if (startDate != null) 'startDate': startDate,
        if (endDate != null) 'endDate': endDate,
        if (receivedBy != null) 'receivedBy': receivedBy,
        if (type != null) 'type': type,
      };
      final response = await _apiClient.dio.get(
        ApiConstants.payments,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return PaginatedResponse<PaymentModel>.fromJson(
          response.data,
          (json) => PaymentModel.fromJson(json),
          dataKey: 'payments',
        );
      } else {
        throw ServerFailure(
            response.data['message'] ?? 'Failed to fetch payments');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<PaymentModel> addPayment(Map<String, dynamic> paymentData) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.payments,
        data: paymentData,
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return PaymentModel.fromJson(response.data['payment']);
      } else {
        throw ServerFailure(
            response.data['message'] ?? 'Failed to add payment');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<String> getReceiptUrl(String paymentId) async {
    final token = await StorageHelper.getToken();
    return '${ApiConstants.baseUrl}${ApiConstants.paymentReceipt}/$paymentId?token=$token';
  }

  Future<PaymentModel> updatePayment(
      String id, Map<String, dynamic> paymentData) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.payments}/$id',
        data: paymentData,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return PaymentModel.fromJson(response.data['payment']);
      } else {
        throw ServerFailure(
            response.data['message'] ?? 'Failed to update payment');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> deletePayment(String id) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiConstants.payments}/$id',
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ServerFailure(
            response.data['message'] ?? 'Failed to delete payment');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
