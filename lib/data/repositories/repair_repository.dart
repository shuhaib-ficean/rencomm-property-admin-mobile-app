import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/models/repair_model.dart';
import '../../core/network/api_client.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class RepairRepository {
  final ApiClient _apiClient;

  RepairRepository(this._apiClient);

  Future<List<RepairModel>> getRepairs({String? status}) async {
    try {
      final response = await _apiClient.dio.get(
        ApiConstants.repairs,
        queryParameters: status != null ? {'status': status} : null,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['repairs'];
        return data.map((json) => RepairModel.fromJson(json)).toList();
      } else {
        throw ServerFailure(response.data['message'] ?? 'Failed to fetch repairs');
      }
    } on DioException catch (e) {
      final message = e.response?.data is Map ? e.response?.data['message'] : null;
      throw ServerFailure(message ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> updateRepairStatus(String id, String status) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.repairs}/$id/status',
        data: {'status': status},
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ServerFailure(response.data['message'] ?? 'Failed to update status');
      }
    } on DioException catch (e) {
      final message = e.response?.data is Map ? e.response?.data['message'] : null;
      throw ServerFailure(message ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<RepairModel> createRepairRequest(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.repairs,
        data: data,
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return RepairModel.fromJson(response.data['repairRequest']);
      } else {
        throw ServerFailure(response.data['message'] ?? 'Failed to create repair request');
      }
    } on DioException catch (e) {
      final message = e.response?.data is Map ? e.response?.data['message'] : null;
      throw ServerFailure(message ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> assignStaff(String id, String staffId) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.repairs}/$id/assign',
        data: {'staffId': staffId},
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ServerFailure(response.data['message'] ?? 'Failed to assign staff');
      }
    } on DioException catch (e) {
      final message = e.response?.data is Map ? e.response?.data['message'] : null;
      throw ServerFailure(message ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> resolveRepairRequest(
    String id, {
    required String status,
    List<String>? completionImages,
    String? completionNotes,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.repairs}/$id/status',
        data: {
          'status': status,
          if (completionImages != null) 'completionImages': completionImages,
          if (completionNotes != null) 'completionNotes': completionNotes,
        },
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ServerFailure(response.data['message'] ?? 'Failed to resolve request');
      }
    } on DioException catch (e) {
      final message = e.response?.data is Map ? e.response?.data['message'] : null;
      throw ServerFailure(message ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
