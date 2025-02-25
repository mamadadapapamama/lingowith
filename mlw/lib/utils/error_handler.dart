import 'package:flutter/material.dart';
import 'package:mlw/utils/logger.dart';

class ErrorHandler {
  static void showErrorSnackBar(BuildContext context, String message, {dynamic error}) {
    if (error != null) {
      Logger.error(message, error);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }
}