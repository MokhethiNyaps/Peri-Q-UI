import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../models/menu_category.dart';

class AdminCategoryManagerScreen extends StatelessWidget {
  const AdminCategoryManagerScreen({super.key, required this.controller});

  final AppController controller;

  Future<void> _openEditor(
    BuildContext context, {
    MenuCategoryModel? category,
  }) async {
    final didSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return _CategoryEditorDialog(
          controller: controller,
          category: category,
        );
      },
    );

    if (didSave != true || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(category == null ? 'Category added.' : 'Category saved.'),
      ),
    );
  }

  Future<void> _deleteCategory(
    BuildContext context,
    MenuCategoryModel category,
  ) async {
    final itemCount = controller.menuItems
        .where((item) => item.category == category.name)
        .length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete category?'),
          content: Text(
            itemCount == 0
                ? '${category.name} will be removed.'
                : '${category.name} still has $itemCount menu item${itemCount == 1 ? '' : 's'}. Move or edit those items first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: itemCount == 0
                  ? () => Navigator.of(context).pop(true)
                  : null,
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    try {
      await controller.deleteMenuCategory(category);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${category.name} deleted.')));
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Categories')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openEditor(context),
            backgroundColor: AppTheme.periRed,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Category'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            children: [
              if (controller.menuCategories.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text('No categories found.'),
                )
              else
                ...controller.menuCategories.map((category) {
                  final itemCount = controller.menuItems
                      .where((item) => item.category == category.name)
                      .length;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: category.isActive
                                  ? AppTheme.success.withValues(alpha: 0.12)
                                  : AppTheme.ashGrey.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${category.sortOrder}',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: category.isActive
                                        ? AppTheme.success
                                        : AppTheme.ashGrey,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  '${category.isActive ? 'Active' : 'Hidden'} • $itemCount item${itemCount == 1 ? '' : 's'}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                _openEditor(context, category: category),
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            onPressed: () => _deleteCategory(context, category),
                            icon: const Icon(Icons.delete_outline_rounded),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryEditorDialog extends StatefulWidget {
  const _CategoryEditorDialog({required this.controller, this.category});

  final AppController controller;
  final MenuCategoryModel? category;

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController sortOrderController;
  late bool isActive;
  bool isSaving = false;

  bool get isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    nameController = TextEditingController(text: category?.name ?? '');
    sortOrderController = TextEditingController(
      text: '${category?.sortOrder ?? _nextSortOrder()}',
    );
    isActive = category?.isActive ?? true;
  }

  @override
  void dispose() {
    nameController.dispose();
    sortOrderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final category = MenuCategoryModel(
      id: widget.category?.id ?? _categoryIdFromName(nameController.text),
      name: nameController.text.trim(),
      sortOrder: int.parse(sortOrderController.text.trim()),
      isActive: isActive,
    );

    setState(() => isSaving = true);
    try {
      if (isEditing) {
        await widget.controller.updateMenuCategory(category);
      } else {
        await widget.controller.addMenuCategory(category);
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Edit Category' : 'Add Category'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Category Name'),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a category name.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: sortOrderController,
              decoration: const InputDecoration(labelText: 'Sort Order'),
              keyboardType: TextInputType.number,
              validator: (value) {
                final order = int.tryParse(value?.trim() ?? '');
                if (order == null) {
                  return 'Enter a number.';
                }
                return null;
              },
            ),
            const SizedBox(height: 4),
            SwitchListTile.adaptive(
              value: isActive,
              contentPadding: EdgeInsets.zero,
              title: const Text('Show to customers'),
              onChanged: (value) => setState(() => isActive = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isSaving ? null : _save,
          child: Text(isSaving ? 'Saving...' : 'Save'),
        ),
      ],
    );
  }

  int _nextSortOrder() {
    if (widget.controller.menuCategories.isEmpty) {
      return 10;
    }
    final maxOrder = widget.controller.menuCategories
        .map((category) => category.sortOrder)
        .reduce((value, element) => value > element ? value : element);
    return maxOrder + 10;
  }

  String _categoryIdFromName(String value) {
    final slug = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final safeSlug = slug.isEmpty ? 'category' : slug;
    return 'cat-$safeSlug-${DateTime.now().millisecondsSinceEpoch}';
  }
}
