import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../models/menu_item.dart';
import '../models/todays_special_settings.dart';
import '../widgets/food_card.dart';
import '../widgets/section_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.onBrowseMenu,
    required this.onBrowseCategory,
    required this.onOpenItem,
  });

  final AppController controller;
  final VoidCallback onBrowseMenu;
  final ValueChanged<String> onBrowseCategory;
  final ValueChanged<MenuItemModel> onOpenItem;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final heroItem = controller.todaysSpecialItem;
          final specialSettings = controller.todaysSpecialSettings;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.asset(
                                  'assets/images/brand_mark.png',
                                  width: 42,
                                  height: 42,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Peri Q',
                                style: Theme.of(context).textTheme.headlineLarge
                                    ?.copyWith(color: AppTheme.periRed),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppTheme.success.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppTheme.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  controller.storeOpen
                                      ? 'Open Now • Closes 9PM'
                                      : 'Closed • Opens 10AM',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppTheme.success,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (specialSettings.enabled) ...[
                        _HeroBanner(
                          settings: specialSettings,
                          onOrderNow: heroItem == null
                              ? null
                              : () => onOpenItem(heroItem),
                        ),
                        const SizedBox(height: 22),
                      ],
                      const SectionHeader(title: 'Categories'),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 42,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            final category =
                                controller.customerCategories[index];
                            final selected =
                                category == controller.selectedMenuCategory;
                            return ChoiceChip(
                              selected: selected,
                              onSelected: (_) => onBrowseCategory(category),
                              selectedColor: AppTheme.periRed,
                              backgroundColor: Colors.white,
                              side: BorderSide.none,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              label: Text(
                                category,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : AppTheme.ashGrey,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemCount: controller.customerCategories.length,
                        ),
                      ),
                      const SizedBox(height: 22),
                      SectionHeader(
                        title: 'Featured Meals',
                        actionLabel: 'View All',
                        onActionTap: onBrowseMenu,
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.crossAxisExtent;
                    final crossAxisCount = width > 760
                        ? 4
                        : width > 560
                        ? 3
                        : 2;
                    return SliverGrid(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final item = controller.featuredItems[index];
                        return FoodCard(
                          item: item,
                          onTap: () => onOpenItem(item),
                          onAdd: () => controller.addToCart(item),
                        );
                      }, childCount: controller.featuredItems.length),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.72,
                      ),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: const SectionHeader(title: "Today's Specials"),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                sliver: SliverList.separated(
                  itemBuilder: (context, index) {
                    final item = controller.todaysSpecials[index];
                    return FoodCard(
                      item: item,
                      compact: true,
                      onTap: () => onOpenItem(item),
                      onAdd: () => controller.addToCart(item),
                    );
                  },
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemCount: controller.todaysSpecials.length,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.settings, required this.onOrderNow});

  final TodaysSpecialSettings settings;
  final VoidCallback? onOrderNow;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [Color(0xFF161616), Color(0xFF2A1912)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            bottom: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x44F07820),
              ),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(26),
                bottomRight: Radius.circular(26),
              ),
              child: _PromoImage(
                imagePath: settings.imagePath,
                width: 170,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 190),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    settings.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.chesaOrange,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    settings.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 30,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    settings.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: onOrderNow,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(128, 42),
                    ),
                    child: const Text('Order Now'),
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

class _PromoImage extends StatelessWidget {
  const _PromoImage({
    required this.imagePath,
    required this.width,
    required this.fit,
  });

  final String imagePath;
  final double width;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final isRemote =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');

    return Image(
      image: isRemote ? NetworkImage(imagePath) : AssetImage(imagePath),
      width: width,
      fit: fit,
      errorBuilder: (context, _, _) {
        return Image.asset(
          'assets/images/brand_mark.png',
          width: width,
          fit: fit,
        );
      },
    );
  }
}
