import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_spacing.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../components/common/custom_header.dart';
import '../../components/common/custom_button.dart';
import '../../components/common/custom_input.dart';
import '../../components/common/card_container.dart';
import '../../components/common/themed_alert.dart';
import '../../utils/area_helper.dart';

class OrderScreen extends StatefulWidget {
  final String areaName;

  const OrderScreen({super.key, this.areaName = 'F-7'});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _pickupController = TextEditingController();
  final _itemsController = TextEditingController();
  final _budgetController = TextEditingController();
  final _notesController = TextEditingController();

  late String _dropoffAddress;
  double? _dropoffLat;
  double? _dropoffLng;
  bool _isOrdering = false;

  @override
  void initState() {
    super.initState();
    final defaultArea = widget.areaName.isNotEmpty ? widget.areaName : 'F-7';
    final defaultCoords = AreaHelper.resolveAreaCoords(defaultArea) ?? {'lat': 33.7215, 'lng': 73.0565};
    _dropoffAddress = '$defaultArea, Islamabad';
    _dropoffLat = defaultCoords['lat'];
    _dropoffLng = defaultCoords['lng'];
    _loadLocation();
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _itemsController.dispose();
    _budgetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadLocation() async {
    final loc = await LocationService.getCurrentLocationWithAddress(fallbackArea: widget.areaName);
    if (!mounted) return;
    setState(() {
      _dropoffAddress = loc.address;
      _dropoffLat = loc.lat;
      _dropoffLng = loc.lng;
    });
  }

  Future<void> _handleSubmit() async {
    final pickup = _pickupController.text.trim();
    final itemsRaw = _itemsController.text.trim();
    final budget = double.tryParse(_budgetController.text.trim()) ?? 0.0;

    if (pickup.isEmpty) {
      ThemedAlert.show(context, title: 'Pickup Required', message: 'Please specify where to buy or pick up from.', type: 'warning');
      return;
    }

    if (itemsRaw.isEmpty) {
      ThemedAlert.show(context, title: 'Items Required', message: 'Please write the items you want our rider to get.', type: 'warning');
      return;
    }

    setState(() => _isOrdering = true);

    try {
      final parsedItems = itemsRaw
          .split('\n')
          .where((s) => s.trim().isNotEmpty)
          .map((s) => OrderItemModel(name: s.trim(), category: 'Custom', quantity: 1, store: pickup))
          .toList();

      final orderData = {
        'items': parsedItems.map((i) => i.toMap()).toList(),
        'pickup': pickup,
        'store': pickup,
        'dropoff': _dropoffAddress,
        'area': widget.areaName,
        'notes': _notesController.text.trim(),
        'total': budget,
        'estimatedPrice': budget,
        'originalEstimate': budget,
        'estimatedSubtotal': budget,
        'location': {
          'lat': _dropoffLat ?? (AreaHelper.resolveAreaCoords(widget.areaName)?['lat'] ?? 33.7215),
          'lng': _dropoffLng ?? (AreaHelper.resolveAreaCoords(widget.areaName)?['lng'] ?? 73.0565),
        },
      };

      final created = await ApiService.createOrder(orderData);

      if (mounted) {
        setState(() => _isOrdering = false);
        Navigator.of(context).pushReplacementNamed(
          '/order-details',
          arguments: {'orderId': created.id},
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isOrdering = false);
        ThemedAlert.show(context, title: 'Order Failed', message: e.toString(), type: 'error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomHeader(
        showBackButton: true,
        title: 'Custom Order Request',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CardContainer(
              color: const Color(0xFF1A2E35),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.flash_on_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Express Personal Shopper', style: AppTypography.h3.copyWith(color: AppColors.white, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text('Tell our rider what to buy from any shop or market', style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            CustomInput(
              label: 'Where to Buy From (Store or Shop Name)',
              hint: 'e.g. D-Watson Pharmacy, Tehzeeb Bakery, Local Meat Shop...',
              controller: _pickupController,
              prefixIcon: Icons.storefront_rounded,
            ),

            const SizedBox(height: AppSpacing.md),

            CustomInput(
              label: 'Items List (One per line)',
              hint: '1x Panadol Extra\n2x Olpers Milk 1L\n1x Brown Bread...',
              controller: _itemsController,
              maxLines: 4,
              prefixIcon: Icons.list_alt_rounded,
            ),

            const SizedBox(height: AppSpacing.md),

            CustomInput(
              label: 'Estimated Budget / Total (Rs)',
              hint: 'Approximate total budget for items',
              controller: _budgetController,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.money_rounded,
            ),

            const SizedBox(height: AppSpacing.md),

            Text('Delivery Destination', style: AppTypography.h3.copyWith(fontSize: 15)),
            const SizedBox(height: 6),
            CardContainer(
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: AppColors.secondary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_dropoffAddress, style: AppTypography.bodyMedium),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            CustomInput(
              label: 'Special Instructions',
              hint: 'e.g. Call when outside, leave at security gate...',
              controller: _notesController,
              maxLines: 2,
              prefixIcon: Icons.note_alt_outlined,
            ),

            const SizedBox(height: AppSpacing.xl),

            CustomButton(
              text: 'Place Custom Order',
              icon: Icons.send_rounded,
              loading: _isOrdering,
              onPressed: _handleSubmit,
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
