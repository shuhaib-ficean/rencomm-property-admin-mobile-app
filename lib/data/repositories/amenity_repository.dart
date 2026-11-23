import 'package:dio/dio.dart';
import '../../core/models/amenity_model.dart';
import '../../core/network/api_client.dart';
import '../../utils/debug_utils.dart';

class AmenityRepository {
  final ApiClient _apiClient;

  AmenityRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<AmenityModel>> getAmenities() async {
    try {
      final response = await _apiClient.dio.get('/amenities');
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['amenities'] ?? [];
        return data.map((json) => AmenityModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      consoleLog('Error in getAmenities: $e');
      rethrow;
    }
  }

  Future<AmenityModel> createAmenity({
    required String name,
    required String category,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/amenities',
        data: {
          'name': name,
          'category': category,
        },
      );
      if (response.statusCode == 201 && response.data != null) {
        return AmenityModel.fromJson(response.data['amenity']);
      }
      throw Exception('Failed to create amenity');
    } catch (e) {
      consoleLog('Error in createAmenity: $e');
      rethrow;
    }
  }

  Future<AmenityModel> updateAmenity({
    required String id,
    String? name,
    String? category,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        '/amenities/$id',
        data: {
          if (name != null) 'name': name,
          if (category != null) 'category': category,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return AmenityModel.fromJson(response.data['amenity']);
      }
      throw Exception('Failed to update amenity');
    } catch (e) {
      consoleLog('Error in updateAmenity: $e');
      rethrow;
    }
  }

  Future<void> deleteAmenity(String id) async {
    try {
      final response = await _apiClient.dio.delete('/amenities/$id');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete amenity');
      }
    } catch (e) {
      consoleLog('Error in deleteAmenity: $e');
      rethrow;
    }
  }
}
