import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_spacing.dart';
import '../../models/order_model.dart';
import '../../models/address_model.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/category_detection_service.dart';
import '../../providers/cart_provider.dart';
import '../../components/common/custom_header.dart';
import '../../components/common/custom_button.dart';
import '../../components/common/custom_input.dart';
import '../../components/common/card_container.dart';
import '../../components/common/themed_alert.dart';
import '../../utils/area_helper.dart';

class StoreOrderScreen extends StatefulWidget {
  final Map<String, dynamic> store;
  final String areaName;
  final String categoryName;

  const StoreOrderScreen({
    super.key,
    required this.store,
    this.areaName = 'F-7',
    this.categoryName = 'Food',
  });

  @override
  State<StoreOrderScreen> createState() => _StoreOrderScreenState();
}

class _StoreOrderScreenState extends State<StoreOrderScreen> {
  final List<OrderItemModel> _items = [];
  final TextEditingController _itemController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  late String _deliveryAddress;
  double? _deliveryLat;
  double? _deliveryLng;
  List<AddressModel> _savedAddresses = [];
  bool _isLocating = true;
  bool _isOrdering = false;
  String _detectedCategory = 'Food';

  @override
  void initState() {
    super.initState();
    final defaultArea = widget.areaName.isNotEmpty ? widget.areaName : 'F-7';
    final defaultCoords = AreaHelper.resolveAreaCoords(defaultArea) ?? {'lat': 33.7215, 'lng': 73.0565};
    _deliveryAddress = '$defaultArea, Islamabad';
    _deliveryLat = defaultCoords['lat'];
    _deliveryLng = defaultCoords['lng'];
    _loadInitialLocation();
    _loadSavedAddresses();
  }

