import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../utils/debug_utils.dart';
import '../constants/api_constants.dart';
import '../utils/storage_helper.dart';

class ApiClient {
  late Dio _dio;
  final GlobalKey<NavigatorState> navigatorKey;
  bool _isLoaderShown = false;

  // For handling multiple concurrent 401s
  bool _isRefreshing = false;
  Completer<String?>? _refreshTokenCompleter;

  ApiClient({required String baseUrl, required this.navigatorKey}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 30),
        headers: ApiConstants.getHeaders(null),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageHelper.getToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            consoleLog('Token being sent: ${token.substring(0, 5)}...');
          } else {
            consoleLog('No token found in storage');
          }

          // Fix: If uploading file (FormData), remove default application/json header
          // so Dio can set the correct multipart/form-data boundary
          if (options.data is FormData) {
            options.headers.remove('Content-Type');
            options.contentType = null;
          }

          consoleLog(
              'Request: ${options.method} ${options.baseUrl}${options.path} ${options.queryParameters}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          consoleLog(
              'Response: ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) async {
          consoleLog('Response Status: ${error.response?.statusCode}, ErrorType: ${error.type}');

          // 1. Auto-Fallback Host Recovery on connection failure (e.g. USB unplugged or Wi-Fi switch)
          final isConnectionIssue = error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout ||
              (error.response == null && error.type == DioExceptionType.unknown);

          if (isConnectionIssue && error.requestOptions.extra['retried_fallback'] != true) {
            consoleLog('Connection failed to ${error.requestOptions.baseUrl}. Attempting auto-fallback host...');
            error.requestOptions.extra['retried_fallback'] = true;

            ApiConstants.toggleFallback();
            final fallbackBase = ApiConstants.baseUrl;
            _dio.options.baseUrl = fallbackBase;

            final requestOptions = error.requestOptions;
            requestOptions.baseUrl = fallbackBase;

            try {
              final cloneReq = await _dio.fetch(requestOptions);
              consoleLog('Auto-fallback successful to $fallbackBase');
              return handler.resolve(cloneReq);
            } catch (fallbackError) {
              consoleLog('Auto-fallback failed too: $fallbackError');
              return handler.next(error);
            }
          }

          if (error.response?.statusCode == 401) {
            final path = error.requestOptions.path;
            // Don't retry if it's login or refresh endpoint to avoid loops
            if (path.contains('login') || path.contains('refresh')) {
              return handler.next(error);
            }

            RequestOptions requestOptions = error.requestOptions;

            // If a refresh is already in progress, wait for it to complete
            if (_isRefreshing) {
              try {
                final newToken = await _refreshTokenCompleter?.future;
                if (newToken != null) {
                  // Retry with new token
                  requestOptions.headers['Authorization'] = 'Bearer $newToken';
                  final cloneReq = await _dio.fetch(requestOptions);
                  return handler.resolve(cloneReq);
                } else {
                  // Refresh failed for the primary request, so fail this one too
                  return handler.next(error);
                }
              } catch (e) {
                return handler.next(error);
              }
            }

            // Start refreshing
            _isRefreshing = true;
            _refreshTokenCompleter = Completer<String?>();

            try {
              final refreshToken = await StorageHelper.getRefreshToken();
              if (refreshToken == null) {
                _processLogout();
                _refreshTokenCompleter?.complete(null);
                _isRefreshing = false;
                return handler.next(error);
              }

              // Show full screen loader
              _showLoader();

              // Create a new Dio instance to avoid interceptor loop
              final refreshDio = Dio(BaseOptions(
                baseUrl: ApiConstants.baseUrl,
                connectTimeout: const Duration(seconds: 30),
                receiveTimeout: const Duration(seconds: 30),
                headers: ApiConstants.getHeaders(null),
              ));

              final response = await refreshDio.post(
                ApiConstants.refreshToken,
                data: {'refreshToken': refreshToken},
              );
              consoleLog('/auth/refresh');
              if (response.statusCode == 200) {
                final newAccessToken = response.data['accessToken'];
                await StorageHelper.saveToken(newAccessToken);

                // Complete the future so waiting requests can proceed
                _refreshTokenCompleter?.complete(newAccessToken);
                _isRefreshing = false;

                // Retry the original request
                requestOptions.headers['Authorization'] =
                    'Bearer $newAccessToken';
                final cloneReq = await _dio.fetch(requestOptions);
                return handler.resolve(cloneReq);
              } else {
                // Refresh failed
                _processLogout();
                _refreshTokenCompleter?.complete(null);
                _isRefreshing = false;
                return handler.next(error);
              }
            } catch (e) {
              // Error during refresh
              _processLogout();
              _refreshTokenCompleter?.completeError(e);
              _isRefreshing = false;
              return handler.next(error);
            } finally {
              // Hide loader
              _hideLoader();
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  Future<void> _processLogout() async {
    await StorageHelper.clearAll();
    navigatorKey.currentState
        ?.pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _showLoader() {
    if (_isLoaderShown) return;

    if (navigatorKey.currentContext != null) {
      _isLoaderShown = true;
      showDialog(
        context: navigatorKey.currentContext!,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: .5),
        builder: (context) {
          return const PopScope(
            canPop: false,
            child: Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            ),
          );
        },
      ).then((_) {
        _isLoaderShown = false;
      });
    }
  }

  void _hideLoader() {
    if (_isLoaderShown && navigatorKey.currentContext != null) {
      // Just checking if we can pop might specific to route stack, but generally safer to try pop
      // if we know we showed a dialog.
      Navigator.of(navigatorKey.currentContext!, rootNavigator: true).pop();
      _isLoaderShown = false;
    }
  }
}
