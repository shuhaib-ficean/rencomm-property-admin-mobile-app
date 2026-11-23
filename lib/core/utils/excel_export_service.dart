import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

class ExcelExportService {
  /// Exports data to an Excel file and opens it.
  ///
  /// [fileName] should not include the .xlsx extension (it will be added).
  /// [sheetName] is the name of the worksheet.
  /// [headers] is a list of column map keys or strings to use as the header row.
  /// [data] is a list of lists, where each inner list represents a row of data corresponding to the headers.
  static Future<void> exportAndOpenFile({
    required String fileName,
    required String sheetName,
    required List<String> headers,
    required List<List<dynamic>> data,
  }) async {
    try {
      // 1. Create a new Excel Document
      var excel = Excel.createExcel();

      // Ensure the sheet exists and is active
      Sheet sheetObject = excel[sheetName];

      // Remove default "Sheet1" if our custom sheet name is different
      if (sheetName != 'Sheet1' && excel.tables.keys.contains('Sheet1')) {
        excel.delete('Sheet1');
      }

      // 2. Append Headers
      sheetObject.appendRow(headers.map((h) => TextCellValue(h)).toList());

      // Optional: Style the headers (bold)
      // Note: Current excel package versions might require complex styling setup.
      // For simplicity in MVP, we might skip bolding if it causes issues.

      // 3. Append Data Rows
      for (var row in data) {
        List<CellValue?> cellRow = row.map((dynamic value) {
          if (value == null) {
            return TextCellValue('');
          } else if (value is String) {
            return TextCellValue(value);
          } else if (value is int) {
            return IntCellValue(value);
          } else if (value is double) {
            return DoubleCellValue(value);
          } else if (value is bool) {
            return BoolCellValue(value);
          } else if (value is DateTime) {
            // excel pkgs often handle DateTimes, or we can format to string
            return DateTimeCellValue.fromDateTime(value);
          } else {
            return TextCellValue(value.toString());
          }
        }).toList();

        sheetObject.appendRow(cellRow);
      }

      // 4. Get Directory to Save File
      Directory? directory;
      if (Platform.isAndroid) {
        // Use external storage directory for Android so it's easily accessible/sharable
        directory = await getExternalStorageDirectory();
        // Fallback if external is null
        directory ??= await getApplicationDocumentsDirectory();
      } else if (Platform.isIOS) {
        // Use Application Documents Directory for iOS
        directory = await getApplicationDocumentsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      // Ensure directory exists
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      final String fullPath = '${directory.path}/$fileName.xlsx';
      final File file = File(fullPath);

      // 5. Save the file
      List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes, flush: true);

        // 6. Open the file
        final result = await OpenFilex.open(fullPath);

        if (result.type != ResultType.done) {
          throw Exception('Could not open file: ${result.message}');
        }
      } else {
        throw Exception('Failed to generate Excel file bytes.');
      }
    } catch (e) {
      rethrow;
    }
  }
}
