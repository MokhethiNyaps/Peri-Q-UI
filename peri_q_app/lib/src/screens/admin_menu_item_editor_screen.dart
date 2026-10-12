import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../models/menu_item.dart';
import '../widgets/app_image.dart';

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
  late final TextEditingController imagePathController;
  late String selectedCategory;
  late bool isAvailable;

  late final List<String> categoryOptions;
  late final List<String> imageOptions;
  bool isSaving = false;
  bool isUploadingImage = false;

  bool get isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    final categories = widget.controller.categories
        .where((category) => category != 'All')
        .toList();
    categoryOptions = categories.isEmpty ? ['General'] : categories;
    if (item != null && !categoryOptions.contains(item.category)) {
      categoryOptions = [...categoryOptions, item.category];
    }
    imageOptions = {
      ...widget.controller.menuItems.map((menuItem) => menuItem.imagePath),
      'assets/images/white-app-icon.png',
    }.toList();

    nameController = TextEditingController(text: item?.name ?? '');
    descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    priceController = TextEditingController(
      text: item?.price.toStringAsFixed(0) ?? '',
    );
    imagePathController = TextEditingController(
      text: item?.imagePath ?? imageOptions.first,
    );
    selectedCategory = item?.category ?? categoryOptions.first;
    isAvailable = item?.isAvailable ?? true;
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    imagePathController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final pickedFile = result.files.single;
    final bytes = pickedFile.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read the selected image.')),
      );
      return;
    }
    final extension = (pickedFile.extension ?? pickedFile.name.split('.').last)
        .toLowerCase();
    const allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};
    if (!allowedExtensions.contains(extension) ||
        bytes.length > 5 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose a JPG, PNG or WebP image smaller than 5 MB.'),
        ),
      );
      return;
    }

    setState(() => isUploadingImage = true);
    try {
      final imageUrl = await widget.controller.uploadMenuItemImage(
        bytes: Uint8List.fromList(bytes),
        fileName: pickedFile.name,
        contentType: _contentTypeFor(pickedFile.extension ?? pickedFile.name),
      );

      if (!mounted) {
        return;
      }
      setState(() => imagePathController.text = imageUrl);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Image uploaded.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The image could not be uploaded. Check the file and connection, then try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isUploadingImage = false);
      }
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final price = double.parse(priceController.text.trim());

    setState(() => isSaving = true);
    try {
      if (isEditing) {
        await widget.controller.updateMenuItem(
          widget.item!.copyWith(
            name: nameController.text.trim(),
            description: descriptionController.text.trim(),
            price: price,
            category: selectedCategory,
            imagePath: imagePathController.text.trim(),
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
            imagePath: imagePathController.text.trim(),
            isAvailable: isAvailable,
          ),
        );
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
    final selectedPreset = imageOptions.contains(imagePathController.text)
        ? imagePathController.text
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Menu Item' : 'Add Menu Item'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
          children: [
            AppImage(
              imagePath: imagePathController.text,
              width: double.infinity,
              height: 210,
              borderRadius: BorderRadius.circular(22),
            ),
            const SizedBox(height: 16),
            Text(
              'Changes save directly to the RastasperiQ database and update the app menu after saving.',
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
                if (price == null || price < 0) {
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
              initialValue: selectedPreset,
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
                setState(() => imagePathController.text = value);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: imagePathController,
              decoration: const InputDecoration(
                labelText: 'Image Path or Public URL',
                hintText: 'assets/images/white-app-icon.png',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Upload an image or enter an image path.';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isUploadingImage ? null : _pickAndUploadImage,
              icon: isUploadingImage
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_rounded),
              label: Text(
                isUploadingImage ? 'Uploading image...' : 'Upload Image',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Images upload to the Supabase menu-images bucket and this item stores the public URL.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
            onPressed: isSaving || isUploadingImage ? null : _save,
            child: Text(
              isSaving
                  ? 'Saving...'
                  : isEditing
                  ? 'Save Changes'
                  : 'Add Menu Item',
            ),
          ),
        ),
      ),
    );
  }

  String _contentTypeFor(String fileNameOrExtension) {
    final extension = fileNameOrExtension.split('.').last.trim().toLowerCase();
    return switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'application/octet-stream',
    };
  }
}
