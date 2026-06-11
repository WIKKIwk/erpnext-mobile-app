import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/app_entry_screen.dart';
import '../features/customer/presentation/customer_delivery_detail_screen.dart';
import '../features/customer/presentation/customer_home_screen.dart';
import '../features/customer/presentation/customer_notifications_screen.dart';
import '../features/customer/presentation/customer_status_detail_screen.dart';
import '../features/admin/presentation/admin_activity_screen.dart';
import '../features/admin/presentation/admin_apparatus_groups_screen.dart';
import '../features/admin/presentation/admin_calculate_screen.dart';
import '../features/admin/presentation/admin_calculate_orders_screen.dart';
import '../features/admin/presentation/admin_create_hub_screen.dart';
import '../features/admin/presentation/admin_home_screen.dart';
import '../features/admin/presentation/admin_inactive_suppliers_screen.dart';
import '../features/admin/presentation/admin_item_create_screen.dart';
import '../features/admin/presentation/admin_item_group_create_screen.dart';
import '../features/admin/presentation/admin_settings_screen.dart';
import '../features/admin/presentation/admin_roles_screen.dart';
import '../features/admin/presentation/admin_production_map_test_screen.dart';
import '../features/admin/presentation/admin_production_map_orders_screen.dart';
import '../features/admin/presentation/admin_supplier_create_screen.dart';
import '../features/admin/presentation/admin_customer_create_screen.dart';
import '../features/admin/presentation/admin_customer_detail_screen.dart';
import '../features/admin/presentation/admin_supplier_detail_screen.dart';
import '../features/admin/presentation/admin_supplier_items_add_screen.dart';
import '../features/admin/presentation/admin_supplier_items_view_screen.dart';
import '../features/admin/presentation/admin_suppliers_screen.dart';
import '../features/admin/presentation/admin_user_create_screen.dart';
import '../features/admin/presentation/admin_werka_screen.dart';
import '../features/admin/models/production_map_models.dart';
import '../features/admin/state/calculate_order_store.dart';
import '../features/gscale/presentation/gscale_mode_screen.dart';
import '../features/rezka/presentation/rezka_split_screen.dart';
import '../features/shared/models/app_models.dart';
import '../features/shared/presentation/pin_setup_confirm_screen.dart';
import '../features/shared/presentation/pin_setup_entry_screen.dart';
import '../features/shared/presentation/notification_detail_screen.dart';
import '../features/shared/presentation/profile_screen.dart';
import '../features/supplier/presentation/supplier_confirm_screen.dart';
import '../features/supplier/presentation/supplier_home_screen.dart';
import '../features/supplier/presentation/supplier_item_picker_screen.dart';
import '../features/supplier/presentation/supplier_notifications_screen.dart';
import '../features/supplier/presentation/supplier_status_breakdown_screen.dart';
import '../features/supplier/presentation/supplier_submitted_category_detail_screen.dart';
import '../features/supplier/presentation/supplier_status_detail_screen.dart';
import '../features/supplier/presentation/supplier_qty_screen.dart';
import '../features/supplier/presentation/supplier_recent_screen.dart';
import '../features/supplier/presentation/supplier_success_screen.dart';
import '../features/werka/presentation/werka_detail_screen.dart';
import '../features/werka/presentation/werka_archive_screen.dart';
import '../features/werka/presentation/werka_archive_sent_hub_screen.dart';
import '../features/werka/presentation/werka_archive_daily_calendar_screen.dart';
import '../features/werka/presentation/werka_archive_monthly_calendar_screen.dart';
import '../features/werka/presentation/werka_archive_yearly_calendar_screen.dart';
import '../features/werka/presentation/werka_archive_period_screen.dart';
import '../features/werka/presentation/werka_archive_list_screen.dart';
import '../features/werka/presentation/werka_home_screen.dart';
import '../features/werka/presentation/werka_batch_dispatch_screen.dart';
import '../features/werka/presentation/werka_create_hub_screen.dart';
import '../features/werka/presentation/werka_customer_issue_customer_screen.dart';
import '../features/werka/presentation/werka_customer_issue_prefill.dart';
import '../features/werka/presentation/werka_customer_delivery_detail_screen.dart';
import '../features/werka/presentation/werka_notifications_screen.dart';
import '../features/werka/presentation/werka_archive_batch_qr_lookup_screen.dart';
import '../features/werka/presentation/werka_stock_entry_lookup_screen.dart';
import '../features/werka/presentation/werka_stock_entry_qr_scan_screen.dart';
import '../features/werka/presentation/werka_unannounced_supplier_screen.dart';
import '../features/werka/presentation/werka_status_detail_screen.dart';
import '../features/werka/presentation/werka_status_breakdown_screen.dart';
import '../features/werka/presentation/werka_success_screen.dart';
import '../core/session/state/app_session.dart';
import '../core/theme/app_motion.dart';
import 'package:full_screen_back_gesture/cupertino.dart'
    as fullscreen_cupertino;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppRoutes {
  static const String login = '/';
  static const String supplierHome = '/supplier-home';
  static const String supplierStatusBreakdown = '/supplier-status-breakdown';
  static const String supplierSubmittedCategoryDetail =
      '/supplier-submitted-category-detail';
  static const String supplierStatusDetail = '/supplier-status-detail';
  static const String supplierItemPicker = '/supplier-item-picker';
  static const String supplierQty = '/supplier-qty';
  static const String supplierConfirm = '/supplier-confirm';
  static const String supplierSuccess = '/supplier-success';
  static const String supplierNotifications = '/supplier-notifications';
  static const String supplierRecent = '/supplier-recent';
  static const String notificationDetail = '/notification-detail';
  static const String werkaHome = '/werka-home';
  static const String werkaCreateHub = '/werka-create-hub';
  static const String werkaBatchDispatch = '/werka-batch-dispatch';
  static const String werkaCustomerIssueCustomer =
      '/werka-customer-issue-customer';
  static const String werkaUnannouncedSupplier = '/werka-unannounced-supplier';
  static const String werkaStockEntryQrScan = '/werka-stock-entry-qr-scan';
  static const String werkaStockEntryLookup = '/werka-stock-entry-lookup';
  static const String werkaArchiveBatchQrLookup =
      '/werka-archive-batch-qr-lookup';
  static const String werkaNotifications = '/werka-notifications';
  static const String werkaArchive = '/werka-archive';
  static const String werkaArchiveSentHub = '/werka-archive-sent-hub';
  static const String werkaArchiveDailyCalendar =
      '/werka-archive-daily-calendar';
  static const String werkaArchiveMonthlyCalendar =
      '/werka-archive-monthly-calendar';
  static const String werkaArchiveYearlyCalendar =
      '/werka-archive-yearly-calendar';
  static const String werkaArchivePeriods = '/werka-archive-periods';
  static const String werkaArchiveList = '/werka-archive-list';
  static const String werkaStatusBreakdown = '/werka-status-breakdown';
  static const String werkaStatusDetail = '/werka-status-detail';
  static const String werkaDetail = '/werka-detail';
  static const String werkaCustomerDeliveryDetail =
      '/werka-customer-delivery-detail';
  static const String werkaSuccess = '/werka-success';
  static const String profile = '/profile';
  static const String customerHome = '/customer-home';
  static const String customerNotifications = '/customer-notifications';
  static const String customerStatusDetail = '/customer-status-detail';
  static const String customerDetail = '/customer-detail';
  static const String pinSetupEntry = '/pin-setup-entry';
  static const String pinSetupConfirm = '/pin-setup-confirm';
  static const String adminHome = '/admin-home';
  static const String adminActivity = '/admin-activity';
  static const String adminCalculate = '/admin-calculate';
  static const String adminCalculateOrders = '/admin-calculate-orders';
  static const String adminCreateHub = '/admin-create-hub';
  static const String adminSettings = '/admin-settings';
  static const String adminRoles = '/admin-roles';
  static const String adminProductionMapTest = '/admin-production-map-test';
  static const String adminProductionMapOrders = '/admin-production-map-orders';
  static const String adminApparatusGroups = '/admin-apparatus-groups';
  static const String apparatusQueue = '/apparatus-queue';
  static const String adminSuppliers = '/admin-suppliers';
  static const String adminUserCreate = '/admin-user-create';
  static const String adminSupplierCreate = '/admin-supplier-create';
  static const String adminCustomerCreate = '/admin-customer-create';
  static const String adminCustomerDetail = '/admin-customer-detail';
  static const String adminInactiveSuppliers = '/admin-inactive-suppliers';
  static const String adminItemCreate = '/admin-item-create';
  static const String adminItemGroupCreate = '/admin-item-group-create';
  static const String adminItemBulkMove = '/admin-item-bulk-move';
  static const String adminSupplierDetail = '/admin-supplier-detail';
  static const String adminSupplierItemsView = '/admin-supplier-items-view';
  static const String adminSupplierItemsAdd = '/admin-supplier-items-add';
  static const String adminWerka = '/admin-werka';
  static const String gscaleMode = '/gscale-mode';
  static const String rezkaSplit = '/rezka-split';
}

