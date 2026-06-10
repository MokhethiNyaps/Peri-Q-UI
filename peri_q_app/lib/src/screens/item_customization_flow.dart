import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../models/menu_item.dart';
import '../widgets/app_image.dart';
import 'cart_screen.dart';

Future<void> showItemCustomizationFlow(
  BuildContext context,
  AppController controller,
  MenuItemModel item,
) async {
  final addedToCart = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (context) {
      return _CustomizerSheet(controller: controller, item: item);
    },
  );

  if (addedToCart != true || !context.mounted) {
    return;
  }

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CartScreen(controller: controller),
    ),
  );
}

class _CustomizerSheet extends StatefulWidget {
  const _CustomizerSheet({
    required this.controller,
    required this.item,
  });

  final AppController controller;
  final MenuItemModel item;

  @override
  State<_CustomizerSheet> createState() => _CustomizerSheetState();
}

class _CustomizerSheetState extends State<_CustomizerSheet> {
  late String selectedSpice;
  late List<AddOnOption> selectedAddOns;
  final notesController = TextEditingController();
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    selectedSpice = widget.item.spiceLevels.first;
    selectedAddOns = [];
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  double get total {
    final addOnTotal = selectedAddOns.fold<double>(0, (sum, item) => sum + item.price);
    return (widget.item.price + addOnTotal) * quantity;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppImage(
                imagePath: widget.item.imagePath,
                width: double.infinity,
                height: 220,
                borderRadius: BorderRadius.circular(24),
              ),
              const SizedBox(height: 18),
              Text(widget.item.name, style: Theme.of(context).textTheme.displayLarge),
              const SizedBox(height: 8),
              Text(widget.item.description, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8),
              Text(
                'R${widget.item.price.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.periRed,
                    ),
              ),
              const SizedBox(height: 20),
              Text('Spice Level', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: widget.item.spiceLevels.map((level) {
                  final selected = level == selectedSpice;
                  return ChoiceChip(
                    selected: selected,
                    onSelected: (_) => setState(() => selectedSpice = level),
                    selectedColor: AppTheme.periRed,
                    backgroundColor: AppTheme.mutedSurface,
                    label: Text(
                      level,
                      style: TextStyle(
                        color: selected ? Colors.white : AppTheme.ashGrey,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              if (widget.item.addOns.isNotEmpty) ...[
                Text('Add-ons', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                ...widget.item.addOns.map((option) {
                  final selected = selectedAddOns.contains(option);
                  return CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: selected,
                    activeColor: AppTheme.periRed,
                    title: Text(option.name),
                    subtitle: Text('+R${option.price.toStringAsFixed(0)}'),
                    onChanged: (_) {
                      setState(() {
                        if (selected) {
                          selectedAddOns.remove(option);
                        } else {
                          selectedAddOns = [...selectedAddOns, option];
                        }
                      });
                    },
                  );
                }),
              ],
              const SizedBox(height: 12),
              Text('Store Notes', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'No onions, extra sauce, cut in half...',
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.mutedSurface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: quantity == 1
                              ? null
                              : () => setState(() => quantity -= 1),
                          icon: const Icon(Icons.remove_rounded),
                        ),
                        Text(
                          '$quantity',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          onPressed: () => setState(() => quantity += 1),
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.controller.addToCart(
                          widget.item,
                          quantity: quantity,
                          spiceLevel: selectedSpice,
                          notes: notesController.text.trim(),
                          selectedAddOns: selectedAddOns,
                        );
                        Navigator.of(context).pop(true);
                      },
                      child: Text('Add • R${total.toStringAsFixed(0)}'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
