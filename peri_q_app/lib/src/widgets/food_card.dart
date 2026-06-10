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
    final radius = BorderRadius.circular(18);
    final theme = Theme.of(context);

    if (compact) {
      return InkWell(
        onTap: item.isAvailable ? onTap : null,
        borderRadius: radius,
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: radius,
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 12,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              AppImage(
                imagePath: item.imagePath,
                width: 84,
                height: 84,
                borderRadius: BorderRadius.circular(14),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: theme.textTheme.titleLarge),
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
                                ? AppTheme.success
                                : AppTheme.periRed,
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
                      color: AppTheme.periRed,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: item.isAvailable ? onAdd : null,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.periRed.withValues(alpha: 0.1),
                      foregroundColor: AppTheme.periRed,
                      minimumSize: const Size(0, 38),
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
          color: Colors.white,
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 18,
              offset: Offset(0, 8),
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
                  width: double.infinity,
                  fit: BoxFit.cover,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 10),
              Text(item.name, style: theme.textTheme.titleLarge),
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
                      color: AppTheme.periRed,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: item.isAvailable ? onAdd : null,
                    borderRadius: BorderRadius.circular(999),
                    child: Ink(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppTheme.periRed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
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
