import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_spacing.dart';
import '../../components/common/custom_header.dart';
import '../../components/common/card_container.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  final List<Map<String, String>> _faqs = const [
    {
      'q': 'How does RobotInn delivery work?',
      'a': 'You can browse any store or write custom item requests. A nearby verified rider will claim your order, shop for the items at the local market, upload the verified store receipt, and deliver straight to your doorstep.',
    },
    {
      'q': 'How does price adjustment work?',
      'a': 'If the actual price at the local market differs from the estimate, our admin checks the rider’s uploaded store receipt and adjusts the bill. You will receive an instant notification to approve or challenge the difference before delivery.',
    },
    {
      'q': 'How can I contact my assigned rider?',
      'a': 'Once a rider claims your order, open the Order Details screen to use the in-app chat or phone call button to speak directly with them.',
    },
    {
      'q': 'Can I cancel an active order?',
      'a': 'Yes, you can cancel an order from the Order Details screen before the rider has completed shopping, by choosing a cancellation reason.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomHeader(
        showBackButton: true,
        title: 'Help Center & Support',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Row(
              children: [
                Expanded(
                  child: CardContainer(
                    onTap: () async {
                      final uri = Uri.parse('tel:+923001234567');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.headset_mic_rounded, color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(height: 8),
                        Text('Call Helpline', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                        Text('24/7 Support', style: AppTypography.caption),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CardContainer(
                    onTap: () async {
                      final uri = Uri.parse('mailto:support@robotinn.com?subject=Help Request');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF60A5FA).withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.email_outlined, color: Color(0xFF60A5FA), size: 28),
                        ),
                        const SizedBox(height: 8),
                        Text('Email Us', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                        Text('support@robotinn.com', style: AppTypography.caption),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            Text('Frequently Asked Questions', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.sm),

            ..._faqs.map((faq) => CardContainer(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: EdgeInsets.zero,
                  child: ExpansionTile(
                    title: Text(faq['q']!, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
                    iconColor: AppColors.primary,
                    collapsedIconColor: AppColors.textSecondary,
                    shape: const Border(),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [
                      Text(faq['a']!, style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.4)),
                    ],
                  ),
                )),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
