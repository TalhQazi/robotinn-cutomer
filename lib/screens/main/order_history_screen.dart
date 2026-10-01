import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_spacing.dart';
import '../../models/order_model.dart';
import '../../constants/order_status.dart';
import '../../providers/orders_provider.dart';
import '../../components/common/custom_header.dart';
import '../../components/common/card_container.dart';

class OrderHistoryScreen extends StatefulWidget {
  final String filter; 

  const OrderHistoryScreen({super.key, this.filter = 'all'});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late String _currentFilter;

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.filter;
  }

  @override
  Widget build(BuildContext context) {
    final ordersProvider = context.watch<OrdersProvider>();
    final allOrders = ordersProvider.orders;

    List<OrderModel> filtered = allOrders;
    if (_currentFilter == 'completed') {
      filtered = allOrders.where((o) => o.status == OrderStatus.delivered).toList();
    } else if (_currentFilter == 'active') {
      filtered = allOrders.where((o) => OrderStatusHelper.isActive(o.status)).toList();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomHeader(
        showBackButton: true,
        title: 'Order History',
      ),
      body: Column(
        children: [
        
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            color: AppColors.white,
            child: Row(
              children: [
                _filterChip('All', 'all'),
                const SizedBox(width: 8),
                _filterChip('Completed', 'completed'),
                const SizedBox(width: 8),
                _filterChip('Active', 'active'),
              ],
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.history_rounded, size: 48, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        Text('No Orders Found', style: AppTypography.h3),
                        const SizedBox(height: 4),
                        Text('Orders matching this filter will show up here.', style: AppTypography.bodySmall),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final order = filtered[i];
                      final statusColor = OrderStatusHelper.getColor(order.status);
                      final statusLabel = OrderStatusHelper.getLabel(order.status);

                      return CardContainer(
                        onTap: () {
                          Navigator.of(context).pushNamed('/order-details', arguments: {'orderId': order.id});
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(order.store.isNotEmpty ? order.store : 'Store Delivery', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const Divider(color: AppColors.border, height: 14),
                            Text('${order.items.length} item(s): ${order.items.map((it) => it.name).join(', ')}', style: AppTypography.bodySmall, maxLines: 2),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatDate(order.createdAt), style: AppTypography.caption),
                                Text(
                                  order.total > 0 ? 'Rs. ${order.total.toStringAsFixed(2)}' : 'Rs. 0.00',
                                  style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _currentFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary.withOpacity(0.15),
      backgroundColor: AppColors.background,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 13,
      ),
      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
      onSelected: (selected) {
        if (selected) setState(() => _currentFilter = value);
      },
    );
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return 'Recently';
    try {
      if (dateVal is String) {
        final d = DateTime.parse(dateVal);
        return DateFormat('MMM d, yyyy').format(d);
      }
    } catch (_) {}
    return 'Recently';
  }
}