  @override
  void dispose() {
    _itemController.dispose();
    _notesController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialLocation({bool showFeedback = false}) async {
    setState(() => _isLocating = true);
    if (showFeedback && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Detecting current GPS location...'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    final loc = await LocationService.getCurrentLocationWithAddress(fallbackArea: widget.areaName);
    if (!mounted) return;
    setState(() {
      _deliveryAddress = loc.address;
      _deliveryLat = loc.lat;
      _deliveryLng = loc.lng;
      _isLocating = false;
    });
    if (showFeedback && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location updated: ${loc.address}'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _loadSavedAddresses() async {
    final list = await ApiService.getAddresses();
    if (mounted) {
      setState(() => _savedAddresses = list);
    }
  }

  void _onItemTextChanged(String text) {
    final detected = CategoryDetectionService.detectCategory(text);
    setState(() {
      _detectedCategory = detected.categoryName;
    });
  }

  void _addItem() {
    final text = _itemController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _items.add(
        OrderItemModel(
          name: text,
          category: _detectedCategory,
          quantity: 1,
          price: 0.0,
          store: widget.store['name'] ?? 'Store',
        ),
      );
      _itemController.clear();
      _detectedCategory = 'Food';
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _updateQuantity(int index, int delta) {
    setState(() {
      final current = _items[index].quantity;
      final newQty = current + delta;
      if (newQty > 0) {
        _items[index] = OrderItemModel(
          name: _items[index].name,
          category: _items[index].category,
          quantity: newQty,
          price: _items[index].price,
          store: _items[index].store,
        );
      } else {
        _items.removeAt(index);
      }
    });
  }

  void _showManualAddressDialog() {
    final textController = TextEditingController(text: _deliveryAddress);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(
          children: [
            const Icon(Icons.edit_location_alt_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            Text('Enter Address', style: AppTypography.h3),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter your delivery address or house/street details:', style: AppTypography.bodySmall),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: textController,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. House 14, Street 25, F-7/2, Islamabad',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
            ),
            onPressed: () {
              final newAddr = textController.text.trim();
              if (newAddr.isNotEmpty) {
                final matched = AreaHelper.resolveAreaCoords(newAddr) ??
                    AreaHelper.resolveAreaCoords(widget.areaName) ??
                    {'lat': 33.7215, 'lng': 73.0565};
                setState(() {
                  _deliveryAddress = newAddr;
                  _deliveryLat = matched['lat'];
                  _deliveryLng = matched['lng'];
                  _isLocating = false;
                });
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Set Address', style: TextStyle(color: AppColors.white)),
          ),
        ],
      ),
    );
  }

  void _openAddressPicker() {
    final quickSectors = ['F-6', 'F-7', 'F-8', 'F-10', 'F-11', 'G-6', 'G-7', 'G-8', 'G-9', 'G-10', 'G-11', 'E-7', 'Blue Area', 'I-8'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      backgroundColor: AppColors.white,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.md,
        ),
        child: SingleChildScrollView(
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
              Text('Select Delivery Address', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), shape: BoxShape.circle),
                  child: const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 20),
                ),
                title: const Text('Use Current GPS Location', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Detect GPS location instantly'),
                trailing: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _loadInitialLocation(showFeedback: true);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.12), shape: BoxShape.circle),
                  child: const Icon(Icons.edit_location_alt_rounded, color: AppColors.secondary, size: 20),
                ),
                title: const Text('Enter Address Manually', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Type exact house, street & sector'),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showManualAddressDialog();
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              const Divider(color: AppColors.border),
              const SizedBox(height: AppSpacing.xs),
              Text('Quick Select Sector (Islamabad)', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: quickSectors.map((sector) {
                  final isSelected = _deliveryAddress.contains(sector);
                  return ActionChip(
                    label: Text(sector),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.white : AppColors.textPrimary,
                    ),
                    backgroundColor: isSelected ? AppColors.primary : AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                    ),
                    onPressed: () {
                      final coords = AreaHelper.resolveAreaCoords(sector) ?? {'lat': 33.7215, 'lng': 73.0565};
                      setState(() {
                        _deliveryAddress = '$sector, Islamabad';
                        _deliveryLat = coords['lat'];
                        _deliveryLng = coords['lng'];
                        _isLocating = false;
                      });
                      Navigator.of(ctx).pop();
                    },
                  );
                }).toList(),
              ),
              if (_savedAddresses.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                const Divider(color: AppColors.border),
                const SizedBox(height: AppSpacing.xs),
                Text('Saved Addresses', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                ..._savedAddresses.map((addr) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on_outlined, color: AppColors.textSecondary),
                      title: Text(addr.title, style: AppTypography.bodyLarge),
                      subtitle: Text(addr.address, style: AppTypography.bodySmall),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        setState(() {
                          _deliveryAddress = addr.address;
                          _deliveryLat = addr.lat;
                          _deliveryLng = addr.lng;
                          _isLocating = false;
                        });
                      },
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAddToCart() async {
    if (_items.isEmpty) {
      ThemedAlert.show(context, title: 'No Items Added', message: 'Please add at least one item before adding to cart.', type: 'warning');
      return;
    }

    final storeName = widget.store['name'] ?? 'Store';
    final budget = double.tryParse(_budgetController.text.trim()) ?? 0.0;
    final fallback = AreaHelper.resolveAreaCoords(widget.areaName) ?? {'lat': 33.7215, 'lng': 73.0565};
    final finalLat = _deliveryLat ?? fallback['lat']!;
    final finalLng = _deliveryLng ?? fallback['lng']!;

    final cartGroup = CartOrderGroup(
      id: 'cart-ord-${DateTime.now().millisecondsSinceEpoch}',
      store: storeName,
      pickup: storeName,
      area: widget.areaName,
      address: _deliveryAddress,
      items: _items,
      estimatedPrice: budget,
      notes: _notesController.text.trim(),
      location: {'lat': finalLat, 'lng': finalLng},
      createdAt: DateTime.now().toIso8601String(),
    );

    await context.read<CartProvider>().addOrderToCart(cartGroup);

    if (mounted) {
      ThemedAlert.show(
        context,
        title: 'Added to Cart',
        message: 'Your items from $storeName have been added to your cart.',
        type: 'success',
        buttons: [
          AlertButtonConfig(
            text: 'View Cart',
            onPressed: () {
              Navigator.of(context).pushNamed('/main', arguments: {'tab': 2});
            },
          ),
          AlertButtonConfig(
            text: 'Keep Shopping',
            isDefault: true,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    }
  }

  Future<void> _handleOrderNow() async {
    if (_items.isEmpty) {
      ThemedAlert.show(context, title: 'No Items Added', message: 'Please add at least one item to place an order.', type: 'warning');
      return;
    }

    setState(() => _isOrdering = true);

    try {
      final storeName = widget.store['name'] ?? 'Store';
      final budget = double.tryParse(_budgetController.text.trim()) ?? 0.0;
      final fallback = AreaHelper.resolveAreaCoords(widget.areaName) ?? {'lat': 33.7215, 'lng': 73.0565};
      final finalLat = _deliveryLat ?? fallback['lat']!;
      final finalLng = _deliveryLng ?? fallback['lng']!;

      final orderData = {
        'items': _items.map((i) => i.toMap()).toList(),
        'pickup': storeName,
        'store': storeName,
        'dropoff': _deliveryAddress,
        'area': widget.areaName,
        'notes': _notesController.text.trim(),
        'total': budget,
        'estimatedPrice': budget,
        'originalEstimate': budget,
        'estimatedSubtotal': budget,
        'location': {'lat': finalLat, 'lng': finalLng},
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
    final storeName = widget.store['name'] ?? 'Selected Store';
    final storeAddress = widget.store['address'] ?? '${widget.areaName}, Islamabad';
    final storeRating = widget.store['rating']?.toString() ?? '4.8';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomHeader(
        showBackButton: true,
        title: storeName,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            CardContainer(
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(storeName, style: AppTypography.h3.copyWith(fontSize: 17)),
                        const SizedBox(height: 2),
                        Text(storeAddress, style: AppTypography.bodySmall),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('⭐ $storeRating', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

           
            Text('Delivery Address', style: AppTypography.h3.copyWith(fontSize: 15)),
            const SizedBox(height: 6),
            CardContainer(
              onTap: _openAddressPicker,
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: AppColors.secondary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _deliveryAddress,
                          style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_isLocating) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Detecting exact GPS location...',
                                style: AppTypography.caption.copyWith(color: AppColors.primary, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

           
            Text('Add Items to Order', style: AppTypography.h3.copyWith(fontSize: 15)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: CustomInput(
                    hint: 'Type dish or item (e.g. 2 Zinger Burgers)...',
                    controller: _itemController,
                    onChanged: _onItemTextChanged,
                    prefixIcon: Icons.add_circle_outline_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    onPressed: _addItem,
                    child: const Icon(Icons.add_rounded, size: 24),
                  ),
                ),
              ],
            ),

           
            if (_itemController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Auto-detected category: $_detectedCategory',
                    style: AppTypography.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),

         
            if (_items.isNotEmpty) ...[
              Text('Your Checklist (${_items.length})', style: AppTypography.h3.copyWith(fontSize: 15)),
              const SizedBox(height: 6),
              ..._items.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;
                return CardContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_getItemCategoryEmoji(item.category), style: const TextStyle(fontSize: 16)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                            Text(item.category, style: AppTypography.caption),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded, size: 20, color: AppColors.textSecondary),
                            onPressed: () => _updateQuantity(idx, -1),
                          ),
                          Text('${item.quantity}', style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 20, color: AppColors.primary),
                            onPressed: () => _updateQuantity(idx, 1),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                            onPressed: () => _removeItem(idx),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],

            const SizedBox(height: AppSpacing.md),

           
            CustomInput(
              label: 'Estimated Budget / Total (Rs)',
              hint: 'Optional price estimate (e.g. 1500)',
              controller: _budgetController,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.money_rounded,
            ),

            const SizedBox(height: AppSpacing.md),

           
            CustomInput(
              label: 'Special Instructions for Rider',
              hint: 'e.g. Extra ketchup, ring bell upon arrival...',
              controller: _notesController,
              maxLines: 2,
              prefixIcon: Icons.note_alt_outlined,
            ),

            const SizedBox(height: AppSpacing.xl),

           
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Add to Cart',
                    outline: true,
                    icon: Icons.shopping_cart_outlined,
                    onPressed: _handleAddToCart,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: CustomButton(
                    text: 'Order Now',
                    icon: Icons.bolt_rounded,
                    loading: _isOrdering,
                    onPressed: _handleOrderNow,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  String _getItemCategoryEmoji(String cat) {
    final lower = cat.toLowerCase();
    if (lower.contains('pharmacy')) return '💊';
    if (lower.contains('grocer')) return '🛒';
    if (lower.contains('bazaar') || lower.contains('fruit')) return '🥬';
    if (lower.contains('meat')) return '🥩';
    if (lower.contains('baker')) return '🥐';
    if (lower.contains('cosmetic')) return '💄';
    return '🍔';
  }
}
