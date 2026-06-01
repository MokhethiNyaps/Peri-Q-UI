import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../models/menu_item.dart';

class AdminMenuItemEditorScreen extends StatefulWidget {
  const AdminMenuItemEditorScreen({
    super.key,
    required this.controller,
    this.item,
  });

  final AppController controller;
  final MenuItemModel? item;

  @override
  State<AdminMenuItemEditorScreen> createState() =>
      _AdminMenuItemEditorScreenState();
}

class _AdminMenuItemEditorScreenState extends State<AdminMenuItemEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  late final TextEditingController priceController;
  late String selectedCategory;
  late String selectedImagePath;
  late bool isAvailable;

  late final List<String> categoryOptions;
  late final List<String> imageOptions;

  bool get isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    final categories = widget.controller.categories
        .where((category) => category != 'All')
        .toList();
    categoryOptions = categories.isEmpty ? ['General'] : categories;
    imageOptions = {
      ...widget.controller.menuItems.map((menuItem) => menuItem.imagePath),
      'assets/images/brand_mark.png',
    }.toList();

    nameController = TextEditingController(text: item?.name ?? '');
    descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    priceController = TextEditingController(
      text: item?.price.toStringAsFixed(0) ?? '',
    );
    selectedCategory = item?.category ?? categoryOptions.first;
    selectedImagePath = item?.imagePath ?? imageOptions.first;
    isAvailable = item?.isAvailable ?? true;
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final price = double.parse(priceController.text.trim());

    if (isEditing) {
      await widget.controller.updateMenuItem(
        widget.item!.copyWith(
          name: nameController.text.trim(),
          description: descriptionController.text.trim(),
          price: price,
          category: selectedCategory,
          imagePath: selectedImagePath,
          isAvailable: isAvailable,
        ),
      );
    } else {
      await widget.controller.addMenuItem(
        MenuItemModel(
          id: 'menu-${DateTime.now().millisecondsSinceEpoch}',
          name: nameController.text.trim(),
          description: descriptionController.text.trim(),
          price: price,
          category: selectedCategory,
          imagePath: selectedImagePath,
          isAvailable: isAvailable,
        ),
      );
    }

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Menu Item' : 'Add Menu Item'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.asset(
                selectedImagePath,
                height: 210,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Changes stay in mock app state for now and are ready to connect to the backend later.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Item Name'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter an item name.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a short description.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Price (R)'),
              validator: (value) {
                final price = double.tryParse(value?.trim() ?? '');
                if (price == null || price <= 0) {
                  return 'Enter a valid price.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: categoryOptions.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => selectedCategory = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedImagePath,
              decoration: const InputDecoration(labelText: 'Image Preset'),
              items: imageOptions.map((imagePath) {
                final fileName = imagePath.split('/').last;
                return DropdownMenuItem<String>(
                  value: imagePath,
                  child: Text(fileName),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => selectedImagePath = value);
              },
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              value: isAvailable,
              contentPadding: EdgeInsets.zero,
              title: const Text('Available to customers'),
              subtitle: const Text(
                'Turn this off to keep the item hidden from ordering.',
              ),
              onChanged: (value) => setState(() => isAvailable = value),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () => _save(),
            child: Text(isEditing ? 'Save Changes' : 'Add Menu Item'),
          ),
        ),
      ),
    );
  }
}
