import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_spacing.dart';

class AlertButtonConfig {
  final String text;
  final VoidCallback? onPressed;
  final bool isDestructive;
  final bool isDefault;

  AlertButtonConfig({
    required this.text,
    this.onPressed,
    this.isDestructive = false,
    this.isDefault = false,
  });
}

class ThemedAlert {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String? type, 
    List<AlertButtonConfig>? buttons,
  }) {
    final effectiveButtons = buttons ?? [AlertButtonConfig(text: 'OK', isDefault: true)];

    Color headerColor = AppColors.primary;
    IconData headerIcon = Icons.info_outline_rounded;

    if (type == 'error' || title.toLowerCase().contains('failed') || title.toLowerCase().contains('error') || title.toLowerCase().contains('suspend')) {
      headerColor = AppColors.error;
      headerIcon = Icons.error_outline_rounded;
    } else if (type == 'success' || title.toLowerCase().contains('success') || title.toLowerCase().contains('welcome')) {
      headerColor = AppColors.delivered;
      headerIcon = Icons.check_circle_outline_rounded;
    } else if (type == 'warning') {
      headerColor = AppColors.secondary;
      headerIcon = Icons.warning_amber_rounded;
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: headerColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(headerIcon, color: headerColor, size: 30),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: AppTypography.h3.copyWith(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: effectiveButtons.map((b) {
                  final isPrimary = b.isDefault || (!b.isDestructive && effectiveButtons.length == 1);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPrimary
                                ? headerColor
                                : (b.isDestructive ? const Color(0xFFFEE2E2) : AppColors.background),
                            foregroundColor: isPrimary
                                ? AppColors.white
                                : (b.isDestructive ? AppColors.error : AppColors.textPrimary),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            if (b.onPressed != null) b.onPressed!();
                          },
                          child: Text(
                            b.text,
                            style: AppTypography.button.copyWith(
                              fontSize: 14,
                              color: isPrimary
                                  ? AppColors.white
                                  : (b.isDestructive ? AppColors.error : AppColors.textPrimary),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
