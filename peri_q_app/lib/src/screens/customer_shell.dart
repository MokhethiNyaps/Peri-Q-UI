import 'dart:async';

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

class _CustomerShellState extends State<CustomerShell>
    with WidgetsBindingObserver {
  late int currentIndex;
  Timer? _storeClockTimer;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex.clamp(0, 3).toInt();
    WidgetsBinding.instance.addObserver(this);
    _storeClockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _storeClockTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.controller.refreshData().catchError((_) {
        // Existing content remains available after a transient refresh failure.
      });
    }
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

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: currentIndex, children: pages),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          return CartFab(
            count: widget.controller.cartCount,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CartScreen(controller: widget.controller),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: AnimatedBuilder(
        animation: widget.controller,
        builder: (context, _) {
          return AppBottomNav(
            currentIndex: currentIndex,
            cartCount: widget.controller.cartCount,
            onSelected: (index) => setState(() => currentIndex = index),
            onCartTap: () {},
          );
        },
      ),
    );
  }
}