class AppRouter {
  static const Set<String> staticDockRoutes = {
    AppRoutes.supplierHome,
    AppRoutes.supplierNotifications,
    AppRoutes.supplierRecent,
    AppRoutes.werkaHome,
    AppRoutes.werkaNotifications,
    AppRoutes.werkaArchive,
    AppRoutes.adminHome,
    AppRoutes.adminActivity,
    AppRoutes.adminCalculate,
    AppRoutes.adminCalculateOrders,
    AppRoutes.adminCreateHub,
    AppRoutes.adminSettings,
    AppRoutes.adminRoles,
    AppRoutes.adminProductionMapTest,
    AppRoutes.adminProductionMapOrders,
    AppRoutes.adminApparatusGroups,
    AppRoutes.apparatusQueue,
    AppRoutes.adminSuppliers,
    AppRoutes.adminUserCreate,
    AppRoutes.adminWerka,
    AppRoutes.profile,
    AppRoutes.customerHome,
    AppRoutes.customerNotifications,
  };

  static const Set<String> edgeSwipeBackRoutes = {
    AppRoutes.notificationDetail,
    AppRoutes.customerStatusDetail,
    AppRoutes.customerDetail,
    AppRoutes.pinSetupEntry,
    AppRoutes.pinSetupConfirm,
    AppRoutes.supplierStatusBreakdown,
    AppRoutes.supplierSubmittedCategoryDetail,
    AppRoutes.supplierStatusDetail,
    AppRoutes.supplierQty,
    AppRoutes.werkaArchiveSentHub,
    AppRoutes.werkaArchiveDailyCalendar,
    AppRoutes.werkaArchiveMonthlyCalendar,
    AppRoutes.werkaArchiveYearlyCalendar,
    AppRoutes.werkaArchivePeriods,
    AppRoutes.werkaArchiveList,
    AppRoutes.werkaStatusBreakdown,
    AppRoutes.werkaStatusDetail,
    AppRoutes.werkaDetail,
    AppRoutes.werkaCustomerDeliveryDetail,
    AppRoutes.werkaBatchDispatch,
    AppRoutes.werkaCustomerIssueCustomer,
    AppRoutes.werkaUnannouncedSupplier,
    AppRoutes.werkaStockEntryQrScan,
    AppRoutes.werkaStockEntryLookup,
    AppRoutes.werkaArchiveBatchQrLookup,
    AppRoutes.adminSettings,
    AppRoutes.adminRoles,
    AppRoutes.adminProductionMapTest,
    AppRoutes.adminProductionMapOrders,
    AppRoutes.adminApparatusGroups,
    AppRoutes.apparatusQueue,
    AppRoutes.adminCalculate,
    AppRoutes.adminCalculateOrders,
    AppRoutes.adminSupplierCreate,
    AppRoutes.adminCustomerCreate,
    AppRoutes.adminCustomerDetail,
    AppRoutes.adminInactiveSuppliers,
    AppRoutes.adminItemCreate,
    AppRoutes.adminItemGroupCreate,
    AppRoutes.adminItemBulkMove,
    AppRoutes.adminSupplierDetail,
    AppRoutes.adminSupplierItemsView,
    AppRoutes.adminSupplierItemsAdd,
    AppRoutes.adminWerka,
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    if (!canOpenRoute(settings.name)) {
      return _buildRoute(settings, const _CapabilityDeniedScreen());
    }
    switch (settings.name) {
      case AppRoutes.login:
        return _buildRoute(settings, const AppEntryScreen());
      case AppRoutes.supplierHome:
        return _buildRoute(settings, const SupplierHomeScreen());
      case AppRoutes.supplierStatusBreakdown:
        final SupplierStatusKind kind =
            settings.arguments as SupplierStatusKind;
        return _buildRoute(
          settings,
          SupplierStatusBreakdownScreen(kind: kind),
        );
      case AppRoutes.supplierSubmittedCategoryDetail:
        final SupplierSubmittedCategoryArgs args =
            settings.arguments as SupplierSubmittedCategoryArgs;
        return _buildRoute(
          settings,
          SupplierSubmittedCategoryDetailScreen(args: args),
        );
      case AppRoutes.supplierStatusDetail:
        final SupplierStatusDetailArgs args =
            settings.arguments as SupplierStatusDetailArgs;
        return _buildRoute(
          settings,
          SupplierStatusDetailScreen(args: args),
        );
      case AppRoutes.supplierItemPicker:
        return _buildRoute(settings, const SupplierItemPickerScreen());
      case AppRoutes.supplierQty:
        if (settings.arguments is SupplierQtyArgs) {
          final SupplierQtyArgs args = settings.arguments as SupplierQtyArgs;
          return _buildRoute(
            settings,
            SupplierQtyScreen(
              item: args.item,
              initialQty: args.initialQty,
            ),
          );
        }
        final SupplierItem item = settings.arguments as SupplierItem;
        return _buildRoute(settings, SupplierQtyScreen(item: item));
      case AppRoutes.supplierConfirm:
        final SupplierConfirmArgs args =
            settings.arguments as SupplierConfirmArgs;
        return _buildRoute(settings, SupplierConfirmScreen(args: args));
      case AppRoutes.supplierSuccess:
        final DispatchRecord record = settings.arguments as DispatchRecord;
        return _buildRoute(settings, SupplierSuccessScreen(record: record));
      case AppRoutes.supplierNotifications:
        return _buildRoute(settings, const SupplierNotificationsScreen());
      case AppRoutes.supplierRecent:
        return _buildRoute(settings, const SupplierRecentScreen());
      case AppRoutes.notificationDetail:
        final String receiptID = settings.arguments as String;
        return _buildRoute(
          settings,
          NotificationDetailScreen(receiptID: receiptID),
        );
      case AppRoutes.werkaHome:
        return _buildRoute(settings, const WerkaHomeScreen());
      case AppRoutes.werkaCreateHub:
        return _buildRoute(settings, const WerkaCreateHubScreen());
      case AppRoutes.werkaBatchDispatch:
        return _buildRoute(settings, const WerkaBatchDispatchScreen());
      case AppRoutes.werkaCustomerIssueCustomer:
        final WerkaCustomerIssuePrefillArgs? args =
            settings.arguments is WerkaCustomerIssuePrefillArgs
                ? settings.arguments as WerkaCustomerIssuePrefillArgs
                : null;
        return _buildRoute(
          settings,
          WerkaCustomerIssueCustomerScreen(prefill: args),
        );
      case AppRoutes.werkaUnannouncedSupplier:
        final WerkaUnannouncedPrefillArgs? args =
            settings.arguments is WerkaUnannouncedPrefillArgs
                ? settings.arguments as WerkaUnannouncedPrefillArgs
                : null;
        return _buildRoute(
          settings,
          WerkaUnannouncedSupplierScreen(prefill: args),
        );
      case AppRoutes.werkaStockEntryQrScan:
        return _buildRoute(settings, const WerkaStockEntryQrScanScreen());
      case AppRoutes.werkaStockEntryLookup:
        final WerkaStockEntryLookupArgs args =
            settings.arguments as WerkaStockEntryLookupArgs;
        return _buildRoute(
          settings,
          WerkaStockEntryLookupScreen(args: args),
        );
      case AppRoutes.werkaArchiveBatchQrLookup:
        final WerkaArchiveBatchQrLookupArgs args =
            settings.arguments as WerkaArchiveBatchQrLookupArgs;
        return _buildRoute(
          settings,
          WerkaArchiveBatchQrLookupScreen(args: args),
        );
      case AppRoutes.werkaNotifications:
        return _buildRoute(settings, const WerkaNotificationsScreen());
      case AppRoutes.werkaArchive:
        return _buildRoute(settings, const WerkaArchiveScreen());
      case AppRoutes.werkaArchiveSentHub:
        return _buildRoute(settings, const WerkaArchiveSentHubScreen());
      case AppRoutes.werkaArchiveDailyCalendar:
        final WerkaArchiveKind kind = settings.arguments is WerkaArchiveKind
            ? settings.arguments as WerkaArchiveKind
            : WerkaArchiveKind.sent;
        return _buildRoute(
          settings,
          WerkaArchiveDailyCalendarScreen(kind: kind),
        );
      case AppRoutes.werkaArchiveMonthlyCalendar:
        final WerkaArchiveKind kind = settings.arguments is WerkaArchiveKind
            ? settings.arguments as WerkaArchiveKind
            : WerkaArchiveKind.sent;
        return _buildRoute(
          settings,
          WerkaArchiveMonthlyCalendarScreen(kind: kind),
        );
      case AppRoutes.werkaArchiveYearlyCalendar:
        final WerkaArchiveKind kind = settings.arguments is WerkaArchiveKind
            ? settings.arguments as WerkaArchiveKind
            : WerkaArchiveKind.sent;
        return _buildRoute(
          settings,
          WerkaArchiveYearlyCalendarScreen(kind: kind),
        );
      case AppRoutes.werkaArchivePeriods:
        final WerkaArchiveKind kind = settings.arguments is WerkaArchiveKind
            ? settings.arguments as WerkaArchiveKind
            : WerkaArchiveKind.sent;
        return _buildRoute(
          settings,
          WerkaArchivePeriodScreen(kind: kind),
        );
      case AppRoutes.werkaArchiveList:
        final WerkaArchiveListArgs args =
            settings.arguments is WerkaArchiveListArgs
                ? settings.arguments as WerkaArchiveListArgs
                : const WerkaArchiveListArgs(
                    kind: WerkaArchiveKind.sent,
                    period: WerkaArchivePeriod.daily,
                  );
        return _buildRoute(
          settings,
          WerkaArchiveListScreen(args: args),
        );
      case AppRoutes.werkaStatusBreakdown:
        final WerkaStatusKind kind = settings.arguments as WerkaStatusKind;
        return _buildRoute(
          settings,
          WerkaStatusBreakdownScreen(kind: kind),
        );
      case AppRoutes.werkaStatusDetail:
        final WerkaStatusDetailArgs args =
            settings.arguments as WerkaStatusDetailArgs;
        return _buildRoute(
          settings,
          WerkaStatusDetailScreen(args: args),
        );
      case AppRoutes.werkaDetail:
        final DispatchRecord record = settings.arguments as DispatchRecord;
        return _buildRoute(settings, WerkaDetailScreen(record: record));
      case AppRoutes.werkaCustomerDeliveryDetail:
        final DispatchRecord record = settings.arguments as DispatchRecord;
        return _buildRoute(
          settings,
          WerkaCustomerDeliveryDetailScreen(record: record),
        );
      case AppRoutes.werkaSuccess:
        final args = settings.arguments;
        if (args is WerkaSuccessArgs) {
          return _buildRoute(settings, WerkaSuccessScreen.fromArgs(args));
        }
        final DispatchRecord record = args as DispatchRecord;
        return _buildRoute(settings, WerkaSuccessScreen(record: record));
      case AppRoutes.profile:
        return _buildRoute(settings, const ProfileScreen());
      case AppRoutes.customerHome:
        return _buildRoute(settings, const CustomerHomeScreen());
      case AppRoutes.customerNotifications:
        return _buildRoute(settings, const CustomerNotificationsScreen());
      case AppRoutes.customerStatusDetail:
        final CustomerStatusKind kind =
            settings.arguments as CustomerStatusKind;
        return _buildRoute(
          settings,
          CustomerStatusDetailScreen(kind: kind),
        );
      case AppRoutes.customerDetail:
        final String deliveryNoteID = settings.arguments as String;
        return _buildRoute(
          settings,
          CustomerDeliveryDetailScreen(deliveryNoteID: deliveryNoteID),
        );
      case AppRoutes.pinSetupEntry:
        return _buildRoute(settings, const PinSetupEntryScreen());
      case AppRoutes.pinSetupConfirm:
        final PinSetupConfirmArgs args =
            settings.arguments as PinSetupConfirmArgs;
        return _buildRoute(settings, PinSetupConfirmScreen(args: args));
      case AppRoutes.adminHome:
        return _buildRoute(settings, const AdminHomeScreen());
      case AppRoutes.adminActivity:
        return _buildRoute(settings, const AdminActivityScreen());
      case AppRoutes.adminCalculate:
        final CalculateOrderTemplate? template =
            settings.arguments is CalculateOrderTemplate
                ? settings.arguments as CalculateOrderTemplate
                : null;
        return _buildRoute(
          settings,
          AdminCalculateScreen(template: template),
        );
      case AppRoutes.adminCalculateOrders:
        return _buildRoute(settings, const AdminCalculateOrdersScreen());
      case AppRoutes.adminCreateHub:
        return _buildRoute(settings, const AdminCreateHubScreen());
      case AppRoutes.adminSettings:
        return _buildAdminSettingsRoute(settings, const AdminSettingsScreen());
      case AppRoutes.adminRoles:
        return _buildRoute(settings, const AdminRolesScreen());
      case AppRoutes.adminProductionMapTest:
        final ProductionMapOrderContext? orderContext =
            settings.arguments is ProductionMapOrderContext
                ? settings.arguments as ProductionMapOrderContext
                : null;
        final ProductionMapSaved? savedMap =
            settings.arguments is ProductionMapSaved
                ? settings.arguments as ProductionMapSaved
                : null;
        return _buildRoute(
          settings,
          AdminProductionMapTestScreen(
            orderContext: orderContext,
            savedMap: savedMap?.map,
          ),
        );
      case AppRoutes.adminProductionMapOrders:
        return _buildRoute(settings, const AdminProductionMapOrdersScreen());
      case AppRoutes.adminApparatusGroups:
        return _buildRoute(settings, const AdminApparatusGroupsScreen());
      case AppRoutes.apparatusQueue:
        return _buildRoute(
          settings,
          const AdminProductionMapOrdersScreen(
            readOnly: true,
            workerMode: true,
          ),
        );
      case AppRoutes.adminSuppliers:
        return _buildRoute(settings, const AdminSuppliersScreen());
      case AppRoutes.adminUserCreate:
        return _buildRoute(settings, const AdminUserCreateScreen());
      case AppRoutes.adminSupplierCreate:
        return _buildRoute(settings, const AdminSupplierCreateScreen());
      case AppRoutes.adminCustomerCreate:
        return _buildRoute(settings, const AdminCustomerCreateScreen());
      case AppRoutes.adminCustomerDetail:
        final String customerRef = settings.arguments as String;
        return _buildRoute(
          settings,
          AdminCustomerDetailScreen(customerRef: customerRef),
        );
      case AppRoutes.adminInactiveSuppliers:
        return _buildRoute(settings, const AdminInactiveSuppliersScreen());
      case AppRoutes.adminItemCreate:
        final int initialTabIndex =
            settings.arguments is int ? settings.arguments as int : 0;
        return _buildRoute(
          settings,
          AdminItemCreateScreen(initialTabIndex: initialTabIndex),
        );
      case AppRoutes.adminItemGroupCreate:
        return _buildRoute(settings, const AdminItemGroupCreateScreen());
      case AppRoutes.adminItemBulkMove:
        return _buildRoute(
          settings,
          const AdminItemCreateScreen(initialTabIndex: 2),
        );
      case AppRoutes.adminSupplierDetail:
        final String supplierRef = settings.arguments as String;
        return _buildRoute(
          settings,
          AdminSupplierDetailScreen(supplierRef: supplierRef),
        );
      case AppRoutes.adminSupplierItemsView:
        final String supplierRef = settings.arguments as String;
        return _buildRoute(
          settings,
          AdminSupplierItemsViewScreen(supplierRef: supplierRef),
        );
      case AppRoutes.adminSupplierItemsAdd:
        final String supplierRef = settings.arguments as String;
        return _buildRoute(
          settings,
          AdminSupplierItemsAddScreen(supplierRef: supplierRef),
        );
      case AppRoutes.adminWerka:
        return _buildRoute(settings, const AdminWerkaScreen());
      case AppRoutes.gscaleMode:
        return _buildRoute(settings, const GScaleModeScreen());
      case AppRoutes.rezkaSplit:
        return _buildRoute(settings, const RezkaSplitScreen());
      default:
        return _buildRoute(settings, const LoginScreen());
    }
  }

