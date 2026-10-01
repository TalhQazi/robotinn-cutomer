import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_spacing.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';
import '../../constants/order_status.dart';
import '../../components/common/custom_header.dart';
import '../../components/common/custom_button.dart';
import '../../components/common/card_container.dart';
import '../../components/common/themed_alert.dart';
import '../../components/order/live_tracking_map.dart';
import '../../components/order/payment_adjustment_modal.dart';
import '../../utils/area_helper.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({super.key, required this.orderId});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  double _ratingScore = 5.0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmittingRating = false;
  Timer? _simulationTimer;
  bool _isSimulating = false;

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _reviewController.dispose();
    super.dispose();
  }

  void _showCancelDialog(OrderModel order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: AppColors.white,
      builder: (ctx) {
        final reasons = [
          'Changed my mind',
          'Order taking too long',
          'Wrong delivery address',
          'Item no longer needed',
          'Other reason',
        ];

        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Cancel Order', style: AppTypography.h3.copyWith(color: AppColors.error)),
              const SizedBox(height: 4),
              Text('Please tell us why you are cancelling this order:', style: AppTypography.bodySmall),
              const SizedBox(height: AppSpacing.md),
              ...reasons.map((r) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(r, style: AppTypography.bodyMedium),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      await _cancelOrder(order.id, r);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cancelOrder(String orderId, String reason) async {
    try {
      await ApiService.cancelOrder(orderId, reason);
      if (mounted) {
        ThemedAlert.show(
          context,
          title: 'Order Cancelled',
          message: 'Your order has been cancelled.',
          type: 'info',
        );
      }
    } catch (e) {
      if (mounted) {
        ThemedAlert.show(context, title: 'Error', message: e.toString(), type: 'error');
      }
    }
  }

  Future<void> _handleCallRider(String? phone) async {
    if (phone == null || phone.isEmpty) {
      ThemedAlert.show(context, title: 'No Phone Number', message: 'Rider phone number is not available.', type: 'warning');
      return;
    }
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _handleChatRider(OrderModel order) async {
    final riderId = order.rider?['id'] ?? order.rider?['uid'];
    final riderName = order.rider?['name'] ?? 'Rider';

    if (riderId == null) {
      ThemedAlert.show(context, title: 'No Rider Assigned', message: 'A rider has not claimed this order yet.', type: 'info');
      return;
    }

    final convId = await ApiService.startConversation(participantId: riderId, orderId: order.orderId);
    if (mounted) {
      Navigator.of(context).pushNamed(
        '/chat',
        arguments: {
          'conversationId': convId,
          'participantId': riderId,
          'contactName': riderName,
          'orderCode': order.orderId,
        },
      );
    }
  }

  Future<void> _submitRating(OrderModel order) async {
    final riderId = order.rider?['id'] ?? order.rider?['uid'];
    if (riderId == null) return;

    setState(() => _isSubmittingRating = true);
    try {
      await ApiService.submitOrderRating(
        order.id,
        riderId,
        _ratingScore,
        _reviewController.text.trim(),
      );
      if (mounted) {
        setState(() => _isSubmittingRating = false);
        ThemedAlert.show(context, title: 'Thank You!', message: 'Your rating and feedback have been submitted.', type: 'success');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmittingRating = false);
        ThemedAlert.show(context, title: 'Rating Failed', message: e.toString(), type: 'error');
      }
    }
  }

  Future<void> _startRiderSimulation(OrderModel order) async {
    setState(() => _isSimulating = true);

    final dest = order.location ??
        order.customer?['location'] ??
        AreaHelper.resolveAreaCoords(order.area.isNotEmpty ? order.area : order.dropoff) ??
        {'lat': 33.7215, 'lng': 73.0565};

    final destLat = (dest['lat'] as num).toDouble();
    final destLng = (dest['lng'] as num).toDouble();

    // Start rider ~1.5 km away
    final startLat = destLat + 0.012;
    final startLng = destLng + 0.012;

    try {
      final docRef = FirebaseFirestore.instance.collection('orders').doc(order.id);

      await docRef.update({
        'status': OrderStatus.outForDelivery,
        'rider': {
          'id': 'simulated_rider_1',
          'name': 'Sher Shah (Test Rider)',
          'phone': '+92 300 1234567',
        },
        'riderLocation': {
          'lat': startLat,
          'lng': startLng,
        },
        'updatedAt': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ThemedAlert.show(
          context,
          title: 'Live Tracking Started!',
          message: 'Simulated rider dispatched! Watch the rider marker move live towards your delivery destination.',
          type: 'success',
        );
      }

      int step = 0;
      const totalSteps = 15;
      _simulationTimer?.cancel();
      _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        step++;
        if (step >= totalSteps) {
          timer.cancel();
          if (mounted) {
            setState(() => _isSimulating = false);
          }
          await docRef.update({
            'status': OrderStatus.delivered,
            'riderLocation': {
              'lat': destLat,
              'lng': destLng,
            },
            'deliveredAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          });
          return;
        }

        final ratio = step / totalSteps;
        final currentLat = startLat + (destLat - startLat) * ratio;
        final currentLng = startLng + (destLng - startLng) * ratio;

        await docRef.update({
          'riderLocation': {
            'lat': currentLat,
            'lng': currentLng,
          },
          'updatedAt': DateTime.now().toIso8601String(),
        });
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isSimulating = false);
        ThemedAlert.show(context, title: 'Simulation Error', message: e.toString(), type: 'error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OrderModel?>(
      stream: ApiService.streamOrder(widget.orderId),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            appBar: CustomHeader(showBackButton: true, title: 'Order Details'),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final order = snapshot.data;
        if (order == null) {
          return const Scaffold(
            appBar: CustomHeader(showBackButton: true, title: 'Order Details'),
            body: Center(child: Text('Order not found')),
          );
        }

        final statusColor = OrderStatusHelper.getColor(order.status);
        final statusLabel = OrderStatusHelper.getLabel(order.status);
        final isAdjustmentPending = order.status == OrderStatus.adjustmentPending;
        final isDelivered = order.status == OrderStatus.delivered;
        final isCancelled = order.status == OrderStatus.cancelled;
        final hasRider = order.rider != null;
        final riderName = order.rider?['name'] ?? 'Assigned Rider';
        final riderPhone = order.rider?['phone']?.toString();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: CustomHeader(
            showBackButton: true,
            title: 'Order #${order.orderId}',
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LiveTrackingMap(
                  riderCoords: order.riderLocation,
                  destinationCoords: order.location ??
                      order.customer?['location'] ??
                      AreaHelper.resolveAreaCoords(order.area.isNotEmpty ? order.area : order.dropoff),
                  isTracking: OrderStatusHelper.isActive(order.status),
                ),

                const SizedBox(height: AppSpacing.md),

                CardContainer(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.delivery_dining_rounded, color: statusColor, size: 28),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(statusLabel, style: AppTypography.h3.copyWith(color: statusColor, fontSize: 17)),
                            const SizedBox(height: 2),
                            Text('Order #${order.orderId}', style: AppTypography.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (!isDelivered && !isCancelled) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isSimulating ? AppColors.secondary : AppColors.primary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                            elevation: 2,
                          ),
                          icon: Icon(_isSimulating ? Icons.directions_bike_rounded : Icons.play_arrow_rounded, size: 20),
                          label: Text(
                            _isSimulating ? 'Tracking Live Rider...' : 'Simulate Rider Tracking',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          onPressed: _isSimulating ? null : () => _startRiderSimulation(order),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onPressed: () => _showCancelDialog(order),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],

               
                if (isAdjustmentPending) ...[
                  const SizedBox(height: AppSpacing.md),
                  InkWell(
                    onTap: () => PaymentAdjustmentModal.show(context, order),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.error, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Price Approval Needed!', style: AppTypography.h3.copyWith(color: AppColors.error, fontSize: 15)),
                                const SizedBox(height: 2),
                                Text('Store total differed from original estimate. Tap to review.', style: AppTypography.caption),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.error),
                        ],
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.md),

               
                if (hasRider) ...[
                  CardContainer(
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.background,
                          child: Icon(Icons.person_rounded, color: AppColors.primary, size: 26),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(riderName, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                              Text('Your Delivery Hero', style: AppTypography.caption),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.phone_rounded, color: AppColors.primary),
                          onPressed: () => _handleCallRider(riderPhone),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_rounded, color: AppColors.primary),
                          onPressed: () => _handleChatRider(order),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                CardContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Order Checklist (${order.items.length})', style: AppTypography.h3.copyWith(fontSize: 16)),
                      const Divider(color: AppColors.border, height: 16),
                      ...order.items.map((it) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppColors.delivered, size: 18),
                                const SizedBox(width: 8),
                                Text('${it.quantity}x', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(it.name, style: AppTypography.bodyMedium)),
                              ],
                            ),
                          )),
                      if (order.notes.isNotEmpty) ...[
                        const Divider(color: AppColors.border, height: 16),
                        Text('Notes: ${order.notes}', style: AppTypography.caption),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                
                CardContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payment & Bill', style: AppTypography.h3.copyWith(fontSize: 16)),
                      const Divider(color: AppColors.border, height: 16),
                      if (order.bill != null && OrderStatusHelper.isBillVisibleToCustomer(order.bill?['status'])) ...[
                        _billRow('Product Total', 'Rs. ${(order.bill?['productPrice'] ?? 0).toString()}'),
                        _billRow('Delivery / Shipping', 'Rs. ${(order.bill?['shippingFee'] ?? 0).toString()}'),
                        const Divider(color: AppColors.border, height: 12),
                        _billRow('Grand Total', 'Rs. ${(order.bill?['total'] ?? order.total).toString()}', isTotal: true),
                      ] else ...[
                        _billRow('Estimated Total', order.total > 0 ? 'Rs. ${order.total.toStringAsFixed(2)}' : 'Calculating...', isTotal: true),
                        const SizedBox(height: 4),
                        Text('Final verified bill receipt will appear once rider shops at store.', style: AppTypography.caption),
                      ],
                    ],
                  ),
                ),

                if (isDelivered) ...[
                  const SizedBox(height: AppSpacing.md),
                  CardContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rate Your Delivery Experience', style: AppTypography.h3.copyWith(fontSize: 16)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [1, 2, 3, 4, 5].map((star) {
                            return IconButton(
                              icon: Icon(
                                _ratingScore >= star ? Icons.star_rounded : Icons.star_border_rounded,
                                color: const Color(0xFFFBBF24),
                                size: 36,
                              ),
                              onPressed: () => setState(() => _ratingScore = star.toDouble()),
                            );
                          }).toList(),
                        ),
                        TextField(
                          controller: _reviewController,
                          decoration: InputDecoration(
                            hintText: 'Leave a compliment or feedback for rider...',
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: BorderSide.none),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 10),
                        CustomButton(
                          text: 'Submit Review',
                          loading: _isSubmittingRating,
                          onPressed: () => _submitRating(order),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _billRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: isTotal ? AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold) : AppTypography.bodySmall),
          Text(
            value,
            style: isTotal
                ? AppTypography.h3.copyWith(fontSize: 16, color: AppColors.primary)
                : AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
