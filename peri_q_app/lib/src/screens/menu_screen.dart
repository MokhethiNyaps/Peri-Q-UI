import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../models/menu_item.dart';
import '../widgets/food_card.dart';
import 'cart_screen.dart';
import 'item_customization_flow.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<MenuItemModel> get filteredItems {
    return widget.controller.availableMenuItems.where((item) {
      final categoryMatch =
          widget.controller.selectedMenuCategory == 'All' ||
          item.category == widget.controller.selectedMenuCategory;
      final query = searchController.text.toLowerCase();
      final searchMatch =
          query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);
      return categoryMatch && searchMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          final items = filteredItems;
          final categories = widget.controller.customerCategories;
          final theme = Theme.of(context);
          final colors = theme.colorScheme;
          final appColors = context.appColors;
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final categoryRailHeight = (46 + ((textScale - 1) * 20))
              .clamp(46.0, 72.0)
              .toDouble();
          return Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Full Menu',
                          style: Theme.of(context).textTheme.displayLarge,
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: searchController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search_rounded),
                            hintText: 'Search meals, wors, drinks...',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          height: categoryRailHeight,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: categories.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final category = categories[index];
                              final selected =
                                  category ==
                                  widget.controller.selectedMenuCategory;
                              return ChoiceChip(
                                selected: selected,
                                onSelected: (_) => widget.controller
                                    .setSelectedMenuCategory(category),
                                selectedColor: colors.primary,
                                backgroundColor: appColors.elevatedSurface,
                                side: BorderSide(color: appColors.softOutline),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                label: Text(
                                  category.toUpperCase(),
                                  style: TextStyle(
                                    color: selected
                                        ? colors.onPrimary
                                        : colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: items.isEmpty
                        ? RefreshIndicator(
                            onRefresh: widget.controller.refreshData,
                            child: ListView(
                              padding: const EdgeInsets.all(32),
                              children: [
                                const SizedBox(height: 80),
                                Icon(
                                  Icons.search_off_rounded,
                                  size: 54,
                                  color: colors.onSurfaceVariant,
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  searchController.text.isEmpty
                                      ? 'No meals are available right now.'
                                      : 'No meals match your search.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Pull down to refresh the menu.',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 160),
                            itemCount: items.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              return FoodCard(
                                item: item,
                                compact: true,
                                onTap: () => showItemCustomizationFlow(
                                  context,
                                  widget.controller,
                                  item,
                                ),
                                onAdd: () => widget.controller.addToCart(item),
                              );
                            },
                          ),
                  ),
                ],
              ),
              if (widget.controller.cartCount > 0)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 96,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              CartScreen(controller: widget.controller),
                        ),
                      );
                    },
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        border: Border.all(
                          color: colors.onPrimary.withValues(alpha: 0.22),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: appColors.shadow,
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${widget.controller.cartCount} item${widget.controller.cartCount == 1 ? '' : 's'} in cart',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: colors.onPrimary),
                            ),
                          ),
                          Text(
                            'R${widget.controller.subtotal.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: colors.onPrimary),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.shopping_bag_rounded,
                            color: colors.onPrimary,
                            semanticLabel: 'View cart',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
