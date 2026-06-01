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

    return BottomAppBar(
      height: 84,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: Colors.white,
      elevation: 14,
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
    );
  }
}

class CartFab extends StatelessWidget {
  const CartFab({
    super.key,
    required this.count,
    required this.onTap,
  });

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        FloatingActionButton(
          heroTag: 'cart-fab',
          onPressed: onTap,
          backgroundColor: AppTheme.periRed,
          foregroundColor: Colors.white,
          child: const Icon(Icons.shopping_cart_rounded),
        ),
        if (count > 0)
          Positioned(
            right: -2,
            top: -4,
            child: Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppTheme.chesaOrange,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                    ),
              ),
            ),
          ),
      ],
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
    final color = selected ? AppTheme.periRed : AppTheme.ashGrey;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
