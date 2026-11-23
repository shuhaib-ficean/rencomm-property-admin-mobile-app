import 'package:dio/dio.dart';
import '../../core/models/expense_model.dart';
import '../../core/network/api_client.dart';
import '../../utils/debug_utils.dart';
import 'dart:io';

class ExpenseRepository {
  final ApiClient _apiClient;

  ExpenseRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  Future<List<ExpenseModel>> getExpenses() async {
    try {
      final response = await _apiClient.dio.get('/expenses');

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> data = response.data['expenses'] ?? [];
        return data.map((json) => ExpenseModel.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      consoleLog('DioException in getExpenses: ${e.message}');
      rethrow;
    } catch (e) {
      consoleLog('Error in getExpenses: $e');
      rethrow;
    }
  }

  Future<ExpenseModel> getExpenseById(String id) async {
    try {
      final response = await _apiClient.dio.get('/expenses/$id');

      if (response.statusCode == 200 && response.data != null) {
        return ExpenseModel.fromJson(response.data['expense']);
      }
      throw Exception('Failed to load expense details');
    } catch (e) {
      consoleLog('Error in getExpenseById: $e');
      rethrow;
    }
  }

  Future<ExpenseModel> createExpense({
    required String title,
    required String category,
    required double amount,
    required String date,
    String? propertyId,
    File? receipt,
  }) async {
    try {
      final formData = FormData.fromMap({
        'title': title,
        'category': category,
        'amount': amount,
        'date': date,
        if (propertyId != null) 'propertyId': propertyId,
      });

      if (receipt != null) {
        formData.files.add(MapEntry(
          'receipt',
          await MultipartFile.fromFile(receipt.path),
        ));
      }

      final response = await _apiClient.dio.post(
        '/expenses',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      if (response.statusCode == 201 && response.data != null) {
        return ExpenseModel.fromJson(response.data['expense']);
      }
      throw Exception('Failed to create expense');
    } catch (e) {
      consoleLog('Error in createExpense: $e');
      rethrow;
    }
  }

  Future<ExpenseModel> updateExpense({
    required String id,
    String? title,
    String? category,
    double? amount,
    String? date,
    String? propertyId,
    File? receipt,
  }) async {
    try {
      final formData = FormData.fromMap({
        if (title != null) 'title': title,
        if (category != null) 'category': category,
        if (amount != null) 'amount': amount,
        if (date != null) 'date': date,
        if (propertyId != null) 'propertyId': propertyId,
      });

      if (receipt != null) {
        formData.files.add(MapEntry(
          'receipt',
          await MultipartFile.fromFile(receipt.path),
        ));
      }

      final response = await _apiClient.dio.put(
        '/expenses/$id',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        return ExpenseModel.fromJson(response.data['expense']);
      }
      throw Exception('Failed to update expense');
    } catch (e) {
      consoleLog('Error in updateExpense: $e');
      rethrow;
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _apiClient.dio.delete('/expenses/$id');
    } catch (e) {
      consoleLog('Error in deleteExpense: $e');
      rethrow;
    }
  }
}
