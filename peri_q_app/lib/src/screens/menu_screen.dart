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
                          height: 46,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                widget.controller.customerCategories.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 10),
                            itemBuilder: (context, index) {
                              final category =
                                  widget.controller.customerCategories[index];
                              final selected =
                                  category ==
                                  widget.controller.selectedMenuCategory;
                              return ChoiceChip(
                                selected: selected,
                                onSelected: (_) => widget.controller
                                    .setSelectedMenuCategory(category),
                                selectedColor: AppTheme.periRed,
                                backgroundColor: Colors.white,
                                side: BorderSide.none,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                label: Text(
                                  category.toUpperCase(),
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : AppTheme.ashGrey,
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
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 160),
                      itemCount: filteredItems.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
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
                        color: AppTheme.periRed,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33C8240B),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${widget.controller.cartCount} item${widget.controller.cartCount == 1 ? '' : 's'} in cart',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: Colors.white),
                            ),
                          ),
                          Text(
                            'R${widget.controller.subtotal.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.shopping_bag_rounded,
                            color: Colors.white,
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
