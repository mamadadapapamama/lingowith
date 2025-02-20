import 'package:flutter/material.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:mlw/theme/tokens/typography_tokens.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Widget? icon;
  final bool isSecondary;
  final bool isSmall;
  final bool isDisabled;

  const CustomButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.isSecondary = false,
    this.isSmall = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled
            ? ColorTokens.getColor('button-disabled')
            : isSecondary
                ? ColorTokens.getColor('button-secondary')
                : ColorTokens.getColor('button-primary'),
        foregroundColor: isDisabled
            ? ColorTokens.getColor('disabled')
            : ColorTokens.getColor('surface'),
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 16 : 24,
          vertical: isSmall ? 8 : 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            SizedBox(width: isSmall ? 4 : 8),
          ],
          Text(
            text,
            style: TypographyTokens.getStyle(isSmall ? 'button.small' : 'button.medium'),
          ),
        ],
      ),
    );
  }
} 