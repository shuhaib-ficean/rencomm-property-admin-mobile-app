import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/department_model.dart';
import '../constants/api_constants.dart';

class DepartmentService {
  final String baseUrl = ApiConstants.baseUrl;

  Future<List<DepartmentModel>> getDepartments(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/departments'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['success'] == true) {
        final List<dynamic> departments = data['departments'];
        return departments.map((json) => DepartmentModel.fromJson(json)).toList();
      } else {
        throw Exception(data['message']);
      }
    } else {
      throw Exception('Failed to load departments: ${response.statusCode} - ${response.body}');
    }
  }

  Future<DepartmentModel> createDepartment(String token, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/departments'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 201) {
      final result = json.decode(response.body);
      return DepartmentModel.fromJson(result['department']);
    } else {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to create department');
    }
  }

  Future<DepartmentModel> updateDepartment(String token, String id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/departments/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(data),
    );

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      return DepartmentModel.fromJson(result['department']);
    } else {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to update department');
    }
  }

  Future<void> deleteDepartment(String token, String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/departments/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(json.decode(response.body)['message'] ?? 'Failed to delete department');
    }
  }
}
