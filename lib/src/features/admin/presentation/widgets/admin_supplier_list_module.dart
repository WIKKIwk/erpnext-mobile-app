import '../../../../core/widgets/m3_segmented_list.dart';
import '../../../shared/models/app_models.dart';
import 'admin_summary_card.dart';
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
    final subtitleLine = <String>[
      item.roleLabel,
      if (item.blocked) 'Blocked',
      if (phone.isNotEmpty) phone,
    ].join(' • ');

    return AdminSummaryCard(
      slot: slot,
      cornerRadius: M3SegmentedListGeometry.cornerRadiusForSlot(slot),
      onTap: onTap,
      fixedHeight: 64,
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      value: '',
      showChevron: true,
      leading: CircleAvatar(
        radius: 15,
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
          size: 15,
        ),
      ),
      title: item.name,
      subtitle: subtitleLine,
      titleMaxLines: 1,
      subtitleMaxLines: 1,
      titleStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
      subtitleStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.05,
          ),
    );
  }
}
