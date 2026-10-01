import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_spacing.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';
import '../common/custom_button.dart';
import '../common/custom_input.dart';
import '../common/themed_alert.dart';

class PaymentAdjustmentModal extends StatefulWidget {
  final OrderModel order;
  final VoidCallback onDismiss;

  const PaymentAdjustmentModal({
    super.key,
    required this.order,
    required this.onDismiss,
  });

  static Future<void> show(BuildContext context, OrderModel order) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaymentAdjustmentModal(
        order: order,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  State<PaymentAdjustmentModal> createState() => _PaymentAdjustmentModalState();
}

class _PaymentAdjustmentModalState extends State<PaymentAdjustmentModal> {
  bool _isSubmitting = false;
  bool _showDisputeForm = false;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final est = widget.order.originalEstimate;
    if (est > 0) {
      _priceController.text = est.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _handleApprove() async {
    setState(() => _isSubmitting = true);
    try {
      await ApiService.respondPriceAdjustment(
        widget.order.id,
        accept: true,
        paymentMethod: 'COD',
      );
      if (mounted) {
        Navigator.of(context).pop();
        ThemedAlert.show(
          context,
          title: 'Adjustment Approved',
          message: 'You have approved the adjusted bill. Your rider will deliver shortly.',
          type: 'success',
        );
      }
    } catch (e) {
      if (mounted) {
        ThemedAlert.show(context, title: 'Error', message: e.toString(), type: 'error');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleDispute() async {
    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      ThemedAlert.show(context, title: 'Invalid Price', message: 'Please enter a valid amount.', type: 'error');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ApiService.rejectPriceAdjustment(
        widget.order.id,
        requestedPrice: price,
        reason: _reasonController.text.trim().isNotEmpty
            ? _reasonController.text.trim()
            : 'Customer counter-offer',
      );
      if (mounted) {
        Navigator.of(context).pop();
        ThemedAlert.show(
          context,
          title: 'Dispute Submitted',
          message: 'Your counter-offer has been sent to our operations team for immediate review.',
          type: 'success',
        );
      }
    } catch (e) {
      if (mounted) {
        ThemedAlert.show(context, title: 'Error', message: e.toString(), type: 'error');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final original = order.originalEstimate;
    final proposed = (order.bill?['total'] as num?)?.toDouble() ??
        (order.adjustmentNegotiation?['proposedPrice'] as num?)?.toDouble() ??
        order.total;
    final diff = proposed - original;
    final receiptUrl = order.bill?['receiptImageUrl'] ?? order.bill?['paymentProofImage'];
    final adminNotes = order.bill?['adminNotes'] ?? order.adjustmentNegotiation?['adminNotes'] ?? 'Actual store price differed from estimated total.';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: AppColors.secondary, size: 24),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Price Adjustment', style: AppTypography.h3),
                      Text('Order #${order.orderId}', style: AppTypography.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: widget.onDismiss,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppSpacing.md),

      
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Original Estimate', style: AppTypography.bodySmall),
                        const SizedBox(height: 4),
                        Text('Rs. ${original.toStringAsFixed(2)}', style: AppTypography.h3.copyWith(fontSize: 16)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded, color: AppColors.textSecondary, size: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Actual Total', style: AppTypography.bodySmall),
                        const SizedBox(height: 4),
                        Text(
                          'Rs. ${proposed.toStringAsFixed(2)}',
                          style: AppTypography.h3.copyWith(fontSize: 16, color: AppColors.secondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (diff != 0) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: diff > 0 ? const Color(0xFFFFF0F0) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    diff > 0 ? '+Rs. ${diff.toStringAsFixed(2)} difference' : '-Rs. ${(-diff).toStringAsFixed(2)} savings',
                    style: TextStyle(
                      color: diff > 0 ? AppColors.error : AppColors.delivered,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),

            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reason / Admin Note', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF92400E))),
                  const SizedBox(height: 2),
                  Text(adminNotes.toString(), style: AppTypography.bodySmall.copyWith(color: const Color(0xFFB45309))),
                ],
              ),
            ),

           
            if (receiptUrl != null && receiptUrl.toString().startsWith('http')) ...[
              const SizedBox(height: AppSpacing.md),
              Text('Store Receipt Scan', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: CachedNetworkImage(
                  imageUrl: receiptUrl.toString(),
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (_, __, ___) => const SizedBox(),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            if (!_showDisputeForm) ...[
              CustomButton(
                text: 'Approve & Pay Difference',
                icon: Icons.check_circle_outline_rounded,
                loading: _isSubmitting,
                onPressed: _handleApprove,
              ),
              const SizedBox(height: AppSpacing.sm),
              CustomButton(
                text: 'Challenge / Offer Counter-Price',
                outline: true,
                textColor: AppColors.secondary,
                backgroundColor: AppColors.secondary,
                onPressed: () => setState(() => _showDisputeForm = true),
              ),
            ] else ...[
              Text('Enter Your Counter Offer', style: AppTypography.h3.copyWith(fontSize: 16)),
              const SizedBox(height: 8),
              CustomInput(
                label: 'Proposed Amount (Rs)',
                controller: _priceController,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.money_rounded,
              ),
              const SizedBox(height: 10),
              CustomInput(
                label: 'Reason for Counter-Offer',
                controller: _reasonController,
                hint: 'e.g. Item was marked cheaper on shelf',
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Back',
                      outline: true,
                      onPressed: () => setState(() => _showDisputeForm = false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: CustomButton(
                      text: 'Submit Offer',
                      loading: _isSubmitting,
                      backgroundColor: AppColors.secondary,
                      onPressed: _handleDispute,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
