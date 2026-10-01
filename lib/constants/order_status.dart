import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class OrderStatus {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String shopping = 'processing';
  static const String billSubmitted = 'bill_submitted';
  static const String billRejected = 'bill_rejected';
  static const String adjustmentPending = 'adjustment_pending';
  static const String adjustmentRejected = 'adjustment_rejected';
  static const String billApproved = 'bill_approved';
  static const String outForDelivery = 'picked';
  static const String delivered = 'delivered';
  static const String cancelled = 'cancelled';
}

class BillStatus {
  static const String submitted = 'submitted';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
}

class OrderStatusHelper {
  static const Map<String, String> _legacyAliases = {
    'in progress': OrderStatus.shopping,
    'picked_up': OrderStatus.outForDelivery,
    'picked up': OrderStatus.outForDelivery,
    'completed': OrderStatus.delivered,
    'arrived_at_store': OrderStatus.shopping,
    'bill_pending': OrderStatus.billSubmitted,
    'pending_admin_validation': OrderStatus.billSubmitted,
    'admin_confirmed': OrderStatus.billApproved,
    'admin_receipt_validated': OrderStatus.billApproved,
    'out_for_delivery': OrderStatus.outForDelivery,
  };

  static String normalize(String? status) {
    final raw = (status ?? '').trim().toLowerCase();
    if (raw.isEmpty) return OrderStatus.pending;
    return _legacyAliases[raw] ?? raw;
  }

  static const List<String> activeStatuses = [
    OrderStatus.accepted,
    OrderStatus.shopping,
    OrderStatus.billSubmitted,
    OrderStatus.billRejected,
    OrderStatus.adjustmentPending,
    OrderStatus.adjustmentRejected,
    OrderStatus.billApproved,
    OrderStatus.outForDelivery,
  ];

  static bool isActive(String? status) {
    return activeStatuses.contains(normalize(status));
  }

  static bool isOpen(String? status) {
    final s = normalize(status);
    return s == OrderStatus.pending || isActive(s);
  }

  static const Map<String, String> labels = {
    OrderStatus.pending: 'Pending',
    OrderStatus.accepted: 'Accepted',
    OrderStatus.shopping: 'Rider at store',
    OrderStatus.billSubmitted: 'Awaiting admin approval',
    OrderStatus.billRejected: 'Bill rejected',
    OrderStatus.adjustmentPending: 'Price approval needed',
    OrderStatus.adjustmentRejected: 'Price declined',
    OrderStatus.billApproved: 'Bill approved',
    OrderStatus.outForDelivery: 'Out for delivery',
    OrderStatus.delivered: 'Delivered',
    OrderStatus.cancelled: 'Cancelled',
  };

  static String getLabel(String? status) {
    final canonical = normalize(status);
    return labels[canonical] ?? 'Pending';
  }

  static Color getColor(String? status) {
    final canonical = normalize(status);
    switch (canonical) {
      case OrderStatus.pending:
      case OrderStatus.accepted:
        return const Color(0xFF2EC4B6);
      case OrderStatus.shopping:
        return const Color(0xFFF77F00);
      case OrderStatus.billSubmitted:
        return const Color(0xFFFF8C42);
      case OrderStatus.billRejected:
      case OrderStatus.adjustmentPending:
      case OrderStatus.adjustmentRejected:
        return const Color(0xFFE63946);
      case OrderStatus.billApproved:
      case OrderStatus.outForDelivery:
        return const Color(0xFF4EA8DE);
      case OrderStatus.delivered:
        return const Color(0xFF2EC4B6);
      case OrderStatus.cancelled:
        return const Color(0xFF9AA5B1);
      default:
        return AppColors.primary;
    }
  }

  static bool isBillVisibleToCustomer(String? billStatus) {
    return (billStatus ?? '').trim().toLowerCase() == BillStatus.approved;
  }
}
