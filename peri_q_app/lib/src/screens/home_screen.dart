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
          final availableItems = controller.availableMenuItems;
          final featuredItems = controller.featuredItems;
          final todaysSpecials = controller.todaysSpecials;
          final categories = controller.customerCategories;
          final theme = Theme.of(context);
          final colors = theme.colorScheme;
          final appColors = context.appColors;
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final categoryRailHeight = (46 + ((textScale - 1) * 20))
              .clamp(46.0, 72.0)
              .toDouble();

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
                        const Text('BLOEMFONTEIN · FLAME-GRILLED CHESANYAMA'),
                        const SizedBox(height: 20),
                        const SectionHeader(title: 'Find your fire'),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: categoryRailHeight,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              final selected =
                                  category == controller.selectedMenuCategory;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: ChoiceChip(
                                  selected: selected,
                                  showCheckmark: false,
                                  onSelected: (_) => onBrowseCategory(category),
                                  selectedColor: colors.primary,
                                  backgroundColor: appColors.elevatedSurface,
                                  side: BorderSide(
                                    color: selected
                                        ? colors.primary
                                        : appColors.softOutline,
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
                                          ? colors.onPrimary
                                          : colors.onSurfaceVariant,
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
                            itemCount: categories.length,
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
                if (availableItems.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(26),
                        decoration: BoxDecoration(
                          color: appColors.elevatedSurface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: appColors.softOutline),
                          boxShadow: [
                            BoxShadow(
                              color: appColors.shadow,
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: colors.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.restaurant_menu_rounded,
                                size: 30,
                                color: colors.onPrimaryContainer,
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
                  padding: EdgeInsets.fromLTRB(
                    20,
                    0,
                    20,
                    todaysSpecials.isEmpty ? 120 : 12,
                  ),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.crossAxisExtent;
                      final useListLayout = width < 560 || textScale > 1.25;
                      final crossAxisCount = width > 760
                          ? 4
                          : width > 560
                          ? 3
                          : 2;
                      if (useListLayout) {
                        return SliverList.separated(
                          itemCount: featuredItems.length,
                          itemBuilder: (context, index) {
                            final item = featuredItems[index];
                            return FoodCard(
                              item: item,
                              compact: true,
                              onTap: () => onOpenItem(item),
                              onAdd: () => controller.addToCart(item),
                            );
                          },
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: AppSpacing.md),
                        );
                      }
                      return SliverGrid(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = featuredItems[index];
                          return FoodCard(
                            item: item,
                            onTap: () => onOpenItem(item),
                            onAdd: () => controller.addToCart(item),
                          );
                        }, childCount: featuredItems.length),
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
                if (todaysSpecials.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                      child: const SectionHeader(title: "Today's Specials"),
                    ),
                  ),
                if (todaysSpecials.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverList.separated(
                      itemBuilder: (context, index) {
                        final item = todaysSpecials[index];
                        return FoodCard(
                          item: item,
                          compact: true,
                          onTap: () => onOpenItem(item),
                          onAdd: () => controller.addToCart(item),
                        );
                      },
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemCount: todaysSpecials.length,
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final appColors = context.appColors;

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
                color: appColors.elevatedSurface,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: appColors.softOutline),
                boxShadow: [
                  BoxShadow(
                    color: appColors.shadow,
                    blurRadius: 18,
                    offset: const Offset(0, 8),
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
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "RastasperiQ",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: colors.onSurface,
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
    final appColors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: appColors.warningContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: appColors.onWarningContainer.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.offline_bolt_rounded, color: appColors.onWarningContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Showing the last saved menu. Reconnect to see updates.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: appColors.onWarningContainer,
                fontWeight: FontWeight.w700,
              ),
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
    final colors = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    final background = isOpen
        ? appColors.successContainer
        : appColors.dangerContainer;
    final foreground = isOpen
        ? appColors.onSuccessContainer
        : appColors.onDangerContainer;
    final indicator = isOpen ? appColors.success : colors.error;

    return Semantics(
      liveRegion: true,
      label: 'Store status: ${controller.storeStatusLabel}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: foreground.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: indicator,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  controller.storeStatusLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
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
    final colors = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = MediaQuery.sizeOf(context);
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final isLandscape = viewport.width > viewport.height;
        final compact = constraints.maxWidth < 360;
        final accessibleText = textScale > 1.25;
        final imageWidth =
            constraints.maxWidth *
            (accessibleText ? 0.42 : (compact ? 0.55 : 0.58));
        final baseBannerHeight = isLandscape
            ? (compact ? 156.0 : 150.0)
            : (compact ? 226.0 : 214.0);
        final bannerHeight = (baseBannerHeight + ((textScale - 1) * 100))
            .clamp(baseBannerHeight, 340.0)
            .toDouble();
        final contentPadding = isLandscape
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
            : EdgeInsets.all(compact ? 18 : 22);
        final maxContentWidth = accessibleText
            ? constraints.maxWidth * 0.78
            : isLandscape
            ? 210.0
            : (compact ? 205.0 : 235.0);
        final titleFontSize = isLandscape ? 22.0 : (compact ? 27.0 : 30.0);

        return Container(
          height: bannerHeight,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: appColors.heroSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: appColors.heroOnSurface.withValues(alpha: 0.16),
            ),
            boxShadow: [
              BoxShadow(
                color: appColors.shadow,
                blurRadius: 30,
                offset: const Offset(0, 16),
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
              Padding(
                padding: contentPadding,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxContentWidth),
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
                          color: appColors.heroOnSurface.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: appColors.heroOnSurface.withValues(
                              alpha: 0.32,
                            ),
                          ),
                        ),
                        child: Text(
                          settings.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: appColors.heroOnSurface,
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      SizedBox(height: isLandscape ? 6 : 9),
                      Text(
                        settings.title,
                        maxLines: accessibleText
                            ? 3
                            : isLandscape
                            ? 1
                            : 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(
                              color: appColors.heroOnSurface,
                              fontSize: titleFontSize,
                              fontWeight: FontWeight.w800,
                              height: 0.98,
                            ),
                      ),
                      SizedBox(height: isLandscape ? 4 : 8),
                      if (!isLandscape && !accessibleText)
                        Text(
                          settings.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: appColors.heroOnSurface.withValues(
                                  alpha: 0.78,
                                ),
                                height: 1.35,
                              ),
                        ),
                      SizedBox(height: isLandscape ? 8 : 13),
                      ElevatedButton.icon(
                        onPressed: onOrderNow,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(
                            isLandscape ? 120 : 138,
                            accessibleText
                                ? 52
                                : isLandscape
                                ? 40
                                : 44,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                        ),
                        icon: Icon(
                          Icons.local_fire_department_rounded,
                          size: isLandscape ? 16 : 18,
                        ),
                        label: Text(
                          'Order Now',
                          style: TextStyle(fontSize: isLandscape ? 13 : null),
                        ),
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
