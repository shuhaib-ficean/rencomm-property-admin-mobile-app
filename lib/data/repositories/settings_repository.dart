import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../utils/debug_utils.dart';

class SettingsRepository {
  final ApiClient _apiClient;

  SettingsRepository(this._apiClient);

  /// Fetch system settings from backend
  Future<Map<String, dynamic>?> getSettings() async {
    try {
      final response = await _apiClient.dio.get(ApiConstants.settings);
      if (response.statusCode == 200 && response.data != null) {
        if (response.data['success'] == true && response.data['settings'] != null) {
          return response.data['settings'] as Map<String, dynamic>;
        }
      }
      return null;
    } on DioException catch (e) {
      consoleLog('DioException in getSettings: ${e.message}');
      return null;
    } catch (e) {
      consoleLog('Error in getSettings: $e');
      return null;
    }
  }

  /// Update system country and currency in backend
  Future<bool> updateRegionalSettings({
    required String countryCode,
    required String currencyCode,
    required String currencySymbol,
  }) async {
    try {
      final response = await _apiClient.dio.put(
        ApiConstants.settings,
        data: {
          'country': countryCode,
          'currency': {
            'code': currencyCode,
            'symbol': currencySymbol,
          },
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        consoleLog(
            'Backend settings updated successfully: country=$countryCode, currency=$currencyCode');
        return true;
      }
      return false;
    } on DioException catch (e) {
      consoleLog('DioException in updateRegionalSettings: ${e.message}');
      return false;
    } catch (e) {
      consoleLog('Error in updateRegionalSettings: $e');
      return false;
    }
  }
}
