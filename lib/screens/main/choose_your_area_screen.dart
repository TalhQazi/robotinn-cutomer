import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_spacing.dart';
import '../../constants/app_constants.dart';
import '../../components/common/custom_header.dart';
import '../../components/common/card_container.dart';

class ChooseYourAreaScreen extends StatefulWidget {
  const ChooseYourAreaScreen({super.key});

  @override
  State<ChooseYourAreaScreen> createState() => _ChooseYourAreaScreenState();
}

class _ChooseYourAreaScreenState extends State<ChooseYourAreaScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = AppConstants.defaultIslamabadAreas
        .where((a) => a.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomHeader(
        showBackButton: true,
        title: 'Choose Your Area',
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Your Delivery Location', style: AppTypography.h3),
            const SizedBox(height: 4),
            Text('Delivery stores and rates are optimized for your sector', style: AppTypography.bodySmall),
            const SizedBox(height: AppSpacing.md),

            TextField(
              decoration: InputDecoration(
                hintText: 'Search sector (e.g. F-6, DHA, Bahria)...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (val) => setState(() => _search = val),
            ),
            const SizedBox(height: AppSpacing.md),

            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final area = filtered[i];
                  return CardContainer(
                    onTap: () {
                      Navigator.of(context).pop(area);
                    },
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_city_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(area, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                              Text('Islamabad / Rawalpindi Operational Zone', style: AppTypography.caption),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
