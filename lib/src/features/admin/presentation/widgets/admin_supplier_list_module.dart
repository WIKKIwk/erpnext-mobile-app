import '../../../../core/widgets/m3_segmented_list.dart';
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
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Text(
          'Userlar topilmadi',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }

    return M3SegmentSpacedColumn(
      children: [
        for (int index = 0; index < items.length; index++)
          _AdminUserRow(
            slot: M3SegmentedListGeometry.standaloneListSlotForIndex(
              index,
              items.length,
            ),
            item: items[index],
            onTap: () => onTapUser(items[index]),
          ),
      ],
    );
  }
}

class _AdminUserRow extends StatelessWidget {
  const _AdminUserRow({
    required this.slot,
    required this.item,
    required this.onTap,
  });

  final M3SegmentVerticalSlot slot;
  final AdminUserListEntry item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final phone = item.phone.trim();
    final subtitleLines = <String>[
      item.roleLabel,
      if (item.blocked) 'Blocked',
      if (phone.isNotEmpty) phone,
    ];

    return M3SegmentFilledSurface(
      slot: slot,
      cornerRadius: M3SegmentedListGeometry.cornerRadiusForSlot(slot),
      onTap: onTap,
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
        leading: CircleAvatar(
          radius: 19,
          backgroundColor: switch (item.kind) {
            AdminUserKind.werka => scheme.primaryContainer,
            AdminUserKind.customer => scheme.tertiaryContainer,
            AdminUserKind.supplier => scheme.secondaryContainer,
          },
          child: Icon(
            switch (item.kind) {
              AdminUserKind.werka => Icons.storefront_rounded,
              AdminUserKind.customer => Icons.groups_rounded,
              AdminUserKind.supplier => Icons.person_rounded,
            },
            color: switch (item.kind) {
              AdminUserKind.werka => scheme.onPrimaryContainer,
              AdminUserKind.customer => scheme.onTertiaryContainer,
              AdminUserKind.supplier => scheme.onSecondaryContainer,
            },
            size: 20,
          ),
        ),
        title: Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in subtitleLines)
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Text(
                    line,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
            ],
          ),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
