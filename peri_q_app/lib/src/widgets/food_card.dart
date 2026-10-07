import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/menu_item.dart';
import 'app_image.dart';

class FoodCard extends StatelessWidget {
  const FoodCard({
    super.key,
    required this.item,
    required this.onAdd,
    this.compact = false,
    this.onTap,
  });

  final MenuItemModel item;
  final VoidCallback onAdd;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadii.card);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final appColors = context.appColors;

    if (compact) {
      return InkWell(
        onTap: item.isAvailable ? onTap : null,
        borderRadius: radius,
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: appColors.elevatedSurface,
            borderRadius: radius,
            border: Border.all(color: appColors.softOutline),
            boxShadow: [
              BoxShadow(
                color: appColors.shadow,
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              AppImage(
                imagePath: item.imagePath,
                semanticLabel: '${item.name} photo',
                width: 84,
                height: 84,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: item.isAvailable
                                ? appColors.success
                                : colors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          item.isAvailable ? 'Available' : 'Out of stock',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'R${item.price.toStringAsFixed(0)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: item.isAvailable ? onAdd : null,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.primaryContainer,
                      foregroundColor: colors.onPrimaryContainer,
                      minimumSize: const Size(72, 48),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: item.isAvailable ? onTap : null,
      borderRadius: radius,
      child: Ink(
        decoration: BoxDecoration(
          color: appColors.elevatedSurface,
          borderRadius: radius,
          border: Border.all(color: appColors.softOutline),
          boxShadow: [
            BoxShadow(
              color: appColors.shadow,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppImage(
                  imagePath: item.imagePath,
                  semanticLabel: '${item.name} photo',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'R${item.price.toStringAsFixed(0)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Semantics(
                    button: true,
                    enabled: item.isAvailable,
                    label: 'Add ${item.name} to cart',
                    child: Tooltip(
                      message: 'Add ${item.name}',
                      child: InkWell(
                        onTap: item.isAvailable ? onAdd : null,
                        borderRadius: BorderRadius.circular(AppRadii.pill),
                        child: Ink(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: item.isAvailable
                                ? colors.primary
                                : appColors.sunkenSurface,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            color: item.isAvailable
                                ? colors.onPrimary
                                : colors.onSurfaceVariant,
                          ),
                        ),
                      ),
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
