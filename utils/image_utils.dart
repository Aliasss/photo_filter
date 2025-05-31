import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageUtils {
  static Future<File?> pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  static Future<void> saveImage(File image, String path) async {
    try {
      await image.copy(path);
    } catch (e) {
      debugPrint('Error saving image: $e');
    }
  }
} 