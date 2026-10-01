import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_spacing.dart';
import '../../models/order_model.dart';
import '../../components/common/custom_header.dart';
import '../../components/common/custom_button.dart';
import '../../components/common/custom_input.dart';
import '../../components/common/card_container.dart';

class AddItemsScreen extends StatefulWidget {
  final List<OrderItemModel> initialItems;
  final String storeName;

  const AddItemsScreen({
    super.key,
    this.initialItems = const [],
    this.storeName = 'Store',
  });

  @override
  State<AddItemsScreen> createState() => _AddItemsScreenState();
}

class _AddItemsScreenState extends State<AddItemsScreen> {
  final List<OrderItemModel> _items = [];
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedCategory = 'Food';

  final List<String> _categories = [
    'Food', 'Groceries', 'Pharmacy', 'Fresh Bazaar', 'Meat', 'Bakery', 'Cosmetics', 'General'
  ];

  @override
  void initState() {
    super.initState();
    _items.addAll(widget.initialItems);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _addItem() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

    setState(() {
      _items.add(
        OrderItemModel(
          name: name,
          category: _selectedCategory,
          quantity: 1,
          price: price,
          store: widget.storeName,
        ),
      );
      _nameController.clear();
      _priceController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomHeader(
        showBackButton: true,
        title: 'Add Items (${_items.length})',
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            CardContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomInput(
                    label: 'Item Name',
                    hint: 'e.g. 1L Whole Milk, Panadol, Chicken Biryani...',
                    controller: _nameController,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: CustomInput(
                          label: 'Estimated Price (Rs)',
                          hint: 'Optional',
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Category', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedCategory,
                                  isExpanded: true,
                                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: AppTypography.bodySmall))).toList(),
                                  onChanged: (val) {
                                    if (val != null) setState(() => _selectedCategory = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomButton(
                    text: 'Add to List',
                    icon: Icons.add_rounded,
                    height: 44,
                    onPressed: _addItem,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            Expanded(
              child: _items.isEmpty
                  ? Center(
                      child: Text('No items added yet', style: AppTypography.bodySmall),
                    )
                  : ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (ctx, i) {
                        final item = _items[i];
                        return CardContainer(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                                    Text('${item.category} • Rs. ${item.price.toStringAsFixed(0)}', style: AppTypography.caption),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                                onPressed: () => setState(() => _items.removeAt(i)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            CustomButton(
              text: 'Done (${_items.length} Items)',
              onPressed: () => Navigator.of(context).pop(_items),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
