import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/motion_widgets.dart';
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
      return SoftCard(
        child: Text(
          'Userlar topilmadi.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int index = 0; index < items.length; index++) ...[
            if (index > 0)
              Container(
                height: 1,
                color: AppTheme.cardBorder(context),
              ),
            _AdminSupplierRow(
              item: items[index],
              onTap: () => onTapUser(items[index]),
            ),
          ],
        ],
      ),
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
    return PressableScale(
      borderRadius: 24,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: AppTheme.actionSurface(context),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.cardBorder(context)),
              ),
              alignment: Alignment.center,
              child: Icon(
                item.kind == AdminUserKind.werka
                    ? Icons.badge_outlined
                    : Icons.person_outline_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.roleLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (item.blocked)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppTheme.cardBorder(context)),
                ),
                child: Text(
                  'Blocked',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
