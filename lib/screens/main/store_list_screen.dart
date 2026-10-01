import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_spacing.dart';
import '../../models/store_model.dart';
import '../../services/store_service.dart';
import '../../utils/area_helper.dart';
import '../../components/common/custom_header.dart';
import '../../components/common/card_container.dart';

class StoreListScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final String areaName;

  const StoreListScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.areaName = 'F-6',
  });

  @override
  State<StoreListScreen> createState() => _StoreListScreenState();
}

class _StoreListScreenState extends State<StoreListScreen> {
  String _searchQuery = '';
  List<StoreModel> _stores = [];
  bool _isLoading = true;
  bool _isBackgroundLoading = false;
  late final String _cleanArea;

  @override
  void initState() {
    super.initState();
    _cleanArea = AreaHelper.cleanSectorName(widget.areaName);
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() {
      _isLoading = true;
      _isBackgroundLoading = true;
    });

    try {
      // Step 1: Instant load from Firestore + Local Fallback for this sector & category
      final instantStores = await StoreService.getImmediateStores(
        areaName: _cleanArea,
        categoryId: widget.categoryId,
        categoryName: widget.categoryName,
      );

      if (mounted) {
        setState(() {
          _stores = instantStores;
          _isLoading = false;
        });
      }

      // Step 2: Fetch Google Places in parallel (matches React Native architecture)
      final googleStores = await StoreService.fetchNearbyStoresFromGoogle(
        areaName: _cleanArea,
        categoryName: widget.categoryName,
      );

      if (mounted) {
        final Map<String, StoreModel> uniqueMap = {};

        // Give priority to real Google Places results and Admin stores
        for (final s in googleStores) {
          final k = s.name.trim().toLowerCase();
          if (k.isNotEmpty) uniqueMap[k] = s;
        }

        for (final s in _stores) {
          final k = s.name.trim().toLowerCase();
          if (k.isNotEmpty) {
            if (s.isAdminStore || !uniqueMap.containsKey(k)) {
              uniqueMap[k] = s;
            }
          }
        }

        setState(() {
          _stores = uniqueMap.values.toList();
          _isBackgroundLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isBackgroundLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _stores.where((s) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = s.name.toLowerCase();
      final addr = (s.address ?? '').toLowerCase();
      return name.contains(q) || addr.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomHeader(
        showBackButton: true,
        title: '${widget.categoryName} Stores',
      ),
      body: Column(
        children: [
          // Search & Sector Location Banner
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: AppColors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search ${widget.categoryName} shops...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Showing stores in $_cleanArea, Islamabad',
                        style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isBackgroundLoading) ...[
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                      const SizedBox(width: 6),
                      Text('Syncing...', style: AppTypography.caption.copyWith(fontSize: 11, color: AppColors.primary)),
                    ] else ...[
                      Text(
                        '${filtered.length} found',
                        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Store List Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.store_mall_directory_outlined, size: 48, color: AppColors.textSecondary),
                              const SizedBox(height: 12),
                              Text('No stores found in $_cleanArea', style: AppTypography.h3),
                              const SizedBox(height: 6),
                              Text(
                                'You can still place a custom order from any shop by writing item names!',
                                style: AppTypography.bodySmall,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                                ),
                                icon: const Icon(Icons.add_shopping_cart_rounded),
                                label: const Text('Custom Order from Here'),
                                onPressed: () {
                                  Navigator.of(context).pushNamed(
                                    '/store-order',
                                    arguments: {
                                      'store': {
                                        'name': '${widget.categoryName} Shop',
                                        'address': '$_cleanArea, Islamabad',
                                      },
                                      'areaName': _cleanArea,
                                      'categoryName': widget.categoryName,
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadStores,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: filtered.length,
                          itemBuilder: (ctx, i) {
                            final store = filtered[i];
                            return CardContainer(
                              onTap: () {
                                Navigator.of(context).pushNamed(
                                  '/store-order',
                                  arguments: {
                                    'store': store.toMap(),
                                    'areaName': _cleanArea,
                                    'categoryName': widget.categoryName,
                                  },
                                );
                              },
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(AppRadius.md),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        _getStoreIcon(store.category ?? widget.categoryName),
                                        color: AppColors.primary,
                                        size: 26,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          store.name,
                                          style: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          store.address ?? '$_cleanArea, Islamabad',
                                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: [
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.schedule_rounded, size: 13, color: AppColors.textSecondary),
                                                const SizedBox(width: 3),
                                                Text('15-25 mins', style: AppTypography.caption.copyWith(fontSize: 11)),
                                              ],
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.delivery_dining_rounded, size: 13, color: AppColors.primary),
                                                const SizedBox(width: 3),
                                                Text('Fast Delivery', style: AppTypography.caption.copyWith(color: AppColors.primary, fontSize: 11)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEF3C7),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '⭐ ${(store.rating ?? 4.7).toStringAsFixed(1)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  IconData _getStoreIcon(String? cat) {
    final lower = (cat ?? '').toLowerCase();
    if (lower.contains('food') || lower.contains('restaur')) {
      return Icons.restaurant_rounded;
    } else if (lower.contains('grocer') || lower.contains('mart')) {
      return Icons.shopping_basket_rounded;
    } else if (lower.contains('vegetable') || lower.contains('sabzi')) {
      return Icons.eco_rounded;
    } else if (lower.contains('fruit')) {
      return Icons.apple_rounded;
    } else if (lower.contains('baker')) {
      return Icons.cake_rounded;
    } else if (lower.contains('pharma') || lower.contains('medic')) {
      return Icons.medical_services_rounded;
    } else if (lower.contains('meat')) {
      return Icons.set_meal_rounded;
    }
    return Icons.storefront_rounded;
  }
}
