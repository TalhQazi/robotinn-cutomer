import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import '../../theme/app_spacing.dart';
import '../../models/category_model.dart';
import '../../models/store_model.dart';
import '../../models/order_model.dart';
import '../../services/api_service.dart';
import '../../constants/order_status.dart';
import '../../providers/orders_provider.dart';
import '../../utils/area_helper.dart';
import '../../components/common/custom_header.dart';
import '../../components/common/card_container.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedArea = 'F-7';
  late PageController _heroPageController;
  int _heroCurrentIndex = 0;
  Timer? _heroTimer;

  final List<Map<String, dynamic>> _heroBrands = [
    {
      'title': 'Burger King',
      'subtitle': 'Flame Grilled Burgers',
      'tag': 'TOP RATED BURGERS',
      'tagIcon': Icons.lunch_dining_rounded,
      'logo': 'assets/images/3d_brands/burger_king.png',
      'color': const Color(0xFFD62300),
      'colors': const [Color(0xFFE11D48), Color(0xFF9F1239)],
    },
    {
      'title': 'Pizza Hut',
      'subtitle': 'Delicious Cheesy Pizzas',
      'tag': 'HOT & FRESH',
      'tagIcon': Icons.local_pizza_rounded,
      'logo': 'assets/images/3d_brands/pizza_hut.png',
      'color': const Color(0xFFEE1C25),
      'colors': const [Color(0xFFDC2626), Color(0xFF991B1B)],
    },
    {
      'title': 'KFC',
      'subtitle': 'Finger Lickin Good',
      'tag': 'BEST SELLER',
      'tagIcon': Icons.local_fire_department_rounded,
      'logo': 'assets/images/3d_brands/kfc.png',
      'color': const Color(0xFFA3080C),
      'colors': const [Color(0xFFB91C1C), Color(0xFF7F1D1D)],
    },
    {
      'title': "McDonald's",
      'subtitle': "I'm Lovin' It",
      'tag': 'POPULAR CHOICE',
      'tagIcon': Icons.star_rounded,
      'logo': 'assets/images/3d_brands/mcdonalds.png',
      'color': const Color(0xFFDA291C),
      'colors': const [Color(0xFFEA580C), Color(0xFFC2410C)],
    },
    {
      'title': 'Subway',
      'subtitle': 'Fresh Subs & Salads',
      'tag': 'FRESH & HEALTHY',
      'tagIcon': Icons.eco_rounded,
      'logo': 'assets/images/3d_brands/subway.png',
      'color': const Color(0xFF008938),
      'colors': const [Color(0xFF059669), Color(0xFF065F46)],
    },
    {
      'title': 'Dunkin',
      'subtitle': 'Coffee & Fresh Donuts',
      'tag': 'COFFEE & DONUTS',
      'tagIcon': Icons.coffee_rounded,
      'logo': 'assets/images/3d_brands/dunkin.png',
      'color': const Color(0xFFFF671F),
      'colors': const [Color(0xFFF97316), Color(0xFFC2410C)],
    },
    {
      'title': 'Baskin Robbins',
      'subtitle': 'Ice Cream Delights',
      'tag': 'SWEET TREATS',
      'tagIcon': Icons.icecream_rounded,
      'logo': 'assets/images/3d_brands/baskin_robbins.png',
      'color': const Color(0xFF004B87),
      'colors': const [Color(0xFF2563EB), Color(0xFF1E40AF)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _heroPageController = PageController(viewportFraction: 0.9);
    _startHeroAutoScroll();
  }

  void _startHeroAutoScroll() {
    _heroTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_heroPageController.hasClients) {
        final nextIndex = (_heroCurrentIndex + 1) % _heroBrands.length;
        _heroPageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroPageController.dispose();
    super.dispose();
  }

  void _onCategoryTap(CategoryModel cat) {
    Navigator.of(context).pushNamed(
      '/store-list',
      arguments: {
        'categoryId': cat.id,
        'categoryName': cat.name,
        'areaName': AreaHelper.cleanSectorName(_selectedArea),
      },
    );
  }

  void _onBrandTap(Map<String, dynamic> brand) {
    final cleanArea = AreaHelper.cleanSectorName(_selectedArea);
    Navigator.of(context).pushNamed(
      '/store-order',
      arguments: {
        'store': {
          'name': brand['title'],
          'address': '$cleanArea Markaz, Islamabad',
          'rating': brand['rating'],
        },
        'areaName': cleanArea,
        'categoryName': 'Food',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersProvider = context.watch<OrdersProvider>();
    final activeOrders = ordersProvider.activeOrders;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomHeader(),
      body: RefreshIndicator(
        onRefresh: () async {
          final uid = ApiService.auth.currentUser?.uid;
          if (uid != null) {
            ordersProvider.startListening(uid);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          
              InkWell(
                onTap: () async {
                  final res = await Navigator.of(context).pushNamed('/choose-area');
                  if (res is String && res.isNotEmpty) {
                    setState(() => _selectedArea = res);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 10),
                  color: AppColors.white,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Delivering to', style: AppTypography.caption),
                            Text(
                              '$_selectedArea, Islamabad',
                              style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              
              if (activeOrders.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: _buildActiveOrderBanner(activeOrders.first),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              
              SizedBox(
                height: 156,
                child: PageView.builder(
                  controller: _heroPageController,
                  onPageChanged: (i) => setState(() => _heroCurrentIndex = i),
                  itemCount: _heroBrands.length,
                  itemBuilder: (ctx, i) {
                    final brand = _heroBrands[i];
                    final colorList = (brand['colors'] as List<Color>?) ?? [
                      brand['color'] as Color,
                      (brand['color'] as Color).withOpacity(0.8),
                    ];

                    return GestureDetector(
                      onTap: () => _onBrandTap(brand),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: colorList,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: (brand['color'] as Color).withOpacity(0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              // Decorative Background Circles for depth
                              Positioned(
                                right: -25,
                                bottom: -25,
                                child: Container(
                                  width: 130,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: -20,
                                top: -20,
                                child: Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.06),
                                  ),
                                ),
                              ),

                              // Content
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Top Promotional Tag (No rating/time)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(0.22),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  (brand['tagIcon'] as IconData?) ?? Icons.verified_rounded,
                                                  size: 13,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  brand['tag'] ?? 'FEATURED BRAND',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 10,
                                                    letterSpacing: 0.6,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Brand Title & Subtitle
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                brand['title'],
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: -0.3,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                brand['subtitle'],
                                                style: TextStyle(
                                                  color: Colors.white.withOpacity(0.92),
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),

                                          // "Order Now →" Pill Button
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(20),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.12),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  'Order Now',
                                                  style: TextStyle(
                                                    color: (brand['color'] as Color),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Icon(
                                                  Icons.arrow_forward_rounded,
                                                  size: 13,
                                                  color: (brand['color'] as Color),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 12),

                                    // Elevated Right Brand Logo Circle
                                    Container(
                                      width: 82,
                                      height: 82,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.18),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(10),
                                      child: ClipOval(
                                        child: Image.asset(
                                          brand['logo'],
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => const Icon(
                                            Icons.fastfood_rounded,
                                            size: 38,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              // Page Indicator Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_heroBrands.length, (dotIdx) {
                  final isActive = dotIdx == _heroCurrentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),

              const SizedBox(height: AppSpacing.md),

           
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: CardContainer(
                  color: const Color(0xFF1A2E35),
                  onTap: () {
                    Navigator.of(context).pushNamed('/add-order', arguments: {'areaName': _selectedArea});
                  },
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Order Anything Custom', style: AppTypography.h3.copyWith(color: AppColors.white, fontSize: 16)),
                            const SizedBox(height: 2),
                            Text('Can\'t find a store? Tell us what to pick up', style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

             
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Explore Categories', style: AppTypography.h3),
                    Text('Sector $_selectedArea', style: AppTypography.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              StreamBuilder<List<CategoryModel>>(
                stream: ApiService.streamCategories(),
                builder: (ctx, snapshot) {
                  final categories = snapshot.data ?? _fallbackCategories;
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (ctx, i) {
                      final cat = categories[i];
                      return _buildCategoryItem(cat);
                    },
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(CategoryModel cat) {
    return GestureDetector(
      onTap: () => _onCategoryTap(cat),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.all(6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: cat.iconUrl != null && cat.iconUrl!.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: cat.iconUrl!,
                        width: 28,
                        height: 28,
                        fit: BoxFit.contain,
                      )
                    : Text(
                        cat.emoji ?? cat.icon ?? _getCategoryEmoji(cat.name),
                        style: const TextStyle(fontSize: 22),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              cat.name,
              style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600, fontSize: 11),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrderBanner(OrderModel order) {
    final statusColor = OrderStatusHelper.getColor(order.status);
    final statusLabel = OrderStatusHelper.getLabel(order.status);

    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed('/order-details', arguments: {'orderId': order.id});
      },
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: statusColor.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(color: statusColor.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.moped_rounded, color: statusColor, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Active Order', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      Text('#${order.orderId}', style: AppTypography.caption),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusLabel,
                    style: AppTypography.h3.copyWith(color: statusColor, fontSize: 15),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  String _getCategoryEmoji(String? catName) {
    if (catName == null) return '🍔';
    final n = catName.toLowerCase();
    if (n.contains('pharmacy')) return '💊';
    if (n.contains('grocer')) return '🛒';
    if (n.contains('bazaar') || n.contains('fruit') || n.contains('veg')) return '🥬';
    if (n.contains('meat') || n.contains('gosht')) return '🥩';
    if (n.contains('baker') || n.contains('cake')) return '🥐';
    if (n.contains('cosmetic') || n.contains('beauty')) return '💄';
    if (n.contains('fitness')) return '🏋️‍♂️';
    if (n.contains('decor')) return '🛋️';
    return '🍔';
  }

  static final List<CategoryModel> _fallbackCategories = [
    CategoryModel(id: 'food', name: 'Food', icon: '🍔'),
    CategoryModel(id: 'groceries', name: 'Groceries', icon: '🛒'),
    CategoryModel(id: 'pharmacy', name: 'Pharmacy', icon: '💊'),
    CategoryModel(id: 'fresh-bazaar', name: 'Fresh Bazaar', icon: '🥬'),
    CategoryModel(id: 'meat', name: 'Meat', icon: '🥩'),
    CategoryModel(id: 'bakery', name: 'Bakery', icon: '🥐'),
    CategoryModel(id: 'cosmetics', name: 'Cosmetics', icon: '💄'),
    CategoryModel(id: 'decor', name: 'House Decor', icon: '🛋️'),
  ];
}
