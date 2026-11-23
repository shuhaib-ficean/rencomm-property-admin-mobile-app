import 'package:flutter/material.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

enum ImagePickerSource { gallery, camera }

class ImagePickerModal {
  static Future<List<File>?> show(BuildContext context) async {
    final source = await showModalBottomSheet<ImagePickerSource>(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery / Files'),
                onTap: () {
                  Navigator.of(context).pop(ImagePickerSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop(ImagePickerSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return null;

    if (source == ImagePickerSource.gallery) {
      return await _pickFromGallery();
    } else if (source == ImagePickerSource.camera) {
      return await _pickFromCamera();
    }
    return null;
  }

  static Future<List<File>?> _pickFromGallery() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.media,
        allowMultiple: true,
      );

      if (result == null) return null;

      return result.files
          .where((file) => file.path != null)
          .map((file) => File(file.path!))
          .toList();
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
      return null;
    }
  }

  static Future<List<File>?> _pickFromCamera() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.camera);

      if (pickedFile == null) return null;

      return [File(pickedFile.path)];
    } catch (e) {
      debugPrint('Error picking from camera: $e');
      return null;
    }
  }
}
