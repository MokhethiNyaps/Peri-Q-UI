import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../models/menu_item.dart';
import '../models/todays_special_settings.dart';
import '../widgets/app_image.dart';
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

          return RefreshIndicator(
            onRefresh: controller.refreshData,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HomeHeader(controller: controller),
                        const SizedBox(height: 22),
                        if (controller.isMenuStale) ...[
                          _OfflineMenuBanner(
                            onRetry: () => controller.refreshData(),
                          ),
                          const SizedBox(height: 14),
                        ],
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
                          height: 46,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              final category =
                                  controller.customerCategories[index];
                              final selected =
                                  category == controller.selectedMenuCategory;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: selected
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.periRed.withValues(
                                              alpha: 0.2,
                                            ),
                                            blurRadius: 16,
                                            offset: const Offset(0, 7),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: ChoiceChip(
                                  selected: selected,
                                  showCheckmark: false,
                                  onSelected: (_) => onBrowseCategory(category),
                                  selectedColor: AppTheme.periRed,
                                  backgroundColor: Colors.white,
                                  side: BorderSide(
                                    color: selected
                                        ? AppTheme.periRed
                                        : Colors.black.withValues(alpha: 0.05),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  label: Text(
                                    category.toUpperCase(),
                                    style: TextStyle(
                                      color: selected
                                          ? Colors.white
                                          : AppTheme.ashGrey,
                                      fontSize: 12,
                                      letterSpacing: 0.3,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              );
                            },
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 10),
                            itemCount: controller.customerCategories.length,
                          ),
                        ),
                        const SizedBox(height: 26),
                        SectionHeader(
                          title: 'Featured Meals',
                          actionLabel: 'View All',
                          onActionTap: onBrowseMenu,
                        ),
                      ],
                    ),
                  ),
                ),
                if (controller.availableMenuItems.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(26),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.05),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x12000000),
                              blurRadius: 24,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppTheme.periRed.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.restaurant_menu_rounded,
                                size: 30,
                                color: AppTheme.periRed,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Today’s menu is not published yet.',
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Pull down to check again or contact the store for help.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            TextButton.icon(
                              onPressed: () => controller.refreshData(),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Try again'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.crossAxisExtent;
                      final textScale = MediaQuery.textScalerOf(
                        context,
                      ).scale(1);
                      final crossAxisCount = width > 760
                          ? 4
                          : width > 560
                          ? 3
                          : width < 360 || textScale > 1.3
                          ? 1
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
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 10),
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
            ),
          );
        },
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final firstName = controller.customerName.trim().split(' ').firstOrNull;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 390;
        final brandIdentity = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppTheme.lightSurface,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/images/white-app-icon.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    firstName == null || firstName.isEmpty
                        ? 'WELCOME TO'
                        : 'WELCOME BACK, ${firstName.toUpperCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.ashGrey,
                      fontSize: 10,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "RastasperiQ",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.smokeCharcoal,
                      fontSize: isNarrow ? 26 : null,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              brandIdentity,
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: _StoreStatusBadge(controller: controller),
              ),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: brandIdentity),
            const SizedBox(width: 12),
            _StoreStatusBadge(controller: controller),
          ],
        );
      },
    );
  }
}

class _OfflineMenuBanner extends StatelessWidget {
  const _OfflineMenuBanner({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: AppTheme.warning.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.offline_bolt_rounded, color: AppTheme.warning),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Showing the last saved menu. Reconnect to see updates.',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _StoreStatusBadge extends StatelessWidget {
  const _StoreStatusBadge({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final isOpen = controller.isStoreOpenNow;
    final color = isOpen ? AppTheme.success : AppTheme.periRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              controller.storeStatusLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final imageWidth = constraints.maxWidth * (compact ? 0.55 : 0.58);

        return Container(
          height: compact ? 226 : 214,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppTheme.smokeCharcoal,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 30,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: imageWidth,
                child: AppImage(
                  imagePath: settings.imagePath,
                  width: imageWidth,
                  fit: BoxFit.cover,
                  semanticLabel: "Today's Special",
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xFF151515),
                      Color(0xF21A1715),
                      Color(0xA61A1715),
                      Color(0x001A1715),
                    ],
                    stops: [0, 0.48, 0.72, 1],
                  ),
                ),
              ),
              Positioned(
                right: -55,
                bottom: -80,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.chesaOrange.withValues(alpha: 0.17),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(compact ? 18 : 22),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: compact ? 205 : 235),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.chesaOrange.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppTheme.chesaOrange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          settings.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: AppTheme.chesaOrange,
                                fontSize: 10,
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        settings.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(
                              color: Colors.white,
                              fontSize: compact ? 27 : 30,
                              fontWeight: FontWeight.w800,
                              height: 0.98,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        settings.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 13),
                      ElevatedButton.icon(
                        onPressed: onOrderNow,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(138, 42),
                          maximumSize: const Size(164, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          backgroundColor: AppTheme.periRed,
                        ),
                        icon: const Icon(
                          Icons.local_fire_department_rounded,
                          size: 18,
                        ),
                        label: const Text('Order Now'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
