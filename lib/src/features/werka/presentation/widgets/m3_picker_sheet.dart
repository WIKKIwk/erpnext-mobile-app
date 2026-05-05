import '../../../../core/theme/app_motion.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/search/search_normalizer.dart';
import '../../../../core/widgets/shell/app_loading_indicator.dart';
import '../../../../core/widgets/lists/m3_segmented_list.dart';
import 'werka_ai_search_service.dart';
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
    this.showScanIcon = false,
  });

  final String title;
  final String hintText;
  final List<T> items;
  final String Function(T item) itemTitle;
  final String Function(T item) itemSubtitle;
  final bool Function(T item, String query) matchesQuery;
  final ValueChanged<T> onSelected;
  final String? supportingText;
  final bool showScanIcon;

  @override
  State<M3PickerSheet<T>> createState() => _M3PickerSheetState<T>();
}

class _M3PickerSheetState<T> extends State<M3PickerSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  List<String> _searchQueries = const <String>[];
  bool _scanning = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(T item) {
    final queries = _effectiveQueries();
    if (queries.isEmpty) {
      return true;
    }
    return queries.any((query) => widget.matchesQuery(item, query));
  }

  List<T> _visibleItems() {
    final visible = widget.items.where((item) => _matches(item)).toList();
    if (_query.trim().isEmpty || visible.length < 2) {
      return visible;
    }
    final indexByItem = <T, int>{
      for (var index = 0; index < widget.items.length; index++)
        widget.items[index]: index,
    };
    visible.sort((left, right) {
      final relevance = _compareRelevanceAcrossQueries(
        left,
        right,
        queries: _effectiveQueries(),
      );
      if (relevance != 0) {
        return relevance;
      }
      return (indexByItem[left] ?? 0).compareTo(indexByItem[right] ?? 0);
    });
    return visible;
  }

  List<String> _effectiveQueries() {
    if (_searchQueries.isNotEmpty) {
      return _searchQueries.where((value) => value.trim().isNotEmpty).toList();
    }
    final current = _query.trim();
    return current.isEmpty ? const <String>[] : <String>[current];
  }

  int _compareRelevanceAcrossQueries(
    T left,
    T right, {
    required List<String> queries,
  }) {
    if (queries.isEmpty) {
      return 0;
    }
    var bestLeft = 0;
    var bestRight = 0;
    for (final query in queries) {
      final leftScore = searchRelevanceScore(
        query: query,
        primary: widget.itemTitle(left),
        secondary: [widget.itemSubtitle(left)],
      );
      final rightScore = searchRelevanceScore(
        query: query,
        primary: widget.itemTitle(right),
        secondary: [widget.itemSubtitle(right)],
      );
      if (leftScore > bestLeft) {
        bestLeft = leftScore;
      }
      if (rightScore > bestRight) {
        bestRight = rightScore;
      }
    }
    return bestRight.compareTo(bestLeft);
  }

  Future<void> _handleScanSearch() async {
    if (_scanning) {
      return;
    }
    setState(() => _scanning = true);
    try {
      final suggestion =
          await WerkaAiSearchService.instance.pickAndInferSuggestion(
        context,
      );
      if (!mounted || suggestion == null) {
        return;
      }
      final value = suggestion.displayQuery.trim();
      if (value.isEmpty) {
        return;
      }
      _searchController.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
      setState(() {
        _query = value;
        _searchQueries = suggestion.backgroundQueries;
      });
    } on WerkaAiSearchException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() => _scanning = false);
      }
    }
  }

  List<Widget>? _scanTrailing(ColorScheme scheme) {
    if (!widget.showScanIcon) {
      return null;
    }
    return <Widget>[
      if (_scanning)
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: scheme.primary,
          ),
        )
      else
        IconButton(
          onPressed: _handleScanSearch,
          icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
          splashRadius: 18,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 28, height: 28),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final media = MediaQuery.of(context);
    final visibleItems = _visibleItems();
    final visibleCount = visibleItems.length;
    final keyboardInset = media.viewInsets.bottom;
    final l10n = context.l10n;

    return AnimatedPadding(
      duration: AppMotion.medium,
      curve: AppMotion.standardDecelerate,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).maybePop(),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              constraints: BoxConstraints(
                maxHeight: media.size.height * 0.66,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
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
                      trailing: _scanTrailing(scheme),
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
                        setState(() {
                          _query = value;
                          _searchQueries = <String>[
                            if (value.trim().isNotEmpty) value.trim(),
                          ];
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    Flexible(
                      child: visibleCount == 0
                          ? Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 24),
                                child: Text(
                                  l10n.noRecordsYet,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: visibleItems.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(
                                height: M3SegmentedListGeometry.gap,
                              ),
                              itemBuilder: (context, index) {
                                final item = visibleItems[index];
                                final subtitle =
                                    widget.itemSubtitle(item).trim();
                                final slot = M3SegmentedListGeometry
                                    .standaloneListSlotForIndex(
                                  index,
                                  visibleItems.length,
                                );
                                final cornerRadius =
                                    M3SegmentedListGeometry.cornerRadiusForSlot(
                                        slot);

                                return M3SegmentFilledSurface(
                                  slot: slot,
                                  cornerRadius: cornerRadius,
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
                  ],
                ),
              ),
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
    this.showScanIcon = false,
  });

  final String title;
  final String hintText;
  final Future<List<T>> Function(String query, int offset, int limit) loadPage;
  final String Function(T item) itemTitle;
  final String Function(T item) itemSubtitle;
  final ValueChanged<T> onSelected;
  final String? supportingText;
  final int pageSize;
  final bool showScanIcon;

  @override
  State<M3AsyncPickerSheet<T>> createState() => _M3AsyncPickerSheetState<T>();
}

