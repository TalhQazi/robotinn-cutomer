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

class RequestScreen extends StatefulWidget {
  const RequestScreen({super.key});

  @override
  State<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<RequestScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersProvider = context.watch<OrdersProvider>();
    final activeOrders = ordersProvider.activeOrders;
    final pastOrders = ordersProvider.pastOrders;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomHeader(
        title: 'My Orders (${ordersProvider.orders.length})',
      ),
      body: Column(
        children: [
         
          Container(
            color: AppColors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: AppTypography.h3.copyWith(fontSize: 15),
              unselectedLabelStyle: AppTypography.bodyMedium,
              tabs: [
                Tab(text: 'Active (${activeOrders.length})'),
                Tab(text: 'Past Orders (${pastOrders.length})'),
              ],
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersList(activeOrders, isActive: true),
                _buildOrdersList(pastOrders, isActive: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders, {required bool isActive}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? Icons.moped_outlined : Icons.receipt_long_outlined,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isActive ? 'No Active Orders' : 'No Order History',
              style: AppTypography.h3,
            ),
            const SizedBox(height: 4),
            Text(
              isActive ? 'When you place an order, live progress will appear here.' : 'Your delivered and past orders will be saved here.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: orders.length,
      itemBuilder: (ctx, i) {
        final order = orders[i];
        final statusColor = OrderStatusHelper.getColor(order.status);
        final statusLabel = OrderStatusHelper.getLabel(order.status);

        return CardContainer(
          onTap: () {
            Navigator.of(context).pushNamed(
              '/order-details',
              arguments: {'orderId': order.id},
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.store.isNotEmpty ? order.store : 'Store Delivery',
                          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text('#${order.orderId}', style: AppTypography.caption),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const Divider(color: AppColors.border, height: 16),

             
              Text(
                '${order.items.length} item(s) • ${order.items.map((it) => it.name).join(', ')}',
                style: AppTypography.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(order.createdAt),
                    style: AppTypography.caption,
                  ),
                  Text(
                    order.total > 0 ? 'Rs. ${order.total.toStringAsFixed(2)}' : 'Budget: Pending',
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return 'Recently';
    try {
      if (dateVal is String) {
        final d = DateTime.parse(dateVal);
        return DateFormat('MMM d, yyyy • h:mm a').format(d);
      }
    } catch (_) {}
    return 'Recently';
  }
}
