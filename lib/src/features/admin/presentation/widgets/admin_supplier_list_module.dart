import '../../../shared/models/app_models.dart';
import 'package:flutter/material.dart';

class AdminSupplierListModule extends StatelessWidget {
  const AdminSupplierListModule({
    super.key,
    required this.items,
    required this.onTapUser,
  });

  final List<AdminUserListEntry> items;
  final ValueChanged<AdminUserListEntry> onTapUser;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (items.isEmpty) {
      return Card.filled(
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Userlar topilmadi.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (int index = 0; index < items.length; index++) ...[
          if (index > 0) const SizedBox(height: 10),
          _AdminSupplierRow(
            item: items[index],
            onTap: () => onTapUser(items[index]),
          ),
        ],
      ],
    );
  }
}

class _AdminSupplierRow extends StatelessWidget {
  const _AdminSupplierRow({
    required this.item,
    required this.onTap,
  });

  final AdminUserListEntry item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final Color bg = switch (theme.brightness) {
      Brightness.dark => scheme.surfaceContainerLow,
      Brightness.light => scheme.surfaceContainerHighest,
    };

    return Material(
      color: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: item.kind == AdminUserKind.werka
                        ? scheme.secondaryContainer
                        : scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    item.kind == AdminUserKind.werka
                        ? Icons.inventory_2_outlined
                        : item.kind == AdminUserKind.customer
                            ? Icons.groups_2_outlined
                            : Icons.account_circle_outlined,
                    size: 21,
                    color: item.kind == AdminUserKind.werka
                        ? scheme.onSecondaryContainer
                        : scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.roleLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (item.blocked) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Blocked',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onErrorContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
