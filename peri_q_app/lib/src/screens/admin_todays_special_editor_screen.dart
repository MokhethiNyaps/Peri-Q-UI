import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../models/todays_special_settings.dart';

class AdminTodaysSpecialEditorScreen extends StatefulWidget {
  const AdminTodaysSpecialEditorScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<AdminTodaysSpecialEditorScreen> createState() =>
      _AdminTodaysSpecialEditorScreenState();
}

class _AdminTodaysSpecialEditorScreenState
    extends State<AdminTodaysSpecialEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController labelController;
  late final TextEditingController titleController;
  late final TextEditingController subtitleController;
  late final TextEditingController imagePathController;
  late bool enabled;
  String? selectedMenuItemId;
  bool isSaving = false;

  late final List<String> imageOptions;

  @override
  void initState() {
    super.initState();
    final settings = widget.controller.todaysSpecialSettings;
    enabled = settings.enabled;
    selectedMenuItemId = settings.menuItemId;
    labelController = TextEditingController(text: settings.label);
    titleController = TextEditingController(text: settings.title);
    subtitleController = TextEditingController(text: settings.subtitle);
    imagePathController = TextEditingController(text: settings.imagePath);
    imageOptions = {
      ...widget.controller.menuItems.map((item) => item.imagePath),
      'assets/images/brand_mark.png',
      'assets/images/chicken_kota.png',
      'assets/images/kota_alt.png',
      'assets/images/mixed_grill.png',
      'assets/images/wings.png',
    }.toList();
  }

  @override
  void dispose() {
    labelController.dispose();
    titleController.dispose();
    subtitleController.dispose();
    imagePathController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => isSaving = true);
    try {
      await widget.controller.updateTodaysSpecialSettings(
        TodaysSpecialSettings(
          enabled: enabled,
          label: labelController.text.trim(),
          title: titleController.text.trim(),
          subtitle: subtitleController.text.trim(),
          imagePath: imagePathController.text.trim(),
          menuItemId:
              selectedMenuItemId == null || selectedMenuItemId!.trim().isEmpty
              ? null
              : selectedMenuItemId,
        ),
      );

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
      appBar: AppBar(title: const Text("Today's Special")),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                height: 210,
                child: _PromoPreviewImage(imagePath: imagePathController.text),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile.adaptive(
              value: enabled,
              contentPadding: EdgeInsets.zero,
              title: const Text('Show Today\'s Special'),
              subtitle: const Text(
                'Turn this off to hide the promotional banner from customers.',
              ),
              onChanged: (value) => setState(() => enabled = value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: labelController,
              decoration: const InputDecoration(labelText: 'Promo Label'),
              textCapitalization: TextCapitalization.characters,
              validator: _requiredText('Enter a promo label.'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: titleController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Promo Title'),
              validator: _requiredText('Enter the headline text.'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: subtitleController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Promo Subtitle'),
              validator: _requiredText('Enter the supporting text.'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedMenuItemId ?? '',
              decoration: const InputDecoration(labelText: 'Linked Menu Item'),
              items: [
                const DropdownMenuItem<String>(
                  value: '',
                  child: Text('First available item'),
                ),
                ...widget.controller.availableMenuItems.map((item) {
                  return DropdownMenuItem<String>(
                    value: item.id,
                    child: Text(item.name),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => selectedMenuItemId = value);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedPreset,
              decoration: const InputDecoration(labelText: 'Image Preset'),
              items: imageOptions.map((imagePath) {
                return DropdownMenuItem<String>(
                  value: imagePath,
                  child: Text(imagePath.split('/').last),
                );
              }).toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() => imagePathController.text = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: imagePathController,
              decoration: const InputDecoration(
                labelText: 'Image Path or URL',
                hintText: 'assets/images/chicken_kota.png',
              ),
              validator: _requiredText('Enter an image asset path or URL.'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            Text(
              'Use a bundled asset path or a public HTTPS image URL. For private uploads, connect Supabase Storage and save the public URL here.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: isSaving ? null : _save,
            child: Text(isSaving ? 'Saving...' : 'Save Today\'s Special'),
          ),
        ),
      ),
    );
  }

  FormFieldValidator<String> _requiredText(String message) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return message;
      }
      return null;
    };
  }
}

class _PromoPreviewImage extends StatelessWidget {
  const _PromoPreviewImage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final isRemote =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');

    return Image(
      image: isRemote
          ? NetworkImage(imagePath)
          : AssetImage(
              imagePath.isEmpty ? 'assets/images/brand_mark.png' : imagePath,
            ),
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, _, _) {
        return Container(
          color: AppTheme.mutedSurface,
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: AppTheme.ashGrey,
            size: 42,
          ),
        );
      },
    );
  }
}
