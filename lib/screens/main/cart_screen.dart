import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_spacing.dart';
import '../../providers/cart_provider.dart';
import '../../services/api_service.dart';
import '../../components/common/custom_header.dart';
import '../../components/common/custom_button.dart';
import '../../components/common/card_container.dart';
import '../../components/common/themed_alert.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isPlacing = false;

  Future<void> _handleCheckoutAll() async {
    final cart = context.read<CartProvider>();
    if (cart.cartOrders.isEmpty) {
      ThemedAlert.show(context, title: 'Empty Cart', message: 'Your cart is empty.', type: 'warning');
      return;
    }

    setState(() => _isPlacing = true);

    try {
      for (var orderGroup in cart.cartOrders) {
        final orderData = {
          'items': orderGroup.items.map((i) => i.toMap()).toList(),
          'pickup': orderGroup.pickup,
          'store': orderGroup.store,
          'dropoff': orderGroup.address,
          'area': orderGroup.area,
          'notes': orderGroup.notes,
          'total': orderGroup.estimatedPrice,
          'estimatedPrice': orderGroup.estimatedPrice,
          'originalEstimate': orderGroup.estimatedPrice,
          'estimatedSubtotal': orderGroup.estimatedPrice,
          'location': orderGroup.location,
        };

        await ApiService.createOrder(orderData);
      }

      await cart.clearCart();

      if (mounted) {
        setState(() => _isPlacing = false);
        ThemedAlert.show(
          context,
          title: 'Orders Placed!',
          message: 'Your delivery orders have been broadcasted to our riders!',
          type: 'success',
          buttons: [
            AlertButtonConfig(
              text: 'View Orders',
              isDefault: true,
              onPressed: () {
                Navigator.of(context).pushReplacementNamed('/main', arguments: {'tab': 1});
              },
            ),
          ],
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isPlacing = false);
        ThemedAlert.show(context, title: 'Checkout Failed', message: e.toString(), type: 'error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final orders = cart.cartOrders;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomHeader(
        title: 'Shopping Cart (${cart.orderCount})',
      ),
      body: orders.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_cart_outlined, size: 48, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text('Your Cart is Empty', style: AppTypography.h3),
                  const SizedBox(height: 6),
                  Text('Add items from stores or request a custom order.', style: AppTypography.bodySmall),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: orders.length,
                    itemBuilder: (ctx, i) {
                      final order = orders[i];
                      return CardContainer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 20),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(order.store, style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                                      Text('Area: ${order.area}', style: AppTypography.caption),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                                  onPressed: () => cart.removeOrder(order.id),
                                ),
                              ],
                            ),
                            const Divider(color: AppColors.border, height: 18),
                            ...order.items.map((item) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Text('${item.quantity}x', style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(item.name, style: AppTypography.bodyMedium),
                                      ),
                                    ],
                                  ),
                                )),
                            const SizedBox(height: 8),
                            if (order.estimatedPrice > 0)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Estimated Budget:', style: AppTypography.bodySmall),
                                  Text('Rs. ${order.estimatedPrice.toStringAsFixed(2)}', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.secondary)),
                                ],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

           
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, -2)),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomButton(
                          text: 'Place All Orders Now',
                          icon: Icons.check_circle_outline_rounded,
                          loading: _isPlacing,
                          onPressed: _handleCheckoutAll,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
