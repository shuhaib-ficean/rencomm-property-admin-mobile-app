import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/models/user_model.dart';
import '../../core/models/paginated_response.dart';
import '../../core/network/api_client.dart';

class StaffRepository {
  final ApiClient _apiClient;

  StaffRepository(this._apiClient);

  Future<PaginatedResponse<UserModel>> getStaff({
    int page = 1,
    int limit = 10,
    bool? isActive,
    bool? includeAdmin,
    String? search,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'limit': limit,
        if (isActive != null) 'isActive': isActive,
        if (includeAdmin != null) 'includeAdmin': includeAdmin,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final response = await _apiClient.dio.get(
        ApiConstants.staff,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return PaginatedResponse<UserModel>.fromJson(
          response.data,
          (json) => UserModel.fromJson(json),
          dataKey: 'staff',
        );
      } else {
        throw ServerFailure(
            response.data['message'] ?? 'Failed to fetch staff');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<UserModel> getStaffById(String id) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.staff}/$id');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return UserModel.fromJson(response.data['staff']);
      } else {
        throw ServerFailure(
            response.data['message'] ?? 'Failed to fetch staff details');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<UserModel> createStaff(Map<String, dynamic> staffData) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.staff,
        data: staffData,
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return UserModel.fromJson(response.data['staff']);
      } else {
        throw ServerFailure(
            response.data['message'] ?? 'Failed to create staff');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<UserModel> updateStaff(
      String id, Map<String, dynamic> staffData) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.staff}/$id',
        data: staffData,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return UserModel.fromJson(response.data['staff']);
      } else {
        throw ServerFailure(
            response.data['message'] ?? 'Failed to update staff');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> deleteStaff(String id) async {
    try {
      final response = await _apiClient.dio.delete('${ApiConstants.staff}/$id');

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ServerFailure(
            response.data['message'] ?? 'Failed to delete staff');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
