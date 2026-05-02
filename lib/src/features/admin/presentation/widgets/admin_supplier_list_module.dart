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
      return const AdminSummaryCard(
        slot: M3SegmentVerticalSlot.top,
        cornerRadius: M3SegmentedListGeometry.cornerLarge,
        title: 'Userlar topilmadi',
        value: '',
        showChevron: false,
      );
    }

    return M3SegmentSpacedColumn(
      children: [
        for (int index = 0; index < items.length; index++)
          _AdminSupplierRow(
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

class _AdminSupplierRow extends StatelessWidget {
  const _AdminSupplierRow({
    required this.slot,
    required this.item,
    required this.onTap,
  });

  final M3SegmentVerticalSlot slot;
  final AdminUserListEntry item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final phone = item.phone.trim();
    final subtitle =
        item.blocked ? '${item.roleLabel} · Blocked' : item.roleLabel;

    return AdminSummaryCard(
      slot: slot,
      cornerRadius: 24,
      title: item.name,
      subtitle: subtitle,
      value: phone.isEmpty ? ' ' : phone,
      onTap: onTap,
    );
  }
}
