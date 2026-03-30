import '../../../../core/theme/app_motion.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import 'dart:async';
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

  bool _matches(T item) {
    if (_query.trim().isEmpty) {
      return true;
    }
    return widget.matchesQuery(item, _query);
  }

  bool _hasVisibleItemAfter(int index) {
    for (int next = index + 1; next < widget.items.length; next++) {
      if (_matches(widget.items[next])) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final media = MediaQuery.of(context);
    final visibleCount = widget.items.where((item) => _matches(item)).length;
    final keyboardInset = media.viewInsets.bottom;
    final l10n = context.l10n;

    return AnimatedPadding(
      duration: AppMotion.medium,
      curve: AppMotion.standardDecelerate,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Align(
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
                  child: visibleCount == 0
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              l10n.noRecordsYet,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        )
                      : Material(
                          color: scheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(24),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: widget.items.length,
                            itemBuilder: (context, index) {
                              final item = widget.items[index];
                              final subtitle = widget.itemSubtitle(item).trim();
                              final visible = _matches(item);
                              final isFirst = visible &&
                                  !widget.items
                                      .take(index)
                                      .any((entry) => _matches(entry));
                              final isLast =
                                  visible && !_hasVisibleItemAfter(index);

                              return ClipRect(
                                child: AnimatedSize(
                                  duration: AppMotion.slow,
                                  curve: AppMotion.emphasizedDecelerate,
                                  alignment: Alignment.topCenter,
                                  child: AnimatedOpacity(
                                    duration: AppMotion.medium,
                                    curve: AppMotion.standardDecelerate,
                                    opacity: visible ? 1 : 0,
                                    child: visible
                                        ? Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              SizedBox(
                                                width: double.infinity,
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    topLeft: Radius.circular(
                                                      isFirst ? 24 : 0,
                                                    ),
                                                    topRight: Radius.circular(
                                                      isFirst ? 24 : 0,
                                                    ),
                                                    bottomLeft: Radius.circular(
                                                      isLast ? 24 : 0,
                                                    ),
                                                    bottomRight:
                                                        Radius.circular(
                                                      isLast ? 24 : 0,
                                                    ),
                                                  ),
                                                  onTap: () =>
                                                      widget.onSelected(item),
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 18,
                                                      vertical: 16,
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          widget
                                                              .itemTitle(item),
                                                          style: theme.textTheme
                                                              .titleLarge
                                                              ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                        ),
                                                        if (subtitle
                                                            .isNotEmpty) ...[
                                                          const SizedBox(
                                                              height: 6),
                                                          Text(
                                                            subtitle,
                                                            style: theme
                                                                .textTheme
                                                                .bodySmall
                                                                ?.copyWith(
                                                              color: scheme
                                                                  .onSurfaceVariant,
                                                            ),
                                                          ),
                                                        ],
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              if (!isLast)
                                                Divider(
                                                  height: 1,
                                                  thickness: 1,
                                                  indent: 18,
                                                  endIndent: 18,
                                                  color: scheme.outlineVariant
                                                      .withValues(alpha: 0.5),
                                                ),
                                            ],
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class M3AsyncPickerSheet<T> extends StatefulWidget {
  const M3AsyncPickerSheet({
    super.key,
    required this.title,
    required this.hintText,
    required this.loadPage,
    required this.itemTitle,
    required this.itemSubtitle,
    required this.onSelected,
    this.supportingText,
    this.pageSize = 50,
  });

  final String title;
  final String hintText;
  final Future<List<T>> Function(String query, int offset, int limit) loadPage;
  final String Function(T item) itemTitle;
  final String Function(T item) itemSubtitle;
  final ValueChanged<T> onSelected;
  final String? supportingText;
  final int pageSize;

  @override
  State<M3AsyncPickerSheet<T>> createState() => _M3AsyncPickerSheetState<T>();
}

class _M3AsyncPickerSheetState<T> extends State<M3AsyncPickerSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  String _query = '';
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  Object? _error;
  List<T> _items = <T>[];
  int _requestVersion = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _reload(reset: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients ||
        _loading ||
        _loadingMore ||
        !_hasMore) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _reload(reset: false);
    }
  }

  Future<void> _reload({required bool reset}) async {
    final requestVersion = ++_requestVersion;
    if (reset) {
      setState(() {
        _loading = true;
        _loadingMore = false;
        _error = null;
        _hasMore = true;
        _items = <T>[];
      });
    } else {
      setState(() {
        _loadingMore = true;
      });
    }
    final offset = reset ? 0 : _items.length;
    try {
      final items =
          await widget.loadPage(_query.trim(), offset, widget.pageSize);
      if (!mounted || requestVersion != _requestVersion) {
        return;
      }
      setState(() {
        _items = reset ? items : [..._items, ...items];
        _hasMore = items.length >= widget.pageSize;
      });
    } catch (error) {
      if (!mounted || requestVersion != _requestVersion) {
        return;
      }
      setState(() {
        _error = error;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _scheduleReload(String nextQuery) {
    _debounce?.cancel();
    _query = nextQuery;
    _debounce = Timer(const Duration(milliseconds: 220), () {
      _reload(reset: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final media = MediaQuery.of(context);
    final keyboardInset = media.viewInsets.bottom;
    final l10n = context.l10n;

    Widget body;
    if (_loading) {
      body = const Center(child: AppLoadingIndicator());
    } else if (_error != null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.serverDisconnectedRetry,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => _reload(reset: true),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      );
    } else if (_items.isEmpty) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            l10n.noRecordsYet,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    } else {
      body = Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        child: ListView.separated(
          controller: _scrollController,
          shrinkWrap: true,
          itemCount: _items.length + (_loadingMore ? 1 : 0),
          separatorBuilder: (context, index) => Divider(
            height: 1,
            thickness: 1,
            indent: 18,
            endIndent: 18,
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
          itemBuilder: (context, index) {
            if (index >= _items.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(child: AppLoadingIndicator()),
              );
            }
            final item = _items[index];
            final subtitle = widget.itemSubtitle(item).trim();
            final isFirst = index == 0;
            final isLast = index == _items.length - 1;

            return SizedBox(
              width: double.infinity,
              child: InkWell(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isFirst ? 24 : 0),
                  topRight: Radius.circular(isFirst ? 24 : 0),
                  bottomLeft: Radius.circular(isLast ? 24 : 0),
                  bottomRight: Radius.circular(isLast ? 24 : 0),
                ),
                onTap: () => widget.onSelected(item),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.itemTitle(item),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return AnimatedPadding(
      duration: AppMotion.medium,
      curve: AppMotion.standardDecelerate,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Align(
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
                  onChanged: _scheduleReload,
                ),
                const SizedBox(height: 14),
                Flexible(child: body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
