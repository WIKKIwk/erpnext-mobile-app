import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/widgets/lists/m3_segmented_list.dart';
import '../../../core/api/mobile_api.dart';
import '../../../core/search/search_normalizer.dart';
import '../../../core/widgets/navigation/app_navigation_bar.dart';
import '../../../core/widgets/navigation/app_primary_navigation_fab.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shell/app_loading_indicator.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../../core/widgets/navigation/dock_gesture_overlay.dart';
import '../../../core/widgets/navigation/dock_system_bottom_inset.dart';
import '../../shared/models/app_models.dart';
import 'widgets/admin_dock.dart';
import 'widgets/admin_summary_card.dart';

class AdminItemGroupBulkMoveScreen extends StatefulWidget {
  const AdminItemGroupBulkMoveScreen({super.key});

  @override
  State<AdminItemGroupBulkMoveScreen> createState() =>
      _AdminItemGroupBulkMoveScreenState();
}

class _AdminItemGroupBulkMoveScreenState
    extends State<AdminItemGroupBulkMoveScreen> {
  static const int _initialPageSize = 30;
  static const int _scrollPageSize = 50;
  static const double _prefetchExtent = 2800;
  static _AdminItemGroupBulkMoveCache? _cache;

  final ScrollController _scrollController = ScrollController();
  final List<SupplierItem> _items = <SupplierItem>[];
  final List<String> _groups = <String>[];
  final Set<String> _selectedCodes = <String>{};
  final TextEditingController _searchController = TextEditingController();

  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _submitting = false;
  bool _hasMore = true;
  int _offset = 0;
  String? _selectedGroup;
  bool _groupMenuOpen = false;
  bool _showScrollTopButton = false;
  Timer? _searchDebounce;
  Timer? _autoTopUpTimer;
  List<SupplierItem>? _serverSearchItems;
  String? _serverSearchQuery;
  int _serverSearchGeneration = 0;
  bool _autoTopUpDone = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    unawaited(_loadInitial());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _autoTopUpTimer?.cancel();
    _searchController.dispose();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _initialLoading) {
      return;
    }

    final shouldShowScrollTopButton = _scrollController.offset > 140;
    if (shouldShowScrollTopButton != _showScrollTopButton && mounted) {
      setState(() => _showScrollTopButton = shouldShowScrollTopButton);
    }

    if (_loadingMore || !_hasMore) {
      return;
    }

    if (_scrollController.position.extentAfter <= _prefetchExtent) {
      unawaited(_loadMore(limit: _scrollPageSize, showLoader: true));
    }
  }

  Future<void> _loadInitial({
    bool clearGroup = false,
    bool forceRefresh = false,
  }) async {
    final restored = !forceRefresh && !clearGroup && _restoreCache();
    if (restored) {
      _scheduleAutoTopUp();
      return;
    }

    _resetCacheState();
    if (mounted) {
      setState(() {
        _initialLoading = true;
        _loadingMore = false;
        _hasMore = true;
        _errorText = null;
        _groupMenuOpen = false;
        _items.clear();
        _selectedCodes.clear();
        _serverSearchItems = null;
        _serverSearchQuery = null;
        _autoTopUpDone = false;
        _offset = 0;
        if (clearGroup) {
          _selectedGroup = null;
        }
      });
    }

    try {
      final results = await Future.wait<Object>([
        MobileApi.instance.adminItemGroups(),
        MobileApi.instance.adminItemsPage(limit: _initialPageSize),
      ]);
      final groups = results[0] as List<String>;
      final items = results[1] as List<SupplierItem>;

      if (!mounted) {
        return;
      }
      final hasMore = items.length == _initialPageSize;
      setState(() {
        _groups
          ..clear()
          ..addAll(groups);
        _items.addAll(items);
        _hasMore = hasMore;
        if (_selectedGroup != null && !groups.contains(_selectedGroup)) {
          _selectedGroup = null;
        }
        if (_selectedGroup == null && groups.length == 1) {
          _selectedGroup = groups.first;
        }
        _offset = items.length;
      });
      _storeCache(
        groups: groups,
        items: items,
        offset: items.length,
        hasMore: hasMore,
      );
      _scheduleAutoTopUp();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorText = error.toString());
    } finally {
      if (mounted) {
        setState(() => _initialLoading = false);
      }
    }
  }

  Future<void> _refresh() {
    return _loadInitial(clearGroup: false, forceRefresh: true);
  }

  Future<void> _loadMore({
    required int limit,
    required bool showLoader,
  }) async {
    if (_initialLoading || _loadingMore || !_hasMore) {
      return;
    }

    if (showLoader && mounted) {
      setState(() => _loadingMore = true);
    }

    try {
      final page = await MobileApi.instance.adminItemsPage(
        limit: limit,
        offset: _offset,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _items.addAll(page);
        _offset += page.length;
        _hasMore = page.length == limit;
      });
      _storeCache(
        groups: _groups,
        items: _items,
        offset: _offset,
        hasMore: _hasMore,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mahsulotlar yuklanmadi: $error')),
      );
    } finally {
      if (mounted && showLoader) {
        setState(() => _loadingMore = false);
      }
    }
  }

  void _toggleItem(SupplierItem item) {
    if (_submitting) {
      return;
    }

    setState(() {
      if (_selectedCodes.contains(item.code)) {
        _selectedCodes.remove(item.code);
      } else {
        _selectedCodes.add(item.code);
      }
    });
  }

  Future<void> _moveSelected() async {
    final targetGroup = _selectedGroup?.trim() ?? '';
    if (_selectedCodes.isEmpty || targetGroup.isEmpty || _submitting) {
      return;
    }

    final confirmed = await _showSafeConfirm(
      title: "Mahsulotlarni ko'chirish",
      message:
          "${_selectedCodes.length} ta mahsulotni \"$targetGroup\" groupiga o'tkazamizmi?",
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _submitting = true);

    try {
      final result = await MobileApi.instance.adminMoveItemsToGroup(
        itemCodes: _selectedCodes.toList(growable: false),
        itemGroup: targetGroup,
      );
      if (!mounted) {
        return;
      }

      final updatedCodes = result.updatedItemCodes.toSet();
      setState(() {
        if (result.failedCount == 0) {
          _selectedCodes.clear();
        } else {
          _selectedCodes.removeWhere(updatedCodes.contains);
        }
      });

      final message = result.failedCount == 0
          ? "${result.updatedCount} ta mahsulot ko'chirildi"
          : "${result.updatedCount} ta ko'chirildi, ${result.failedCount} ta xato";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ko'chirish bajarilmadi: $error")),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = _selectedCodes.isNotEmpty &&
        (_selectedGroup?.trim().isNotEmpty ?? false) &&
        !_submitting;
    final searchTerm = _searchController.text.trim();
    final visibleItems = _visibleItems(searchTerm);
    final rowCount = visibleItems.isEmpty ? 1 : visibleItems.length;
    final listItemCount = 2 + rowCount + (_loadingMore ? 1 : 0);

    return ExcludeSemantics(
      child: AppShell(
        animateOnEnter: false,
        title: "Mahsulot group ko'chirish",
        subtitle: '',
        nativeTopBar: true,
        nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
        contentPadding: EdgeInsets.zero,
        bottom: _AdminDockWithScrollTop(
          activeTab: AdminDockTab.home,
          visible: _showScrollTopButton,
          onScrollTop: _scrollToTop,
        ),
        child: _initialLoading
            ? const Center(child: AppLoadingIndicator())
            : _errorText != null && _items.isEmpty
                ? _ErrorView(
                    message: _errorText!,
                    onRetry: () =>
                        _loadInitial(clearGroup: false, forceRefresh: true),
                  )
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(4, 8, 4, 164),
                      itemCount: listItemCount,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _BulkMoveHeader(
                            groups: _groups,
                            selectedGroup: _selectedGroup,
                            groupMenuOpen: _groupMenuOpen,
                            selectedCount: _selectedCodes.length,
                            submitting: _submitting,
                            canSubmit: canSubmit,
                            onChooseGroup: _chooseGroup,
                            onSelectGroup: _selectGroup,
                            searchController: _searchController,
                            onSearchChanged: _handleSearchChanged,
                            onSubmit: _moveSelected,
                          );
                        }

                        if (index == 1) {
                          return const SizedBox(height: 12);
                        }

                        if (visibleItems.isEmpty && index == 2) {
                          return const _EmptyItemsView();
                        }

                        final rowIndex = index - 2;
                        if (rowIndex >= 0 && rowIndex < visibleItems.length) {
                          final item = visibleItems[rowIndex];
                          return Padding(
                            padding: EdgeInsets.fromLTRB(
                              8,
                              rowIndex == 0 ? 0 : M3SegmentedListGeometry.gap,
                              8,
                              0,
                            ),
                            child: _ItemRow(
                              slot: M3SegmentedListGeometry
                                  .standaloneListSlotForIndex(
                                rowIndex,
                                visibleItems.length,
                              ),
                              item: item,
                              selected: _selectedCodes.contains(item.code),
                              onTap:
                                  _submitting ? null : () => _toggleItem(item),
                            ),
                          );
                        }

                        if (_loadingMore && index == listItemCount - 1) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Center(child: AppLoadingIndicator()),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
      ),
    );
  }

  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) {
      return;
    }
    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  List<SupplierItem> _visibleItems(String query) {
    final normalized = query.trim();
    if (normalized.isEmpty) {
      return _items;
    }

    final indexedItems = <String, SupplierItem>{
      for (final item in _items) item.code: item,
    };
    if (_serverSearchQuery == normalized && _serverSearchItems != null) {
      for (final item in _serverSearchItems!) {
        indexedItems[item.code] = item;
      }
    }

    final matches = indexedItems.values
        .where(
          (item) => searchMatches(
            normalized,
            <String>[
              item.code,
              item.name,
              item.uom,
              item.warehouse,
              item.itemGroup,
            ],
          ),
        )
        .toList(growable: false);

    if (matches.length <= 1) {
      return matches;
    }

    matches.sort((left, right) {
      final leftPrimary = left.name.isEmpty ? left.code : left.name;
      final rightPrimary = right.name.isEmpty ? right.code : right.name;
      return compareSearchRelevance(
        query: normalized,
        leftPrimary: leftPrimary,
        leftSecondary: <String>[
          left.code,
          left.uom,
          left.warehouse,
          left.itemGroup,
        ],
        rightPrimary: rightPrimary,
        rightSecondary: <String>[
          right.code,
          right.uom,
          right.warehouse,
          right.itemGroup,
        ],
      );
    });
    return matches;
  }

  void _scheduleAutoTopUp() {
    _autoTopUpTimer?.cancel();
    if (_autoTopUpDone || !_hasMore || _items.length >= 60) {
      _autoTopUpDone = true;
      return;
    }

    _autoTopUpTimer = Timer(const Duration(seconds: 5), () {
      unawaited(_autoTopUpMore());
    });
  }

  Future<void> _autoTopUpMore() async {
    if (!mounted || _initialLoading || _loadingMore) {
      return;
    }
    if (_autoTopUpDone || !_hasMore || _items.length >= 60) {
      _autoTopUpDone = true;
      return;
    }

    final remainingToSixty = 60 - _items.length;
    final limit = remainingToSixty < _initialPageSize
        ? remainingToSixty
        : _initialPageSize;
    if (limit <= 0) {
      _autoTopUpDone = true;
      return;
    }

    await _loadMore(limit: limit, showLoader: false);
    _autoTopUpDone = true;
  }

  Future<void> _chooseGroup() async {
    if (_submitting || _groups.isEmpty) {
      return;
    }
    setState(() => _groupMenuOpen = !_groupMenuOpen);
  }

  void _handleSearchChanged(String value) {
    if (!mounted) {
      return;
    }
    final query = value.trim();
    _searchDebounce?.cancel();
    setState(() {
      _groupMenuOpen = false;
      if (query.isEmpty) {
        _serverSearchItems = null;
        _serverSearchQuery = null;
      }
    });

    if (query.isEmpty) {
      _serverSearchGeneration += 1;
      return;
    }

    final int generation = ++_serverSearchGeneration;
    _searchDebounce = Timer(const Duration(milliseconds: 220), () async {
      if (!mounted || generation != _serverSearchGeneration) {
        return;
      }

      try {
        final results = await MobileApi.instance.adminItems(query: query);
        if (!mounted || generation != _serverSearchGeneration) {
          return;
        }
        setState(() {
          _serverSearchQuery = query;
          _serverSearchItems = results;
        });
      } catch (_) {
        if (!mounted || generation != _serverSearchGeneration) {
          return;
        }
        setState(() {
          _serverSearchQuery = query;
          _serverSearchItems = _visibleItems(query);
        });
      }
    });
  }

  void _selectGroup(String group) {
    if (_submitting) {
      return;
    }
    setState(() {
      _selectedGroup = group;
      _groupMenuOpen = false;
    });
  }

  Future<bool?> _showSafeConfirm({
    required String title,
    required String message,
  }) async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return false;
    }
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return _SafeConfirmDialog(title: title, message: message);
      },
    );
  }

  bool _restoreCache() {
    final cache = _cache;
    if (cache == null) {
      return false;
    }
    if (mounted) {
      setState(() {
        _groups
          ..clear()
          ..addAll(cache.groups);
        _items
          ..clear()
          ..addAll(cache.items);
        _offset = cache.offset;
        _hasMore = cache.hasMore;
        _autoTopUpDone = cache.items.length >= 60 || !cache.hasMore;
        _initialLoading = false;
        _groupMenuOpen = false;
        _errorText = null;
        _selectedCodes.clear();
        if (_selectedGroup != null && !cache.groups.contains(_selectedGroup)) {
          _selectedGroup = null;
        }
        if (_selectedGroup == null && cache.groups.length == 1) {
          _selectedGroup = cache.groups.first;
        }
      });
    }
    return true;
  }

  void _resetCacheState() {
    _cache = null;
    _autoTopUpDone = false;
    _autoTopUpTimer?.cancel();
  }

  void _storeCache({
    required List<String> groups,
    required List<SupplierItem> items,
    required int offset,
    required bool hasMore,
  }) {
    _cache = _AdminItemGroupBulkMoveCache(
      groups: List<String>.unmodifiable(groups),
      items: List<SupplierItem>.unmodifiable(items),
      offset: offset,
      hasMore: hasMore,
      allLoaded: !hasMore,
    );
  }
}

