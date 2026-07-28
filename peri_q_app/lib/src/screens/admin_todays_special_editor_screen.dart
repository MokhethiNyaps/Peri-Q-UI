import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../models/todays_special_settings.dart';
import '../widgets/app_image.dart';

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
  bool isUploadingImage = false;
  Uint8List? previewImageBytes;

  late final List<String> imageOptions;

  static const _defaultImagePath = 'assets/images/brand_mark.png';
  static const _maxImageBytes = 5 * 1024 * 1024;

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
      _defaultImagePath,
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

  Future<void> _pickAndUploadImage() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
    } catch (_) {
      _showMessage(
        'The gallery could not be opened. Check photo access and try again.',
        isError: true,
      );
      return;
    }

    if (result == null || result.files.isEmpty) {
      return;
    }

    final pickedFile = result.files.single;
    final bytes = pickedFile.bytes;
    final extension = (pickedFile.extension ?? _extensionFrom(pickedFile.name))
        .toLowerCase();
    const allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

    if (bytes == null || bytes.isEmpty) {
      _showMessage('The selected image could not be read.', isError: true);
      return;
    }
    if (!allowedExtensions.contains(extension)) {
      _showMessage('Choose a JPG, PNG or WebP image.', isError: true);
      return;
    }
    if (bytes.length > _maxImageBytes) {
      _showMessage('Choose an image smaller than 5 MB.', isError: true);
      return;
    }

    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      frame.image.dispose();
      codec.dispose();
    } catch (_) {
      _showMessage(
        'The selected file is not a valid image or is corrupted.',
        isError: true,
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      previewImageBytes = Uint8List.fromList(bytes);
      isUploadingImage = true;
    });

    try {
      final imageUrl = await widget.controller.uploadMenuItemImage(
        bytes: Uint8List.fromList(bytes),
        fileName: pickedFile.name,
        contentType: _contentTypeFor(extension),
      );

      if (!mounted) return;
      setState(() => imagePathController.text = imageUrl);
      _showMessage('Image uploaded. Save the special to publish it.');
    } catch (_) {
      if (!mounted) return;
      setState(() => previewImageBytes = null);
      _showMessage(
        'The image could not be uploaded. Check your connection and try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => isUploadingImage = false);
      }
    }
  }

  void _resetImage() {
    setState(() {
      previewImageBytes = null;
      imagePathController.text = _defaultImagePath;
    });
    _showMessage('Image reset to the Rasta\'s Peri Q brand mark.');
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.periRed : AppTheme.smokeCharcoal,
      ),
    );
  }

  String _extensionFrom(String fileName) {
    final segments = fileName.split('.');
    return segments.length > 1 ? segments.last : '';
  }

  String _contentTypeFor(String extension) {
    return switch (extension.toLowerCase()) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'application/octet-stream',
    };
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
            Container(
              height: 224,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppTheme.mutedSurface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (previewImageBytes != null)
                    Image.memory(
                      previewImageBytes!,
                      fit: BoxFit.cover,
                      semanticLabel: "Today's Special image preview",
                    )
                  else
                    AppImage(
                      imagePath: imagePathController.text,
                      width: double.infinity,
                      height: 224,
                      semanticLabel: "Today's Special image preview",
                    ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.smokeCharcoal.withValues(alpha: 0.86),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isUploadingImage) ...[
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                          ] else ...[
                            const Icon(
                              Icons.visibility_outlined,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            isUploadingImage ? 'Uploading' : 'Preview',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
                setState(() {
                  previewImageBytes = null;
                  imagePathController.text = value;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: imagePathController,
              decoration: const InputDecoration(
                labelText: 'Image Path or URL',
                hintText: 'assets/images/brand_mark.png',
              ),
              validator: _requiredText('Enter an image asset path or URL.'),
              onChanged: (_) => setState(() => previewImageBytes = null),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isUploadingImage ? null : _pickAndUploadImage,
                    icon: isUploadingImage
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(
                      isUploadingImage ? 'Uploading...' : 'Choose Image',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.outlined(
                  tooltip: 'Reset image',
                  onPressed: isUploadingImage ? null : _resetImage,
                  icon: const Icon(Icons.restart_alt_rounded),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'JPG, PNG or WebP, up to 5 MB. Images upload securely to the same Supabase Storage bucket used by menu items.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.ashGrey),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: isSaving || isUploadingImage ? null : _save,
            child: isSaving
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text('Saving...'),
                    ],
                  )
                : const Text('Save Today\'s Special'),
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
