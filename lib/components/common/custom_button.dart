import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_spacing.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outline;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double height;
  final double? width;
  final List<Color>? gradient;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.loading = false,
    this.outline = false,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.height = 52,
    this.width,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = gradient ?? (outline ? null : AppColors.royalGradient);

    Widget content;
    if (loading) {
      content = SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: outline ? (textColor ?? AppColors.primary) : AppColors.white,
        ),
      );
    } else {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: outline ? (textColor ?? AppColors.primary) : (textColor ?? AppColors.white),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: AppTypography.button.copyWith(
              color: outline ? (textColor ?? AppColors.primary) : (textColor ?? AppColors.white),
            ),
          ),
        ],
      );
    }

    BoxDecoration decoration;
    if (outline) {
      decoration = BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: backgroundColor ?? AppColors.primary, width: 1.5),
      );
    } else {
      decoration = BoxDecoration(
        color: backgroundColor ?? AppColors.primary,
        gradient: (backgroundColor != null || effectiveGradient == null)
            ? null
            : LinearGradient(colors: effectiveGradient),
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: (backgroundColor ?? AppColors.primary).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );
    }

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Ink(
            decoration: decoration,
            child: Center(
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