class _AdminDockWithScrollTop extends StatelessWidget {
  const _AdminDockWithScrollTop({
    required this.activeTab,
    required this.visible,
    required this.onScrollTop,
  });

  final AdminDockTab activeTab;
  final bool visible;
  final VoidCallback onScrollTop;

  @override
  Widget build(BuildContext context) {
    final dock = AdminDock(
      activeTab: activeTab,
    );

    if (!visible) {
      return dock;
    }

    final media = MediaQueryData.fromView(View.of(context));
    final dockHeight = appNavigationBarDockHeight(
      height: appNavigationBarHeight,
      systemBottomInset: dockLayoutBottomInset(
        media,
        thinGestureBottom: DockGestureOverlayScope.thinGestureBottomOf(context),
      ),
    );
    const double buttonSize = 48;
    final double buttonBottom =
        appNavigationBarPrimaryButtonBottom(dockHeight: dockHeight) +
            (appNavigationBarPrimaryButtonSize / 2) -
            (buttonSize / 2) -
            7;
    final double buttonEnd = appNavigationBarPrimaryEndMargin +
        appNavigationBarPrimaryButtonSize +
        appNavigationBarPrimaryNavGap;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        dock,
        PositionedDirectional(
          end: buttonEnd,
          bottom: buttonBottom,
          child: _ScrollToTopButton(
            size: buttonSize,
            onTap: onScrollTop,
          ),
        ),
      ],
    );
  }
}

