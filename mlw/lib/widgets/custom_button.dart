import 'package:flutter/material.dart';
import 'package:mlw/styles/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isSmall;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.isSmall = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.neonGreen,
        foregroundColor: AppColors.deepGreen,
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 16.0 : 24.0,
          vertical: isSmall ? 8.0 : 12.0,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: isSmall ? 12.0 : 16.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
} 