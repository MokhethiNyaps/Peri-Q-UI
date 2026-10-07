import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../models/app_settings.dart';
import '../models/todays_special_settings.dart';
import '../widgets/app_image.dart';

class AdminAppSettingsScreen extends StatefulWidget {
  const AdminAppSettingsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<AdminAppSettingsScreen> createState() => _AdminAppSettingsScreenState();
}

class _AdminAppSettingsScreenState extends State<AdminAppSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController openingTimeController;
  late final TextEditingController closingTimeController;
  late final TextEditingController labelController;
  late final TextEditingController titleController;
  late final TextEditingController subtitleController;
  late final TextEditingController imagePathController;
  late bool storeOpen;
  late bool pickupAvailable;
  late bool deliveryAvailable;
  late final TextEditingController deliveryFeeController;
  late bool specialEnabled;
  String? selectedMenuItemId;
  bool isSaving = false;

  late final List<String> imageOptions;

  @override
  void initState() {
    super.initState();
    final settings = widget.controller.appSettings;
    final special = settings.todaysSpecial;

    storeOpen = settings.storeOpen;
    pickupAvailable = settings.pickupAvailable;
    deliveryAvailable = settings.deliveryAvailable;
    deliveryFeeController = TextEditingController(
      text: settings.deliveryFee.toStringAsFixed(0),
    );
    specialEnabled = special.enabled;
    selectedMenuItemId = special.menuItemId;
    openingTimeController = TextEditingController(text: settings.openingTime);
    closingTimeController = TextEditingController(text: settings.closingTime);
    labelController = TextEditingController(text: special.label);
    titleController = TextEditingController(text: special.title);
    subtitleController = TextEditingController(text: special.subtitle);
    imagePathController = TextEditingController(text: special.imagePath);
    imageOptions = {
      ...widget.controller.menuItems.map((item) => item.imagePath),
      'assets/images/white-app-icon.png',
    }.toList();
  }

  @override
  void dispose() {
    openingTimeController.dispose();
    closingTimeController.dispose();
    labelController.dispose();
    titleController.dispose();
    subtitleController.dispose();
    imagePathController.dispose();
    deliveryFeeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => isSaving = true);
    try {
      await widget.controller.updateAppSettings(
        AppSettings(
          storeOpen: storeOpen,
          pickupAvailable: pickupAvailable,
          deliveryAvailable: deliveryAvailable,
          deliveryFee: double.parse(deliveryFeeController.text.trim()),
          openingTime: openingTimeController.text.trim(),
          closingTime: closingTimeController.text.trim(),
          todaysSpecial: TodaysSpecialSettings(
            enabled: specialEnabled,
            label: labelController.text.trim(),
            title: titleController.text.trim(),
            subtitle: subtitleController.text.trim(),
            imagePath: imagePathController.text.trim(),
            menuItemId:
                selectedMenuItemId == null || selectedMenuItemId!.isEmpty
                ? null
                : selectedMenuItemId,
          ),
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

  Future<void> _pickTime(TextEditingController controller) async {
    final current =
        _parseTime(controller.text) ?? const TimeOfDay(hour: 10, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked == null || !mounted) {
      return;
    }
    setState(() => controller.text = _formatTime(picked));
  }

  @override
  Widget build(BuildContext context) {
    final selectedPreset = imageOptions.contains(imagePathController.text)
        ? imagePathController.text
        : null;
    final previewSettings = AppSettings(
      storeOpen: storeOpen,
      pickupAvailable: pickupAvailable,
      deliveryAvailable: deliveryAvailable,
      deliveryFee: double.tryParse(deliveryFeeController.text.trim()) ?? 30,
      openingTime: openingTimeController.text.trim(),
      closingTime: closingTimeController.text.trim(),
    );
    final isOpenNow = previewSettings.isOpenAt(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('App Settings')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
          children: [
            _SectionPanel(
              title: 'Store Availability',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile.adaptive(
                    value: storeOpen,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Store accepting orders'),
                    subtitle: Text(
                      storeOpen
                          ? 'Customers can place orders during operating hours.'
                          : 'Ordering is paused even if the hours say open.',
                    ),
                    onChanged: (value) => setState(() => storeOpen = value),
                  ),
                  SwitchListTile.adaptive(
                    value: pickupAvailable,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Pickup available'),
                    subtitle: const Text(
                      'Customers can select collection when the store is open.',
                    ),
                    onChanged: (value) =>
                        setState(() => pickupAvailable = value),
                  ),
                  SwitchListTile.adaptive(
                    value: deliveryAvailable,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Delivery available'),
                    subtitle: const Text(
                      'Turn off delivery without pausing pickup orders.',
                    ),
                    onChanged: (value) =>
                        setState(() => deliveryAvailable = value),
                  ),
                  if (deliveryAvailable) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: deliveryFeeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Delivery fee (R)',
                      ),
                      validator: (value) {
                        final fee = double.tryParse(value?.trim() ?? '');
                        if (fee == null || fee < 0 || fee > 1000) {
                          return 'Enter a fee from R0 to R1000.';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final opening = _TimeField(
                        controller: openingTimeController,
                        label: 'Opening Time',
                        onPickTime: () => _pickTime(openingTimeController),
                      );
                      final closing = _TimeField(
                        controller: closingTimeController,
                        label: 'Closing Time',
                        onPickTime: () => _pickTime(closingTimeController),
                      );
                      final stackFields = constraints.maxWidth < 420 ||
                          MediaQuery.textScalerOf(context).scale(1) > 1.2;
                      if (stackFields) {
                        return Column(
                          children: [
                            opening,
                            const SizedBox(height: 12),
                            closing,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: opening),
                          const SizedBox(width: 12),
                          Expanded(child: closing),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isOpenNow
                          ? context.appColors.successContainer
                          : context.appColors.dangerContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isOpenNow
                          ? 'Preview: Open now'
                          : 'Preview: Closed right now',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isOpenNow
                            ? context.appColors.onSuccessContainer
                            : context.appColors.onDangerContainer,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _SectionPanel(
              title: "Today's Special",
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppImage(
                    imagePath: imagePathController.text,
                    width: double.infinity,
                    height: 200,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile.adaptive(
                    value: specialEnabled,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show promotional banner'),
                    subtitle: const Text(
                      'This controls the customer-facing home screen special.',
                    ),
                    onChanged: (value) =>
                        setState(() => specialEnabled = value),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: labelController,
                    decoration: const InputDecoration(labelText: 'Promo Label'),
                    textCapitalization: TextCapitalization.characters,
                    validator: _requiredText('Enter a promo label.'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: titleController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Promo Title'),
                    validator: _requiredText('Enter the headline text.'),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: subtitleController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Promo Subtitle',
                    ),
                    validator: _requiredText('Enter the supporting text.'),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedMenuItemId ?? '',
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Linked Menu Item',
                    ),
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
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedPreset,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Image Preset',
                    ),
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
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: imagePathController,
                    decoration: const InputDecoration(
                      labelText: 'Image Path or Public URL',
                      hintText: 'assets/images/white-app-icon.png',
                    ),
                    validator: _requiredText(
                      'Enter an image asset path or URL.',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: isSaving ? null : _save,
            child: Text(isSaving ? 'Saving...' : 'Save App Settings'),
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

  static bool _isValidTime(String value) {
    final parts = value.trim().split(':');
    if (parts.length != 2) {
      return false;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    return hour != null &&
        minute != null &&
        hour >= 0 &&
        hour <= 23 &&
        minute >= 0 &&
        minute <= 59;
  }

  static TimeOfDay? _parseTime(String value) {
    if (!_isValidTime(value)) {
      return null;
    }
    final parts = value.trim().split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.controller,
    required this.label,
    required this.onPickTime,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: '10:00',
        suffixIcon: IconButton(
          onPressed: onPickTime,
          icon: const Icon(Icons.schedule_rounded),
          tooltip: 'Pick time',
        ),
      ),
      keyboardType: TextInputType.datetime,
      validator: (value) {
        if (!_AdminAppSettingsScreenState._isValidTime(value ?? '')) {
          return 'Use HH:mm.';
        }
        return null;
      },
    );
  }
}

class _SectionPanel extends StatelessWidget {
  const _SectionPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.appColors.elevatedSurface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: context.appColors.softOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
