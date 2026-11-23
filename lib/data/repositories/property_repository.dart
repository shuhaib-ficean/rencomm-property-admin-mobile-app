import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/models/property_model.dart';
import '../../core/models/paginated_response.dart';
import '../../core/network/api_client.dart';

class PropertyRepository {
  final ApiClient _apiClient;

  PropertyRepository(this._apiClient);

  Future<PaginatedResponse<PropertyModel>> getProperties({
    int page = 1,
    int limit = 10,
    String? search,
    String? createdById,
    bool? vacantOnly,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'limit': limit,
        if (search != null) 'search': search,
        if (createdById != null) 'createdById': createdById,
        if (vacantOnly == true) 'vacant': 'true',
      };

      final response = await _apiClient.dio.get(
        ApiConstants.properties,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return PaginatedResponse<PropertyModel>.fromJson(
          response.data,
          (json) => PropertyModel.fromJson(json),
          dataKey: 'properties',
        );
      } else {
        throw ServerFailure(
            response.data['message'] ?? 'Failed to fetch properties');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<PropertyModel> getPropertyById(String id) async {
    try {
      final response =
          await _apiClient.dio.get('${ApiConstants.properties}/$id');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return PropertyModel.fromJson(response.data['property']);
      } else {
        throw ServerFailure(
            response.data['message'] ?? 'Failed to fetch property');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<PropertyModel> createProperty(
      Map<String, dynamic> propertyData) async {
    try {
      dynamic dataPayload = propertyData;

      if (propertyData.containsKey('images') && propertyData['images'] is List && (propertyData['images'] as List).isNotEmpty) {
        final List<XFile> images = List<XFile>.from(propertyData['images']);
        final Map<String, dynamic> formDataMap = {};
        
        propertyData.forEach((key, value) {
          if (key != 'images') {
            if (value is List || value is Map) {
              formDataMap[key] = jsonEncode(value);
            } else {
              formDataMap[key] = value;
            }
          }
        });

        final formData = FormData.fromMap(formDataMap);
        for (var image in images) {
          formData.files.add(MapEntry(
            'images',
            await MultipartFile.fromFile(image.path, filename: image.name),
          ));
        }
        dataPayload = formData;
      } else {
        propertyData.remove('images');
      }

      final response = await _apiClient.dio.post(
        ApiConstants.properties,
        data: dataPayload,
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return PropertyModel.fromJson(response.data['property']);
      } else {
        throw ServerFailure(
            response.data['message'] ?? 'Failed to create property');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<PropertyModel> updateProperty(
      String id, Map<String, dynamic> propertyData) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.properties}/$id',
        data: propertyData,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return PropertyModel.fromJson(response.data['property']);
      } else {
        throw ServerFailure(
            response.data['message'] ?? 'Failed to update property');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> deleteProperty(String id) async {
    try {
      final response =
          await _apiClient.dio.delete('${ApiConstants.properties}/$id');

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ServerFailure(
            response.data['message'] ?? 'Failed to delete property');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> updateRoom(String roomId, Map<String, dynamic> roomData) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.properties}/rooms/$roomId',
        data: roomData,
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ServerFailure(
            response.data['message'] ?? 'Failed to update room');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> addFloor(String propertyId, String floorNumber) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.properties}/$propertyId/floors',
        data: {'number': floorNumber},
      );

      if ((response.statusCode != 201 && response.statusCode != 200) ||
          response.data['success'] != true) {
        throw ServerFailure(response.data['message'] ?? 'Failed to add floor');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> updateFloor(String floorId, String floorNumber) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.properties}/floors/$floorId',
        data: {'number': floorNumber},
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ServerFailure(
            response.data['message'] ?? 'Failed to update floor');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> deleteFloor(String floorId) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiConstants.properties}/floors/$floorId',
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ServerFailure(
            response.data['message'] ?? 'Failed to delete floor');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> addRoom(String propertyId, Map<String, dynamic> roomData) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.properties}/$propertyId/rooms',
        data: roomData,
      );

      if ((response.statusCode != 201 && response.statusCode != 200) ||
          response.data['success'] != true) {
        throw ServerFailure(response.data['message'] ?? 'Failed to add room');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiConstants.properties}/rooms/$roomId',
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ServerFailure(
            response.data['message'] ?? 'Failed to delete room');
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
