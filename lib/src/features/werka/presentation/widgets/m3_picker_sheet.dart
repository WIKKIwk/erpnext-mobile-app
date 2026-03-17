import '../../../../core/theme/app_motion.dart';
import 'package:flutter/material.dart';

const AnimationStyle kM3PickerSheetAnimation = AnimationStyle(
  curve: AppMotion.standardDecelerate,
  reverseCurve: AppMotion.standardAccelerate,
  duration: Duration(milliseconds: 360),
  reverseDuration: Duration(milliseconds: 240),
);

class M3PickerSheet<T> extends StatefulWidget {
  const M3PickerSheet({
    super.key,
    required this.title,
    required this.hintText,
    required this.items,
    required this.itemTitle,
    required this.itemSubtitle,
    required this.matchesQuery,
    required this.onSelected,
    this.supportingText,
  });

  final String title;
  final String hintText;
  final List<T> items;
  final String Function(T item) itemTitle;
  final String Function(T item) itemSubtitle;
  final bool Function(T item, String query) matchesQuery;
  final ValueChanged<T> onSelected;
  final String? supportingText;

  @override
  State<M3PickerSheet<T>> createState() => _M3PickerSheetState<T>();
}

class _M3PickerSheetState<T> extends State<M3PickerSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<T> get _filteredItems {
    if (_query.trim().isEmpty) {
      return widget.items;
    }
    return widget.items
        .where((item) => widget.matchesQuery(item, _query))
        .toList(growable: false);
  }

  String _resultKey(List<T> items) {
    final buffer = StringBuffer(_query.trim());
    for (final item in items) {
      buffer
        ..write('|')
        ..write(widget.itemTitle(item))
        ..write(':')
        ..write(widget.itemSubtitle(item));
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final media = MediaQuery.of(context);
    final filtered = _filteredItems;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: media.size.height * 0.66,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(32),
          ),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              if ((widget.supportingText ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  widget.supportingText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              SearchBar(
                controller: _searchController,
                hintText: widget.hintText,
                leading: const Icon(Icons.search_rounded),
                elevation: const WidgetStatePropertyAll<double>(0),
                backgroundColor: WidgetStatePropertyAll<Color>(
                  scheme.surfaceContainerHighest,
                ),
                side: WidgetStatePropertyAll<BorderSide>(
                  BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.72),
                  ),
                ),
                shape: WidgetStatePropertyAll<OutlinedBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                onChanged: (value) {
                  setState(() => _query = value);
                },
              ),
              const SizedBox(height: 14),
              Flexible(
                child: AnimatedSwitcher(
                  duration: AppMotion.medium,
                  reverseDuration: AppMotion.fast,
                  switchInCurve: AppMotion.standardDecelerate,
                  switchOutCurve: AppMotion.standardAccelerate,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SizeTransition(
                        sizeFactor: animation,
                        axisAlignment: -1,
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<String>(_resultKey(filtered)),
                    child: filtered.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                'Hech narsa topilmadi',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        : Material(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(24),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                thickness: 1,
                                indent: 18,
                                endIndent: 18,
                                color: scheme.outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                final subtitle =
                                    widget.itemSubtitle(item).trim();
                                final isFirst = index == 0;
                                final isLast = index == filtered.length - 1;
                                return InkWell(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(isFirst ? 24 : 0),
                                    topRight: Radius.circular(isFirst ? 24 : 0),
                                    bottomLeft:
                                        Radius.circular(isLast ? 24 : 0),
                                    bottomRight:
                                        Radius.circular(isLast ? 24 : 0),
                                  ),
                                  onTap: () => widget.onSelected(item),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 16,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.itemTitle(item),
                                          style: theme.textTheme.titleLarge
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        if (subtitle.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            subtitle,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: scheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
