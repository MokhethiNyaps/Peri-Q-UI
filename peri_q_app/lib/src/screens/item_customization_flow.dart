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
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (context) {
      return _CustomizerSheet(controller: controller, item: item);
    },
  );

  if (addedToCart != true || !context.mounted) {
    return;
  }

  await Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => CartScreen(controller: controller)));
}

class _CustomizerSheet extends StatefulWidget {
  const _CustomizerSheet({required this.controller, required this.item});

  final AppController controller;
  final MenuItemModel item;

  @override
  State<_CustomizerSheet> createState() => _CustomizerSheetState();
}

class _CustomizerSheetState extends State<_CustomizerSheet> {
  String? selectedSpice;
  late List<AddOnOption> selectedAddOns;
  final notesController = TextEditingController();
  int quantity = 1;

  @override
  void initState() {
    super.initState();
    selectedSpice = widget.item.spiceLevels.isEmpty
        ? null
        : widget.item.spiceLevels.first;
    selectedAddOns = [];
  }

  @override
  void dispose() {
    notesController.dispose();
    super.dispose();
  }

  double get total {
    final addOnTotal = selectedAddOns.fold<double>(
      0,
      (sum, item) => sum + item.price,
    );
    return (widget.item.price + addOnTotal) * quantity;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final appColors = context.appColors;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final stackActions = MediaQuery.sizeOf(context).width < 360 || textScale > 1.3;

    Widget quantityControl() {
      return Semantics(
        label: 'Quantity, $quantity',
        value: '$quantity',
        child: Container(
          decoration: BoxDecoration(
            color: appColors.sunkenSurface,
            borderRadius: BorderRadius.circular(AppRadii.input),
            border: Border.all(color: appColors.softOutline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Decrease quantity',
                onPressed: quantity == 1
                    ? null
                    : () => setState(() => quantity -= 1),
                icon: const Icon(Icons.remove_rounded),
              ),
              Text('$quantity', style: theme.textTheme.titleLarge),
              IconButton(
                tooltip: 'Increase quantity',
                onPressed: () => setState(() => quantity += 1),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
      );
    }

    Widget addButton() {
      return ElevatedButton(
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
        child: Text(
          'Add $quantity • R${total.toStringAsFixed(0)}',
          textAlign: TextAlign.center,
        ),
      );
    }

    return FractionallySizedBox(
      heightFactor: 0.92,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppImage(
                      imagePath: widget.item.imagePath,
                      semanticLabel: '${widget.item.name} photo',
                      width: double.infinity,
                      height: 220,
                      borderRadius: BorderRadius.circular(AppRadii.panel),
                    ),
                    const SizedBox(height: 18),
                    Text(widget.item.name, style: theme.textTheme.displayLarge),
                    const SizedBox(height: 8),
                    Text(
                      widget.item.description,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'R${widget.item.price.toStringAsFixed(0)}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: colors.primary,
                      ),
                    ),
                    if (widget.item.spiceLevels.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Spice Level', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.item.spiceLevels.map((level) {
                          final selected = level == selectedSpice;
                          return ChoiceChip(
                            selected: selected,
                            onSelected: (_) =>
                                setState(() => selectedSpice = level),
                            label: Text(level),
                          );
                        }).toList(),
                      ),
                    ],
                    if (widget.item.addOns.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Add-ons', style: theme.textTheme.titleLarge),
                      const SizedBox(height: 10),
                      ...widget.item.addOns.map((option) {
                        final selected = selectedAddOns.contains(option);
                        return CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: selected,
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
                    Text('Store Notes', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'No onions, extra sauce, cut in half...',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: appColors.elevatedSurface,
                border: Border(top: BorderSide(color: appColors.softOutline)),
                boxShadow: [
                  BoxShadow(
                    color: appColors.shadow,
                    blurRadius: 18,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: stackActions
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: quantityControl(),
                            ),
                            const SizedBox(height: 10),
                            addButton(),
                          ],
                        )
                      : Row(
                          children: [
                            quantityControl(),
                            const SizedBox(width: 12),
                            Expanded(child: addButton()),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
