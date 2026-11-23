import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/models/role_model.dart';
import '../../core/network/api_client.dart';

class RoleRepository {
  final ApiClient _apiClient;

  RoleRepository(this._apiClient);

  Future<List<RoleModel>> getRoles() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.roles);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> rolesJson = response.data['data'];
        return rolesJson.map((json) => RoleModel.fromJson(json)).toList();
      } else {
        throw ServerFailure(
            response.data['message'] ?? 'Failed to fetch roles');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<RoleModel> createRole(Map<String, dynamic> roleData) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.roles,
        data: roleData,
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return RoleModel.fromJson(response.data['data']);
      } else {
        throw ServerFailure(
            response.data['message'] ?? 'Failed to create role');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<RoleModel> updateRole(String id, Map<String, dynamic> roleData) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.roles}/$id',
        data: roleData,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return RoleModel.fromJson(response.data['data']);
      } else {
        throw ServerFailure(
            response.data['message'] ?? 'Failed to update role');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> deleteRole(String id) async {
    try {
      final response = await _apiClient.dio.delete('${ApiConstants.roles}/$id');

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ServerFailure(
            response.data['message'] ?? 'Failed to delete role');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
