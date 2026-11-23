import 'package:dio/dio.dart';
import '../../core/models/lease_model.dart';
import '../../core/network/api_client.dart';
import '../../utils/debug_utils.dart';

class LeaseRepository {
  final ApiClient _apiClient;

  LeaseRepository(this._apiClient);

  Future<List<LeaseModel>> getLeasesByTenantId(String tenantId) async {
    try {
      final response = await _apiClient.dio.get('/tenants/$tenantId/leases');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['leases'] ?? [];
        return data.map((json) => LeaseModel.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      consoleLog('DioException in getLeasesByTenantId: ${e.message}');
      rethrow;
    } catch (e) {
      consoleLog('Error in getLeasesByTenantId: $e');
      rethrow;
    }
  }

  Future<void> createLease({
    required String tenantId,
    required String roomId,
    required double rentAmount,
    required double securityDeposit,
    required String startDate,
    required bool isRecurring,
    int? durationDays,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/tenants/$tenantId/assign-room',
        data: {
          'roomId': roomId,
          'rentAmount': rentAmount,
          'securityDeposit': securityDeposit,
          'startDate': startDate,
          'isRecurring': isRecurring.toString(),
          if (durationDays != null) 'durationDays': durationDays,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to create lease');
      }
    } catch (e) {
      consoleLog('Error in createLease (assignToRoom): $e');
      rethrow;
    }
  }
}
