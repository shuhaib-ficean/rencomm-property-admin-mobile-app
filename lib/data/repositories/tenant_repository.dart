import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../core/models/lease_model.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/models/tenant_model.dart';
import '../../core/models/paginated_response.dart';
import '../../core/network/api_client.dart';

class TenantRepository {
  final ApiClient _apiClient;

  TenantRepository(this._apiClient);

  Future<PaginatedResponse<TenantModel>> getTenants({
    int page = 1,
    int limit = 10,
    String? status,
    String? search,
    String? propertyId,
    String? createdById,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
        if (search != null) 'search': search,
        if (propertyId != null) 'propertyId': propertyId,
        if (createdById != null) 'createdById': createdById,
      };

      final response = await _apiClient.dio.get(
        ApiConstants.tenants,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return PaginatedResponse<TenantModel>.fromJson(
          response.data,
          (json) => TenantModel.fromJson(json),
          dataKey: 'tenants',
        );
      } else {
        throw ServerFailure(
          response.data['message'] ?? 'Failed to fetch tenants',
        );
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<TenantModel> getTenantById(String id) async {
    try {
      final response = await _apiClient.dio.get('${ApiConstants.tenants}/$id');

      if (response.statusCode == 200 && response.data['success'] == true) {
        return TenantModel.fromJson(response.data['tenant']);
      } else {
        throw ServerFailure(
          response.data['message'] ?? 'Failed to fetch tenant',
        );
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  String _extractErrorMessage(DioException e, {String fallback = 'Network error'}) {
    final data = e.response?.data;
    if (data is Map) {
      final err = data['error']?.toString().trim();
      final msg = data['message']?.toString().trim();
      if (err != null &&
          err.isNotEmpty &&
          !err.toLowerCase().startsWith('error creating') &&
          !err.toLowerCase().startsWith('error updating')) {
        return err;
      }
      if (msg != null &&
          msg.isNotEmpty &&
          !msg.toLowerCase().startsWith('error creating') &&
          !msg.toLowerCase().startsWith('error updating')) {
        return msg;
      }
      if (err != null && err.isNotEmpty) return err;
      if (msg != null && msg.isNotEmpty) return msg;
    }
    return e.response?.statusMessage ?? e.message ?? fallback;
  }

  Future<TenantModel> createTenant(Map<String, dynamic> tenantData) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.tenants,
        data: tenantData,
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        return TenantModel.fromJson(response.data['tenant']);
      } else {
        throw ServerFailure(
          response.data['message'] ?? 'Failed to create tenant',
        );
      }
    } on DioException catch (e) {
      throw ServerFailure(_extractErrorMessage(e, fallback: 'Failed to create tenant'));
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(e.toString());
    }
  }

  Future<TenantModel> updateTenant(
    String id,
    Map<String, dynamic> tenantData,
  ) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.tenants}/$id',
        data: tenantData,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return TenantModel.fromJson(response.data['tenant']);
      } else {
        throw ServerFailure(
          response.data['message'] ?? 'Failed to update tenant',
        );
      }
    } on DioException catch (e) {
      throw ServerFailure(_extractErrorMessage(e, fallback: 'Failed to update tenant'));
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(e.toString());
    }
  }

  Future<void> deleteTenant(String id) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiConstants.tenants}/$id',
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ServerFailure(
          response.data['message'] ?? 'Failed to delete tenant',
        );
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> addTenantAmenity(
      String tenantId, String description, DateTime providedAt) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.tenants}/$tenantId/amenities',
        data: {
          'description': description,
          'providedAt': providedAt.toUtc().toIso8601String(),
        },
      );

      if (response.statusCode != 201 || response.data['success'] != true) {
        throw ServerFailure(
          response.data['message'] ?? 'Failed to add amenity',
        );
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> updateTenantAmenity(String tenantId, String amenityId,
      String description, DateTime providedAt) async {
    try {
      final response = await _apiClient.dio.put(
        '${ApiConstants.tenants}/$tenantId/amenities/$amenityId',
        data: {
          'description': description,
          'providedAt': providedAt.toUtc().toIso8601String(),
        },
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ServerFailure(
          response.data['message'] ?? 'Failed to update amenity',
        );
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> removeTenantAmenity(String tenantId, String amenityId) async {
    try {
      final response = await _apiClient.dio.delete(
        '${ApiConstants.tenants}/$tenantId/amenities/$amenityId',
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ServerFailure(
          response.data['message'] ?? 'Failed to remove amenity',
        );
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> assignProperty(String tenantId, String propertyId) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.tenants}/$tenantId/assign-property',
        data: {'propertyId': propertyId},
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ServerFailure(
          response.data['message'] ?? 'Failed to assign property',
        );
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> assignRoom(
    String tenantId,
    String roomId, {
    double? rentAmount,
    double? securityDeposit,
    String? startDate,
    bool? isRecurring,
    int? durationDays,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.tenants}/$tenantId/assign-room',
        data: {
          'roomId': roomId,
          if (rentAmount != null) 'rentAmount': rentAmount,
          if (securityDeposit != null) 'securityDeposit': securityDeposit,
          if (startDate != null) 'startDate': startDate,
          if (isRecurring != null) 'isRecurring': isRecurring,
          if (durationDays != null) 'durationDays': durationDays,
        },
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ServerFailure(
          response.data['message'] ?? 'Failed to assign room',
        );
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> unassignRoom(
    String tenantId,
    String roomId,
    String propertyId,
  ) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.tenants}/$tenantId/unassign-room',
        data: {'roomId': roomId, 'propertyId': propertyId},
      );

      if (response.statusCode != 200 || response.data['success'] != true) {
        throw ServerFailure(
          response.data['message'] ?? 'Failed to unassign room',
        );
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  /// Upload document images for a tenant. [documentType] is one of:
  ///   passportFrontImages, passportBackImages, qatarIdImages.
  /// Returns list of uploaded image URLs.
  Future<List<String>> uploadTenantDocumentFiles(
    String tenantId,
    String documentType,
    List<File> files,
  ) async {
    if (files.isEmpty) return [];
    try {
      // Map frontend keys to backend keys
      String? backendKey;
      if (documentType == 'passportFrontImages') {
        backendKey = 'passportFrontDoc';
      } else if (documentType == 'passportBackImages') {
        backendKey = 'passportBackDoc';
      } else if (documentType == 'qatarIdImages') {
        backendKey = 'qatarIdDoc';
      }

      if (backendKey == null) return [];

      final List<MapEntry<String, MultipartFile>> formDataFiles = [];

      for (var file in files) {
        // Determine content type
        final extension = file.path.split('.').last.toLowerCase();
        MediaType? mediaType;
        if (extension == 'pdf') {
          mediaType = MediaType('application', 'pdf');
        } else if (['jpg', 'jpeg'].contains(extension)) {
          mediaType = MediaType('image', 'jpeg');
        } else if (extension == 'png') {
          mediaType = MediaType('image', 'png');
        } else if (['heic', 'heif'].contains(extension)) {
          mediaType = MediaType('image', 'heic');
        }

        final multipartFile = await MultipartFile.fromFile(
          file.path,
          contentType: mediaType,
        );
        formDataFiles.add(MapEntry(backendKey, multipartFile));
      }

      final formData = FormData();
      formData.files.addAll(formDataFiles);

      // Use POST /tenants/:id/documents
      final response = await _apiClient.dio.post(
        '${ApiConstants.tenants}/$tenantId/documents',
        data: formData,
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 30),
          contentType:
              null, // Override default application/json to let FormData set multipart/form-data
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['tenant'] != null) {
          final tenant = TenantModel.fromJson(data['tenant']);
          if (documentType == 'passportFrontImages' &&
              tenant.passportFrontImages != null) {
            return tenant.passportFrontImages!;
          }
          if (documentType == 'passportBackImages' &&
              tenant.passportBackImages != null) {
            return tenant.passportBackImages!;
          }
          if (documentType == 'qatarIdImages' && tenant.qatarIdImages != null) {
            return tenant.qatarIdImages!;
          }
        }
        return [];
      } else {
        throw ServerFailure(
          response.data['message'] ?? 'Failed to upload documents',
        );
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<void> addTenantPayment({
    required String tenantId,
    required double amount,
    required DateTime paymentDate,
    String? notes,
    String? leaseId,
    String? paymentMethod,
    String? transactionId,
    bool isSecurityDeposit = false,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '${ApiConstants.baseUrl}/tenant-payments',
        data: {
          'tenantId': tenantId,
          'amount': amount,
          'paymentDate': paymentDate.toIso8601String(),
          'notes': notes,
          if (leaseId != null) 'leaseId': leaseId,
          if (paymentMethod != null) 'paymentMethod': paymentMethod,
          if (transactionId != null) 'transactionId': transactionId,
          'isSecurityDeposit': isSecurityDeposit,
        },
      );

      if (response.statusCode != 201 || response.data['success'] != true) {
        throw ServerFailure(
          response.data['message'] ?? 'Failed to add payment',
        );
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<Map<String, dynamic>> getTenantPayments({
    required String tenantId,
    DateTime? startDate,
    DateTime? endDate,
    String? leaseId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = {
        if (startDate != null) 'startDate': startDate.toUtc().toIso8601String(),
        if (endDate != null) 'endDate': endDate.toUtc().toIso8601String(),
        if (leaseId != null) 'leaseId': leaseId,
        'page': page,
        'limit': limit,
      };

      final response = await _apiClient.dio.get(
        '${ApiConstants.baseUrl}/tenant-payments/$tenantId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        return {
          'payments': response.data['payments'],
          'totalPaid': (response.data['totalPaid'] as num? ?? 0).toDouble(),
          'totalAmount': (response.data['totalAmount'] as num? ?? 0).toDouble(),
          'totalPending':
              (response.data['totalPending'] as num? ?? 0).toDouble(),
          'currentPage': response.data['currentPage'] ?? 1,
          'totalPages': response.data['totalPages'] ?? 1,
          'total': response.data['total'] ?? 0,
        };
      } else {
        throw ServerFailure(
          response.data['message'] ?? 'Failed to fetch payments',
        );
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  Future<List<LeaseModel>> getLeasesByTenantId(String tenantId) async {
    try {
      final response = await _apiClient.dio.get(
        '${ApiConstants.tenants}/$tenantId/leases',
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> leasesJson = response.data['leases'];
        return leasesJson.map((json) => LeaseModel.fromJson(json)).toList();
      } else {
        throw ServerFailure(
          response.data['message'] ?? 'Failed to fetch leases',
        );
      }
    } on DioException catch (e) {
      throw ServerFailure(e.response?.data['message'] ?? 'Network error');
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }
}
