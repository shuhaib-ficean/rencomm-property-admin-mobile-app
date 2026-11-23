import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../core/constants/api_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/models/user_model.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/storage_helper.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _apiClient;

  AuthRepositoryImpl(this._apiClient);

  @override
  Future<Either<Failure, User>> register(String name, String email, String password, String? phone) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          if (phone != null) 'phone': phone,
          'role': 'admin', // For property admin app, they register as admin
        },
      );

      if (response.statusCode == 201 && response.data['success'] == true) {
        final token = response.data['accessToken'];
        final refreshToken = response.data['refreshToken'];
        final userModel = UserModel.fromJson(response.data['user']);
        final user = _mapModelToEntity(userModel);

        // Save token and user
        await StorageHelper.saveToken(token);
        if (refreshToken != null) {
          await StorageHelper.saveRefreshToken(refreshToken);
        }
        await StorageHelper.saveUser(userModel);

        return Right(user);
      } else {
        return Left(ServerFailure(response.data['message'] ?? 'Registration failed'));
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return Left(ServerFailure(
          e.response?.data['message'] ?? 'Registration failed',
        ));
      } else {
        return const Left(
            NetworkFailure('Network error. Please check your connection.'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> login(String email, String password) async {
    try {
      final response = await _apiClient.dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final token = response.data['accessToken'];
        final refreshToken = response.data['refreshToken'];
        final userModel = UserModel.fromJson(response.data['user']);
        final user = _mapModelToEntity(userModel);

        if (user.role.toLowerCase() == 'customer' ||
            user.role.toLowerCase() == 'tenant') {
          return const Left(AuthenticationFailure(
            'Access denied. Customer accounts cannot log in to the Property Admin app. Please use the Customer App.',
          ));
        }

        // Save token and user
        await StorageHelper.saveToken(token);
        if (refreshToken != null) {
          await StorageHelper.saveRefreshToken(refreshToken);
        }
        await StorageHelper.saveUser(userModel);

        return Right(user);
      } else {
        return Left(ServerFailure(response.data['message'] ?? 'Login failed'));
      }
    } on DioException catch (e) {
      if (e.response != null) {
        return Left(ServerFailure(
          e.response?.data['message'] ?? 'Login failed',
        ));
      } else {
        return const Left(
            NetworkFailure('Network error. Please check your connection.'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, User>> getCurrentUser() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.getMe);

      if (response.statusCode == 200 && response.data['success'] == true) {
        final userModel = UserModel.fromJson(response.data['user']);
        if (userModel.role.toLowerCase() == 'customer' ||
            userModel.role.toLowerCase() == 'tenant') {
          await StorageHelper.clearAll();
          return const Left(AuthenticationFailure(
            'Access denied. Customer accounts cannot access the Property Admin app.',
          ));
        }
        await StorageHelper.saveUser(userModel);
        return Right(_mapModelToEntity(userModel));
      } else {
        return const Left(ServerFailure('Failed to get user data'));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await StorageHelper.clearAll();
        return const Left(
            AuthenticationFailure('Session expired. Please login again.'));
      }
      return Left(
          ServerFailure(e.response?.data['message'] ?? 'Failed to get user'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await _apiClient.dio.post(ApiConstants.logout);
      return const Right(null);
    } catch (e) {
      // Even if API call fails, clear local storage
      return const Right(null);
    } finally {
      await StorageHelper.clearAll();
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await StorageHelper.getToken();
    return token != null && token.isNotEmpty;
  }

  User _mapModelToEntity(UserModel model) {
    return User(
      id: model.id,
      name: model.name,
      email: model.email,
      role: model.role,
      permissions: model.permissions,
      employeeId: model.employeeId,
      department: model.department,
      isActive: model.isActive,
    );
  }
}
