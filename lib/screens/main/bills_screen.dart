import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_spacing.dart';
import '../../models/bill_model.dart';
import '../../services/api_service.dart';
import '../../components/common/custom_header.dart';
import '../../components/common/custom_button.dart';
import '../../components/common/card_container.dart';
import '../../components/common/themed_alert.dart';

class BillsScreen extends StatefulWidget {
  const BillsScreen({super.key});

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _handleUploadProof(BillModel bill) async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;

      setState(() => _isUploading = true);
      final file = File(picked.path);
      final url = await ApiService.uploadPaymentProof(billId: bill.id, file: file);
      await ApiService.submitPaymentProof(bill.id, url);

      if (mounted) {
        setState(() => _isUploading = false);
        ThemedAlert.show(
          context,
          title: 'Payment Proof Uploaded',
          message: 'Your payment screenshot has been submitted for admin verification.',
          type: 'success',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ThemedAlert.show(context, title: 'Upload Failed', message: e.toString(), type: 'error');
      }
    }
  }

  void _previewReceipt(String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                errorWidget: (_, __, ___) => const Center(child: Text('Failed to load image', style: TextStyle(color: Colors.white))),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = ApiService.auth.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomHeader(
        showBackButton: true,
        title: 'My Bills',
      ),
      body: StreamBuilder<List<BillModel>>(
        stream: ApiService.streamMyBills(uid),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final bills = snapshot.data ?? [];
          if (bills.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_rounded, size: 48, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text('No Verified Bills', style: AppTypography.h3),
                  const SizedBox(height: 6),
                  Text('Approved store receipts and invoices will show up here.', style: AppTypography.bodySmall),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: bills.length,
            itemBuilder: (ctx, i) {
              final bill = bills[i];
              final isPaid = bill.status == 'paid';

              return CardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Order #${bill.orderId}', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPaid ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isPaid ? 'PAID' : 'PAYMENT DUE',
                            style: TextStyle(
                              color: isPaid ? AppColors.delivered : const Color(0xFFD97706),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: AppColors.border, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Items Amount', style: AppTypography.bodySmall),
                        Text('Rs. ${bill.productPrice.toStringAsFixed(2)}', style: AppTypography.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Delivery Fee', style: AppTypography.bodySmall),
                        Text('Rs. ${bill.shippingFee.toStringAsFixed(2)}', style: AppTypography.bodyMedium),
                      ],
                    ),
                    const Divider(color: AppColors.border, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Bill', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                        Text(
                          'Rs. ${bill.total.toStringAsFixed(2)}',
                          style: AppTypography.h3.copyWith(color: AppColors.primary, fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (bill.receiptImageUrl != null && bill.receiptImageUrl!.isNotEmpty)
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                              ),
                              icon: const Icon(Icons.receipt_rounded, size: 16, color: AppColors.primary),
                              label: const Text('View Receipt', style: TextStyle(color: AppColors.primary, fontSize: 13)),
                              onPressed: () => _previewReceipt(bill.receiptImageUrl!),
                            ),
                          ),
                        if (!isPaid) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.secondary,
                                foregroundColor: AppColors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                              ),
                              icon: const Icon(Icons.upload_file_rounded, size: 16),
                              label: const Text('Pay / Proof', style: TextStyle(fontSize: 13)),
                              onPressed: _isUploading ? null : () => _handleUploadProof(bill),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