  static bool canOpenRoute(String? routeName) {
    if (routeName == null ||
        routeName == AppRoutes.login ||
        routeName == AppRoutes.profile ||
        routeName == AppRoutes.pinSetupEntry ||
        routeName == AppRoutes.pinSetupConfirm) {
      return true;
    }
    final profile = AppSession.instance.profile;
    if (profile == null) {
      return true;
    }
    final required = _routeCapabilities[routeName];
    if (required == null) {
      return true;
    }
    return profile.hasAnyCapability(required);
  }

  static const Map<String, Set<String>> _routeCapabilities = {
    AppRoutes.supplierHome: {'supplier.access'},
    AppRoutes.supplierStatusBreakdown: {'supplier.access'},
    AppRoutes.supplierSubmittedCategoryDetail: {'supplier.access'},
    AppRoutes.supplierStatusDetail: {'supplier.access'},
    AppRoutes.supplierItemPicker: {'supplier.access'},
    AppRoutes.supplierQty: {'supplier.access'},
    AppRoutes.supplierConfirm: {'supplier.access'},
    AppRoutes.supplierSuccess: {'supplier.access'},
    AppRoutes.supplierNotifications: {'supplier.access'},
    AppRoutes.supplierRecent: {'supplier.access'},
    AppRoutes.customerHome: {'customer.access'},
    AppRoutes.customerNotifications: {'customer.access'},
    AppRoutes.customerStatusDetail: {'customer.access'},
    AppRoutes.customerDetail: {'customer.access'},
    AppRoutes.notificationDetail: {
      'supplier.access',
      'werka.access',
      'customer.access',
    },
    AppRoutes.werkaHome: {'werka.access'},
    AppRoutes.werkaCreateHub: {'werka.access'},
    AppRoutes.werkaBatchDispatch: {'werka.access'},
    AppRoutes.werkaCustomerIssueCustomer: {'werka.access'},
    AppRoutes.werkaUnannouncedSupplier: {'werka.access'},
    AppRoutes.werkaStockEntryQrScan: {'werka.access'},
    AppRoutes.werkaStockEntryLookup: {'werka.access'},
    AppRoutes.werkaArchiveBatchQrLookup: {'werka.access'},
    AppRoutes.werkaNotifications: {'werka.access'},
    AppRoutes.werkaArchive: {'werka.access'},
    AppRoutes.werkaArchiveSentHub: {'werka.access'},
    AppRoutes.werkaArchiveDailyCalendar: {'werka.access'},
    AppRoutes.werkaArchiveMonthlyCalendar: {'werka.access'},
    AppRoutes.werkaArchiveYearlyCalendar: {'werka.access'},
    AppRoutes.werkaArchivePeriods: {'werka.access'},
    AppRoutes.werkaArchiveList: {'werka.access'},
    AppRoutes.werkaStatusBreakdown: {'werka.access'},
    AppRoutes.werkaStatusDetail: {'werka.access'},
    AppRoutes.werkaDetail: {'werka.access'},
    AppRoutes.werkaCustomerDeliveryDetail: {'werka.access'},
    AppRoutes.werkaSuccess: {'werka.access'},
    AppRoutes.gscaleMode: {
      'gscale.catalog.read',
      'gscale.print',
      'rps.batch.manage',
    },
    AppRoutes.rezkaSplit: {'rezka.split.manage'},
    AppRoutes.adminHome: {
      'admin.access',
      'role.capability.read',
      'role.capability.manage',
      'admin.settings.read',
      'admin.settings.manage',
      'catalog.item.read',
      'catalog.item.create',
      'catalog.item_group.read',
      'catalog.item_group.manage',
      'catalog.item.bulk_move',
      'party.supplier.read',
      'party.supplier.manage',
      'party.supplier.item.assign',
      'party.supplier.code.manage',
      'party.customer.read',
      'party.customer.manage',
      'party.customer.item.assign',
      'party.customer.code.manage',
      'admin.activity.read',
      'werka.code.manage',
      'production.map.manage',
      'rezka.split.manage',
    },
    AppRoutes.adminActivity: {'admin.activity.read'},
    AppRoutes.adminCalculate: {
      'admin.access',
      'production.map.manage',
    },
    AppRoutes.adminCalculateOrders: {
      'admin.access',
      'production.map.manage',
    },
    AppRoutes.adminCreateHub: {
      'catalog.item.create',
      'catalog.item_group.manage',
      'party.supplier.manage',
      'party.customer.manage',
      'werka.code.manage',
      'role.capability.manage',
    },
    AppRoutes.adminSettings: {'admin.settings.read'},
    AppRoutes.adminRoles: {'role.capability.read'},
    AppRoutes.adminProductionMapTest: {
      'admin.access',
      'production.map.manage',
    },
    AppRoutes.adminProductionMapOrders: {
      'admin.access',
      'production.map.manage',
    },
    AppRoutes.adminApparatusGroups: {
      'admin.access',
      'production.map.manage',
    },
    AppRoutes.apparatusQueue: {
      'apparatus.queue.read',
      'apparatus.queue.manage',
    },
    AppRoutes.adminSuppliers: {
      'party.supplier.read',
      'party.customer.read',
    },
    AppRoutes.adminUserCreate: {
      'party.supplier.manage',
      'party.customer.manage',
      'werka.code.manage',
    },
    AppRoutes.adminSupplierCreate: {'party.supplier.manage'},
    AppRoutes.adminCustomerCreate: {'party.customer.manage'},
    AppRoutes.adminCustomerDetail: {'party.customer.read'},
    AppRoutes.adminInactiveSuppliers: {'party.supplier.read'},
    AppRoutes.adminItemCreate: {
      'catalog.item.read',
      'catalog.item.create',
      'catalog.item.bulk_move',
    },
    AppRoutes.adminItemGroupCreate: {'catalog.item_group.manage'},
    AppRoutes.adminItemBulkMove: {'catalog.item.bulk_move'},
    AppRoutes.adminSupplierDetail: {'party.supplier.read'},
    AppRoutes.adminSupplierItemsView: {'party.supplier.item.assign'},
    AppRoutes.adminSupplierItemsAdd: {'party.supplier.item.assign'},
    AppRoutes.adminWerka: {'werka.code.manage'},
  };

