import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/property_model.dart';
import '../constants/api_constants.dart';

class EnquiryService {
  final String baseUrl = ApiConstants.baseUrl;

  Future<List<EnquiryModel>> getEnquiries(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/enquiries'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final List<dynamic> enquiriesList = data['enquiries'];
        return enquiriesList.map((e) => EnquiryModel.fromJson(e)).toList();
      }
    }
    throw Exception('Failed to load enquiries');
  }

  Future<void> updateEnquiryStatus(String token, String id, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/enquiries/$id/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Failed to update enquiry status');
    }
  }
}
