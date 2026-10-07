import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onSelected,
    required this.cartCount,
    required this.onCartTap,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;
  final int cartCount;
  final VoidCallback onCartTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'Home'),
      (Icons.restaurant_menu_rounded, 'Menu'),
      (Icons.receipt_long_rounded, 'Orders'),
      (Icons.person_rounded, 'Profile'),
    ];

    final appColors = context.appColors;

    return SafeArea(
      top: false,
      child: BottomAppBar(
        height: 84,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: appColors.elevatedSurface,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Row(
          children: [
            for (var index = 0; index < 2; index++)
              Expanded(
                child: _NavItem(
                  icon: items[index].$1,
                  label: items[index].$2,
                  selected: currentIndex == index,
                  onTap: () => onSelected(index),
                ),
              ),
            const SizedBox(width: 56),
            for (var index = 2; index < items.length; index++)
              Expanded(
                child: _NavItem(
                  icon: items[index].$1,
                  label: items[index].$2,
                  selected: currentIndex == index,
                  onTap: () => onSelected(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CartFab extends StatelessWidget {
  const CartFab({super.key, required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final countLabel = count > 99 ? '99+' : '$count';
    final semanticLabel = count == 0
        ? 'Open cart, empty'
        : 'Open cart, $count item${count == 1 ? '' : 's'}';

    return Semantics(
      button: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: Tooltip(
          message: semanticLabel,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              FloatingActionButton(
                heroTag: 'cart-fab',
                onPressed: onTap,
                child: const Icon(Icons.shopping_cart_rounded),
              ),
              if (count > 0)
                Positioned(
                  right: -5,
                  top: -5,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      border: Border.all(color: colors.onSecondaryContainer),
                    ),
                    child: Text(
                      countLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSecondaryContainer,
                        fontWeight: FontWeight.w900,
                      ),
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = selected ? colors.primary : colors.onSurfaceVariant;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.input),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
