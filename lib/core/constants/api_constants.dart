class ApiConstants {
  // Base URL - Update this with your backend URL
  // Use 192.168.1.3 for Physical Device connected to the same Wi-Fi
  // Primary: Direct USB reverse tunnel (127.0.0.1:5001)
  static const String usbServerUrl = 'http://127.0.0.1:5001';
  // Fallback: Local Wi-Fi LAN IP (192.168.1.6:5001)
  static const String wifiServerUrl = 'http://192.168.1.6:5001';

  static String serverUrl = usbServerUrl;

  static String get baseUrl => '$serverUrl/api';

  static void toggleFallback() {
    if (serverUrl == usbServerUrl) {
      serverUrl = wifiServerUrl;
    } else {
      serverUrl = usbServerUrl;
    }
  }

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String getMe = '/auth/me';
  static const String refreshToken = '/auth/refresh';

  // Property endpoints
  static const String properties = '/properties';

  // Tenant endpoints
  static const String tenants = '/tenants';
  static String tenantDocuments(String tenantId) =>
      '/tenants/$tenantId/documents';

  // Staff endpoints
  static const String staff = '/staff';
  static const String roles = '/roles';

  // Payment endpoints
  static const String payments = '/tenant-payments';
  static const String paymentReceipt = '/tenant-payments/receipt';

  // Repair & Maintenance endpoints
  static const String repairs = '/maintenance';

  // Analytics endpoints
  static const String analyticsStaffCollections =
      '/analytics/staff-collections';
  static const String analyticsTenantSummary = '/analytics/tenant-summary';
  static const String analyticsPaymentHistory = '/analytics/payment-history';
  static const String analyticsPropertyAnalytics =
      '/analytics/property-analytics';

  // Settings endpoints
  static const String settings = '/settings';
  static const String settingsLogo = '/settings/logo';

  // Headers
  static Map<String, String> getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