  static PageRoute<dynamic> _buildRoute(RouteSettings settings, Widget child) {
    if (_usesAdminPageTransition(settings.name)) {
      return PageRouteBuilder<dynamic>(
        settings: settings,
        transitionDuration: AppMotion.pageEnter,
        reverseTransitionDuration: AppMotion.pageExit,
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final enter = CurvedAnimation(
            parent: animation,
            curve: const Interval(0.0, 1.0, curve: AppMotion.pageIn),
            reverseCurve: AppMotion.pageOut,
          );
          final fadeIn = CurvedAnimation(
            parent: animation,
            curve: const Interval(0.08, 1.0,
                curve: AppMotion.emphasizedDecelerate),
            reverseCurve: AppMotion.pageOut,
          );
          final slideIn = Tween<Offset>(
            begin: const Offset(0, 0.045),
            end: Offset.zero,
          ).animate(enter);
          final scaleIn = Tween<double>(
            begin: 0.985,
            end: 1.0,
          ).animate(enter);
          return FadeTransition(
            opacity: fadeIn,
            child: SlideTransition(
              position: slideIn,
              child: ScaleTransition(
                scale: scaleIn,
                child: child,
              ),
            ),
          );
        },
      );
    }
    if (_shouldUseEdgeSwipeBack(settings)) {
      return fullscreen_cupertino.CupertinoPageRoute<dynamic>(
        settings: settings,
        builder: (context) {
          return child;
        },
      );
    }
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (context) {
        return child;
      },
    );
  }

  static PageRoute<dynamic> _buildAdminSettingsRoute(
    RouteSettings settings,
    Widget child,
  ) {
    if (_shouldUseEdgeSwipeBack(settings)) {
      return fullscreen_cupertino.CupertinoPageRoute<dynamic>(
        settings: settings,
        builder: (context) {
          return child;
        },
      );
    }
    return MaterialPageRoute<dynamic>(
      settings: settings,
      builder: (context) {
        return child;
      },
    );
  }

  static bool _shouldUseEdgeSwipeBack(RouteSettings settings) {
    return !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        edgeSwipeBackRoutes.contains(settings.name);
  }

  static bool _usesAdminPageTransition(String? routeName) {
    return false;
  }
}

class _CapabilityDeniedScreen extends StatelessWidget {
  const _CapabilityDeniedScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Ruxsat yo‘q'),
      ),
    );
  }
}
