import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/theme/app_theme.dart';
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
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          SoftCard(
            child: Text(
              'Userlar topilmadi.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (context, _) => Container(
        height: 1,
        color: AppTheme.cardBorder(context),
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return InkWell(
          onTap: () => onTapUser(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
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
                const SizedBox(width: 10),
                const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