class _ScrollToTopButton extends StatelessWidget {
  const _ScrollToTopButton({
    required this.size,
    required this.onTap,
  });

  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.primaryContainer,
      elevation: 8,
      shadowColor: scheme.primary.withValues(alpha: 0.24),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.arrow_upward_rounded,
            color: scheme.onPrimaryContainer,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _AdminItemGroupBulkMoveCache {
  const _AdminItemGroupBulkMoveCache({
    required this.groups,
    required this.items,
    required this.offset,
    required this.hasMore,
    required this.allLoaded,
  });

  final List<String> groups;
  final List<SupplierItem> items;
  final int offset;
  final bool hasMore;
  final bool allLoaded;
}

class _TapBox extends StatelessWidget {
  const _TapBox({
    required this.child,
    required this.onTap,
    required this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: child,
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.enabled,
    required this.onTap,
    required this.child,
    this.compact = false,
  });

  final bool enabled;
  final VoidCallback onTap;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _TapBox(
      onTap: enabled ? onTap : null,
      borderRadius: 999,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 16,
          vertical: compact ? 8 : 11,
        ),
        decoration: BoxDecoration(
          color: enabled
              ? scheme.primary
              : scheme.onSurface.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: IconTheme(
          data: IconThemeData(
            color: enabled
                ? scheme.onPrimary
                : scheme.onSurface.withValues(alpha: 0.38),
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: enabled
                  ? scheme.onPrimary
                  : scheme.onSurface.withValues(alpha: 0.38),
              fontWeight: FontWeight.w700,
              fontSize: compact ? 13.5 : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SafeConfirmDialog extends StatelessWidget {
  const _SafeConfirmDialog({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: scheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _PillButton(
                    enabled: true,
                    onTap: () => Navigator.of(context).pop(false),
                    child: const Center(child: Text("Yo'q")),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PillButton(
                    enabled: true,
                    onTap: () => Navigator.of(context).pop(true),
                    child: const Center(child: Text('Ha')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BulkMoveHeader extends StatelessWidget {
  const _BulkMoveHeader({
    required this.groups,
    required this.selectedGroup,
    required this.groupMenuOpen,
    required this.selectedCount,
    required this.submitting,
    required this.canSubmit,
    required this.onChooseGroup,
    required this.onSelectGroup,
    required this.searchController,
    required this.onSearchChanged,
    required this.onSubmit,
  });

  final List<String> groups;
  final String? selectedGroup;
  final bool groupMenuOpen;
  final int selectedCount;
  final bool submitting;
  final bool canSubmit;
  final VoidCallback onChooseGroup;
  final ValueChanged<String> onSelectGroup;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Target group',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _PillButton(
                enabled: canSubmit,
                compact: true,
                onTap: onSubmit,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (submitting)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.done_all_rounded, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      submitting ? "..." : "Ko'chirish",
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _TapBox(
            onTap: submitting ? null : onChooseGroup,
            borderRadius: 14,
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedGroup ?? 'Group tanlang',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: selectedGroup == null
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.expand_more_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: groupMenuOpen
                ? Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainer,
                      borderRadius: BorderRadius.zero,
                      border: Border(
                        left: BorderSide(color: scheme.outlineVariant),
                        right: BorderSide(color: scheme.outlineVariant),
                        top: BorderSide(color: scheme.outlineVariant),
                        bottom: BorderSide(color: scheme.outlineVariant),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int index = 0; index < groups.length; index++) ...[
                          if (index > 0)
                            Divider(
                              height: 1,
                              thickness: 1,
                              color:
                                  scheme.outlineVariant.withValues(alpha: 0.6),
                            ),
                          Material(
                            color: groups[index] == selectedGroup
                                ? scheme.primaryContainer
                                    .withValues(alpha: 0.55)
                                : Colors.transparent,
                            child: InkWell(
                              onTap: submitting
                                  ? null
                                  : () => onSelectGroup(groups[index]),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 13,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        groups[index],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: scheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    if (groups[index] == selectedGroup)
                                      Icon(
                                        Icons.check_rounded,
                                        size: 18,
                                        color: scheme.onSurface,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            enabled: !submitting,
            decoration: InputDecoration(
              hintText: 'Mahsulot qidirish',
              isDense: true,
              filled: true,
              fillColor: scheme.surfaceContainer,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: scheme.outlineVariant),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: scheme.primary, width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tanlangan: $selectedCount ta',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.slot,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final M3SegmentVerticalSlot slot;
  final SupplierItem item;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final displayTitle = item.name.isEmpty ? item.code : item.name;
    final titleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        );
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
          height: 1.05,
        );
    final subtitleLine = <String>[
      if (item.code.isNotEmpty && !_sameSearchText(item.code, displayTitle))
        item.code,
      if (item.uom.isNotEmpty) item.uom,
      if (item.itemGroup.isNotEmpty) 'Group: ${item.itemGroup.trim()}',
      if (item.warehouse.isNotEmpty) item.warehouse,
    ].where((part) => part.isNotEmpty).join(' • ');

    return AdminSummaryCard(
      slot: slot,
      cornerRadius: M3SegmentedListGeometry.cornerRadiusForSlot(slot),
      onTap: onTap,
      fixedHeight: 61,
      padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
      value: '',
      showChevron: false,
      leading: SizedBox.square(
        dimension: 30,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? scheme.primaryContainer
                : scheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              selected ? Icons.check_rounded : Icons.inventory_2_rounded,
              color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
              size: 16,
            ),
          ),
        ),
      ),
      title: displayTitle,
      subtitle: subtitleLine,
      titleMaxLines: 1,
      subtitleMaxLines: 1,
      titleStyle: titleStyle,
      subtitleStyle: subtitleStyle,
    );
  }

  bool _sameSearchText(String left, String right) {
    return normalizeForSearch(left) == normalizeForSearch(right);
  }
}

class _EmptyItemsView extends StatelessWidget {
  const _EmptyItemsView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 0),
      child: Text(
        'Mahsulot topilmadi',
        style: Theme.of(context).textTheme.bodyLarge,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: scheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              'Mahsulotlar yuklanmadi',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _PillButton(
              enabled: true,
              onTap: onRetry,
              child: const Text('Qayta urinish'),
            ),
          ],
        ),
      ),
    );
  }
}
