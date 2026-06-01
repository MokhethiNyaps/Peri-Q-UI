import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../widgets/app_bottom_nav.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import 'item_customization_flow.dart';
import 'menu_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({
    super.key,
    required this.controller,
    this.initialIndex = 0,
  });

  final AppController controller;
  final int initialIndex;

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        controller: widget.controller,
        onBrowseMenu: () {
          widget.controller.setSelectedMenuCategory('All');
          setState(() => currentIndex = 1);
        },
        onBrowseCategory: (category) {
          widget.controller.setSelectedMenuCategory(category);
          setState(() => currentIndex = 1);
        },
        onOpenItem: (item) {
          showItemCustomizationFlow(context, widget.controller, item);
        },
      ),
      MenuScreen(controller: widget.controller),
      OrdersScreen(controller: widget.controller),
      ProfileScreen(controller: widget.controller),
    ];

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Scaffold(
          body: IndexedStack(index: currentIndex, children: pages),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          floatingActionButton: CartFab(
            count: widget.controller.cartCount,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CartScreen(controller: widget.controller),
                ),
              );
            },
          ),
          bottomNavigationBar: AppBottomNav(
            currentIndex: currentIndex,
            cartCount: widget.controller.cartCount,
            onSelected: (index) => setState(() => currentIndex = index),
            onCartTap: () {},
          ),
        );
      },
    );
  }
}
