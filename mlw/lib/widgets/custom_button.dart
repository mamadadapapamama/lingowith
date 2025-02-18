import 'package:flutter/material.dart';
import 'package:mlw/theme/tokens/color_tokens.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isSmall;
  final bool isPrimary;
  final Widget? icon;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isSmall = false,
    this.isPrimary = true,
    this.icon,
  }) : super(key: key);

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  Color get _backgroundColor {
    if (!widget.isPrimary) return Colors.transparent;
    if (widget.onPressed == null) {
      return ColorTokens.base[400] ?? Colors.grey;
    }
    if (_isPressed) {
      return ColorTokens.semantic['surface']?['button-primary-on'] as Color? ?? Colors.orange[700]!;
    }
    if (_isHovered) {
      return ColorTokens.semantic['surface']?['button-primary-hover'] as Color? ?? Colors.orange[400]!;
    }
    return ColorTokens.semantic['surface']?['button-primary'] as Color? ?? Colors.orange;
  }

  Color get _textColor {
    if (!widget.isPrimary) {
      if (widget.onPressed == null) {
        return ColorTokens.base[400] ?? Colors.grey;
      }
      return ColorTokens.semantic['text']?['body'] as Color? ?? Colors.black;
    }
    if (widget.onPressed == null) {
      return ColorTokens.base[400] ?? Colors.grey;
    }
    if (_isPressed) {
      return ColorTokens.semantic['surface']?['button-primary-on'] as Color? ?? Colors.orange[600]!;
    }
    return ColorTokens.semantic['text']?['primary'] as Color? ?? Colors.white;
  }

  Color get _borderColor {
    if (widget.onPressed == null) {
      return ColorTokens.base[400] ?? Colors.grey;
    }
    return ColorTokens.semantic['border']?['base'] as Color? ?? Colors.grey[300]!;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: widget.onPressed == null ? null : (_) => setState(() => _isPressed = true),
        onTapUp: widget.onPressed == null ? null : (_) => setState(() => _isPressed = false),
        onTapCancel: widget.onPressed == null ? null : () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: widget.isSmall ? 12.0 : 16.0,
            vertical: widget.isSmall ? 6.0 : 8.0,
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width - 32,
          ),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: widget.isPrimary ? null : Border.all(
              color: _borderColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                widget.icon!,
                const SizedBox(width: 8.0),
              ],
              Text(
                widget.text,
                style: GoogleFonts.poppins(
                  fontSize: widget.isSmall ? 14.0 : 16.0,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 