class _M3AsyncPickerSheetState<T> extends State<M3AsyncPickerSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  String _query = '';
  List<String> _searchQueries = const <String>[];
  bool _scanning = false;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  Object? _error;
  List<T> _items = <T>[];
  Map<String, int> _queryRankByItem = <String, int>{};
  Map<String, int> _queryMatchCountByItem = <String, int>{};
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
        _queryRankByItem = <String, int>{};
        _queryMatchCountByItem = <String, int>{};
      });
    } else {
      setState(() {
        _loadingMore = true;
      });
    }
    final offset = reset ? 0 : _items.length;
    try {
      final queries = _effectiveRemoteQueries();
      debugPrint('picker remote queries=${queries.join(' | ')}');
      final result = await _loadItems(
        queries: queries,
        offset: offset,
        limit: widget.pageSize,
        reset: reset,
      );
      if (!mounted || requestVersion != _requestVersion) {
        return;
      }
      setState(() {
        _items = reset ? result.items : [..._items, ...result.items];
        _queryRankByItem = reset
            ? result.queryRankByItem
            : {..._queryRankByItem, ...result.queryRankByItem};
        _queryMatchCountByItem = reset
            ? result.queryMatchCountByItem
            : {..._queryMatchCountByItem, ...result.queryMatchCountByItem};
        _hasMore =
            queries.length <= 1 && result.items.length >= widget.pageSize;
      });
      debugPrint('picker loaded items=${result.items.length}');
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
    _searchQueries = <String>[
      if (nextQuery.trim().isNotEmpty) nextQuery.trim()
    ];
    _debounce = Timer(const Duration(milliseconds: 220), () {
      _reload(reset: true);
    });
  }

  List<String> _effectiveQueries() {
    if (_searchQueries.isNotEmpty) {
      return _searchQueries.where((value) => value.trim().isNotEmpty).toList();
    }
    final current = _query.trim();
    return current.isEmpty ? const <String>[] : <String>[current];
  }

  List<String> _effectiveRemoteQueries() {
    final queries = _effectiveQueries();
    if (queries.length <= 1) {
      return queries;
    }
    final firstTokenQueries = <String>[];
    final familyQueries = <String>[];
    final coreQueries = <String>[];
    final specificQueries = <String>[];
    final seen = <String>{};

    void addQuery(String value, List<String> bucket) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return;
      }
      final key = trimmed.toLowerCase();
      if (!seen.add(key)) {
        return;
      }
      bucket.add(trimmed);
    }

    for (final query in queries) {
      final tokens = query
          .split(RegExp(r'[^A-Za-z0-9А-Яа-яЁёЎўҚқҒғҲҳ]+'))
          .where((token) => token.trim().isNotEmpty)
          .toList(growable: false);
      if (tokens.isEmpty) {
        continue;
      }
      final firstToken = tokens.first;
      if (firstToken.length >= 5 &&
          !_genericRemoteTokens.contains(firstToken.toLowerCase())) {
        addQuery(firstToken, firstTokenQueries);
      }
      if (tokens.length == 1) {
        if (tokens.first.length >= 4 &&
            !_genericRemoteTokens.contains(tokens.first.toLowerCase())) {
          addQuery(tokens.first, coreQueries);
        }
        continue;
      }
      if (tokens.length == 2) {
        addQuery(tokens.take(2).join(' '), familyQueries);
        continue;
      }
      if (tokens.length >= 3) {
        addQuery(tokens.take(2).join(' '), familyQueries);
        addQuery(tokens.take(3).join(' '), specificQueries);
      }
    }

    final ordered = <String>[
      ...firstTokenQueries,
      ...familyQueries,
      ...coreQueries,
      ...specificQueries,
      ...queries,
    ];
    return ordered.take(6).toList(growable: false);
  }

  static const Set<String> _genericRemoteTokens = {
    'mahsulotlari',
    'products',
    'продукты',
    'молочные',
    'dairy',
    'milk',
    'sut',
    'noodles',
    'instant',
    'spicy',
    'achchiq',
    'курица',
    'острая',
    'kuritsa',
    'ostraya',
    'tovuq',
    'snack',
    'halal',
  };

  Future<_AsyncLoadResult<T>> _loadItems({
    required List<String> queries,
    required int offset,
    required int limit,
    required bool reset,
  }) async {
    if (queries.length <= 1) {
      final items = await widget.loadPage(
        queries.isEmpty ? '' : queries.first,
        offset,
        limit,
      );
      final queryRankByItem = <String, int>{
        for (final item in items) _itemIdentity(item): 0,
      };
      final queryMatchCountByItem = <String, int>{
        for (final item in items) _itemIdentity(item): 1,
      };
      return _AsyncLoadResult<T>(
        items: items,
        queryRankByItem: queryRankByItem,
        queryMatchCountByItem: queryMatchCountByItem,
      );
    }
    if (!reset) {
      return _AsyncLoadResult<T>(
        items: <T>[],
        queryRankByItem: <String, int>{},
        queryMatchCountByItem: <String, int>{},
      );
    }
    final pages = await Future.wait(
      queries.map((query) => widget.loadPage(query, 0, limit)),
    );
    for (var pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      debugPrint(
        'picker query="${queries[pageIndex]}" page_items=${pages[pageIndex].length}',
      );
    }
    final merged = <T>[];
    final seen = <String>{};
    final queryRankByItem = <String, int>{};
    final queryMatchCountByItem = <String, int>{};
    for (var pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      final page = pages[pageIndex];
      for (var index = 0; index < page.length; index++) {
        final item = page[index];
        final key = _itemIdentity(item);
        queryRankByItem[key] ??= pageIndex;
        queryMatchCountByItem.update(
          key,
          (value) => value + 1,
          ifAbsent: () => 1,
        );
        if (!seen.add(key)) {
          continue;
        }
        merged.add(item);
      }
    }
    return _AsyncLoadResult<T>(
      items: merged,
      queryRankByItem: queryRankByItem,
      queryMatchCountByItem: queryMatchCountByItem,
    );
  }

  String _itemIdentity(T item) {
    return '${widget.itemTitle(item)}|${widget.itemSubtitle(item)}'
        .toLowerCase()
        .trim();
  }

  Future<void> _handleScanSearch() async {
    if (_scanning) {
      return;
    }
    setState(() => _scanning = true);
    try {
      final suggestion =
          await WerkaAiSearchService.instance.pickAndInferSuggestion(
        context,
      );
      if (!mounted || suggestion == null) {
        return;
      }
      final value = suggestion.displayQuery.trim();
      if (value.isEmpty) {
        return;
      }
      _searchController.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
      _debounce?.cancel();
      _query = value;
      _searchQueries = suggestion.backgroundQueries;
      await _reload(reset: true);
    } on WerkaAiSearchException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } finally {
      if (mounted) {
        setState(() => _scanning = false);
      }
    }
  }

  List<Widget>? _scanTrailing(ColorScheme scheme) {
    if (!widget.showScanIcon) {
      return null;
    }
    return <Widget>[
      if (_scanning)
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: scheme.primary,
          ),
        )
      else
        IconButton(
          onPressed: _handleScanSearch,
          icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
          splashRadius: 18,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 28, height: 28),
        ),
    ];
  }

  List<T> _sortedItems() {
    final queries = _effectiveQueries();
    if (queries.isEmpty || _items.length < 2) {
      return _items;
    }
    final indexed = _items.indexed.toList(growable: false);
    indexed.sort((left, right) {
      final relevance = _compareRelevanceAcrossQueries(
        left.$2,
        right.$2,
        queries: queries,
      );
      if (relevance != 0) {
        return relevance;
      }
      final leftCount = _queryMatchCountByItem[_itemIdentity(left.$2)] ?? 0;
      final rightCount = _queryMatchCountByItem[_itemIdentity(right.$2)] ?? 0;
      if (leftCount != rightCount) {
        return rightCount.compareTo(leftCount);
      }
      final leftRank = _queryRankByItem[_itemIdentity(left.$2)] ?? 999;
      final rightRank = _queryRankByItem[_itemIdentity(right.$2)] ?? 999;
      if (leftRank != rightRank) {
        return leftRank.compareTo(rightRank);
      }
      return left.$1.compareTo(right.$1);
    });
    return indexed.map((entry) => entry.$2).toList(growable: false);
  }

  int _compareRelevanceAcrossQueries(
    T left,
    T right, {
    required List<String> queries,
  }) {
    var bestLeft = 0;
    var bestRight = 0;
    for (final query in queries) {
      final leftScore = searchRelevanceScore(
        query: query,
        primary: widget.itemTitle(left),
        secondary: [widget.itemSubtitle(left)],
      );
      final rightScore = searchRelevanceScore(
        query: query,
        primary: widget.itemTitle(right),
        secondary: [widget.itemSubtitle(right)],
      );
      if (leftScore > bestLeft) {
        bestLeft = leftScore;
      }
      if (rightScore > bestRight) {
        bestRight = rightScore;
      }
    }
    return bestRight.compareTo(bestLeft);
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
      final sortedItems = _sortedItems();
      body = ListView.separated(
        controller: _scrollController,
        shrinkWrap: true,
        itemCount: sortedItems.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (context, index) => const SizedBox(
          height: M3SegmentedListGeometry.gap,
        ),
        itemBuilder: (context, index) {
          if (index >= sortedItems.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(child: AppLoadingIndicator()),
            );
          }
          final item = sortedItems[index];
          final subtitle = widget.itemSubtitle(item).trim();
          final slot = M3SegmentedListGeometry.standaloneListSlotForIndex(
            index,
            sortedItems.length,
          );
          final cornerRadius =
              M3SegmentedListGeometry.cornerRadiusForSlot(slot);

          return M3SegmentFilledSurface(
            slot: slot,
            cornerRadius: cornerRadius,
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
          );
        },
      );
    }

    return AnimatedPadding(
      duration: AppMotion.medium,
      curve: AppMotion.standardDecelerate,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).maybePop(),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              constraints: BoxConstraints(
                maxHeight: media.size.height * 0.66,
              ),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
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
                      trailing: _scanTrailing(scheme),
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
        ),
      ),
    );
  }
}

class _AsyncLoadResult<T> {
  const _AsyncLoadResult({
    required this.items,
    required this.queryRankByItem,
    required this.queryMatchCountByItem,
  });

  final List<T> items;
  final Map<String, int> queryRankByItem;
  final Map<String, int> queryMatchCountByItem;
}
