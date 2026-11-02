import 'dart:async';
import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import 'app_image.dart';
import 'plate_entrance.dart';

class FoodCard extends StatefulWidget {
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
  State<FoodCard> createState() => _FoodCardState();
}

class _FoodCardState extends State<FoodCard> {
  bool added = false;
  Timer? reset;
  @override
  void dispose() {
    reset?.cancel();
    super.dispose();
  }

  void add() {
    widget.onAdd();
    setState(() => added = true);
    reset?.cancel();
    reset = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => added = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final item = widget.item;
    final image = PlateEntrance(
      child: AppImage(
        imagePath: item.imagePath,
        semanticLabel: '${item.name} photo',
        width: widget.compact ? 100 : double.infinity,
        height: widget.compact ? 112 : null,
        fit: BoxFit.cover,
        borderRadius: BorderRadius.circular(12),
      ),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          item.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'R${item.price.toStringAsFixed(0)}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Semantics(
              label: 'Add ${item.name} to cart',
              button: true,
              child: FilledButton.tonalIcon(
                onPressed: item.isAvailable ? add : null,
                icon: AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 140),
                  child: Icon(
                    added ? Icons.check_rounded : Icons.add_rounded,
                    key: ValueKey(added),
                    size: 18,
                  ),
                ),
                label: Text(
                  !item.isAvailable
                      ? 'Sold out'
                      : added
                      ? 'Added'
                      : 'Add',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(76, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.isAvailable ? widget.onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
          child: widget.compact
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    image,
                    const SizedBox(width: 16),
                    Expanded(child: details),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: image),
                    const SizedBox(height: 12),
                    details,
                  ],
                ),
        ),
      ),
    );
  }
}
