import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../models/app_preferences.dart';

class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key, required this.controller});

  final AppController controller;

  Future<void> _openEditor(
    BuildContext context, {
    SavedAddress? address,
  }) async {
    final didSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return _AddressEditor(controller: controller, address: address);
      },
    );

    if (didSave != true || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(address == null ? 'Address added.' : 'Address saved.'),
      ),
    );
  }

  Future<void> _deleteAddress(
    BuildContext context,
    SavedAddress address,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete address?'),
          content: Text(
            '${address.label} will be removed from saved addresses.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await controller.deleteSavedAddress(address.id);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Address deleted.')));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Saved Addresses')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openEditor(context),
            backgroundColor: AppTheme.periRed,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_location_alt_outlined),
            label: const Text('Address'),
          ),
          body: controller.savedAddresses.isEmpty
              ? _EmptyAddresses(onAdd: () => _openEditor(context))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  itemCount: controller.savedAddresses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final address = controller.savedAddresses[index];
                    final isDefault = address.id == controller.defaultAddressId;
                    return _AddressCard(
                      address: address,
                      isDefault: isDefault,
                      onSetDefault: () =>
                          controller.setDefaultAddress(address.id),
                      onEdit: () => _openEditor(context, address: address),
                      onDelete: () => _deleteAddress(context, address),
                    );
                  },
                ),
        );
      },
    );
  }
}

class _EmptyAddresses extends StatelessWidget {
  const _EmptyAddresses({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.location_on_outlined,
              color: AppTheme.ashGrey,
              size: 72,
            ),
            const SizedBox(height: 16),
            Text(
              'No saved addresses yet',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Save a delivery address once and reuse it at checkout.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Address'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.isDefault,
    required this.onSetDefault,
    required this.onEdit,
    required this.onDelete,
  });

  final SavedAddress address;
  final bool isDefault;
  final VoidCallback onSetDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDefault
              ? AppTheme.periRed.withValues(alpha: 0.28)
              : Colors.transparent,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.periRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: AppTheme.periRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  address.label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Default',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: AppTheme.success),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            address.displayAddress,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: isDefault ? null : onSetDefault,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Default'),
              ),
              const Spacer(),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit address',
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete address',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddressEditor extends StatefulWidget {
  const _AddressEditor({required this.controller, this.address});

  final AppController controller;
  final SavedAddress? address;

  @override
  State<_AddressEditor> createState() => _AddressEditorState();
}

class _AddressEditorState extends State<_AddressEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController labelController;
  late final TextEditingController addressController;
  late final TextEditingController notesController;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    labelController = TextEditingController(text: address?.label ?? '');
    addressController = TextEditingController(text: address?.address ?? '');
    notesController = TextEditingController(text: address?.notes ?? '');
  }

  @override
  void dispose() {
    labelController.dispose();
    addressController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => isSaving = true);
    final existingAddress = widget.address;
    if (existingAddress == null) {
      await widget.controller.addSavedAddress(
        label: labelController.text.trim(),
        address: addressController.text.trim(),
        notes: notesController.text.trim(),
      );
    } else {
      await widget.controller.updateSavedAddress(
        existingAddress.copyWith(
          label: labelController.text.trim(),
          address: addressController.text.trim(),
          notes: notesController.text.trim(),
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
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final viewPadding = MediaQuery.viewPaddingOf(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: viewInsets.bottom + viewPadding.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.address == null ? 'Add Address' : 'Edit Address',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'Home, Work, Office',
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a label.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: addressController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Address',
                hintText: 'House number, street, suburb and city',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter the address.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Delivery Notes',
                hintText: 'Gate code, landmark or instructions',
              ),
            ),
            const SizedBox(height: 18),
            SafeArea(
              top: false,
              left: false,
              right: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isSaving ? null : _save,
                  child: Text(isSaving ? 'Saving...' : 'Save Address'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
