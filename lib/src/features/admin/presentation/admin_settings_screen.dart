import '../../../core/api/mobile_api.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/shell/app_loading_indicator.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../../core/widgets/shell/app_retry_state.dart';
import '../../../core/widgets/display/motion_widgets.dart';
import '../../shared/models/app_models.dart';
import 'widgets/admin_dock.dart';
import 'package:flutter/material.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  late Future<AdminSettings> _future;
  final erpUrl = TextEditingController();
  final apiKey = TextEditingController();
  final apiSecret = TextEditingController();
  final warehouse = TextEditingController();
  final uom = TextEditingController();
  final werkaPhone = TextEditingController();
  final werkaName = TextEditingController();
  bool saving = false;
  bool changed = false;

  @override
  void initState() {
    super.initState();
    _future = MobileApi.instance.adminSettings();
  }

  @override
  void dispose() {
    erpUrl.dispose();
    apiKey.dispose();
    apiSecret.dispose();
    warehouse.dispose();
    uom.dispose();
    werkaPhone.dispose();
    werkaName.dispose();
    super.dispose();
  }

  void _fill(AdminSettings settings) {
    erpUrl.text = settings.erpUrl;
    apiKey.text = settings.erpApiKey;
    apiSecret.text = settings.erpApiSecret;
    warehouse.text = settings.defaultTargetWarehouse;
    uom.text = settings.defaultUom;
    werkaPhone.text = settings.werkaPhone;
    werkaName.text = settings.werkaName;
  }

  Future<void> _save() async {
    setState(() => saving = true);
    try {
      final current = await MobileApi.instance.adminSettings();
      final updated = await MobileApi.instance.updateAdminSettings(
        AdminSettings(
          erpUrl: erpUrl.text.trim(),
          erpApiKey: apiKey.text.trim(),
          erpApiSecret: apiSecret.text.trim(),
          defaultTargetWarehouse: warehouse.text.trim(),
          defaultUom: uom.text.trim(),
          werkaPhone: werkaPhone.text.trim(),
          werkaName: werkaName.text.trim(),
          werkaCode: current.werkaCode,
          werkaCodeLocked: current.werkaCodeLocked,
          werkaCodeRetryAfterSec: current.werkaCodeRetryAfterSec,
          adminPhone: current.adminPhone,
          adminName: current.adminName,
        ),
      );
      _fill(updated);
      changed = true;
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.settingsSaved)),
      );
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pop(changed);
      },
      child: AppShell(
        title: context.l10n.adminSettingsTitle,
        subtitle: '',
        nativeTopBar: true,
        nativeTitleTextStyle: AppTheme.werkaNativeAppBarTitleStyle(context),
        contentPadding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
        bottom: const AdminDock(activeTab: AdminDockTab.settings),
        child: FutureBuilder<AdminSettings>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: AppLoadingIndicator());
            }
            if (snapshot.hasError) {
              return AppRetryState(
                onRetry: () async {
                  setState(() {
                    _future = MobileApi.instance.adminSettings();
                  });
                },
              );
            }

            final settings = snapshot.data!;
            _fill(settings);
            final theme = Theme.of(context);
            final scheme = theme.colorScheme;
            final bottomPadding =
                MediaQuery.viewPaddingOf(context).bottom + 136.0;

            return ListView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(0, 4, 0, bottomPadding),
              children: [
                SmoothAppear(
                  delay: const Duration(milliseconds: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.erpConnectionTitle,
                          style: theme.textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text(
                        context.l10n.erpConnectionSubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SettingsField(
                        label: 'ERP URL',
                        controller: erpUrl,
                      ),
                      const SizedBox(height: 14),
                      _SettingsField(
                        label: 'API Key',
                        controller: apiKey,
                      ),
                      const SizedBox(height: 14),
                      _SettingsField(
                        label: 'API Secret',
                        controller: apiSecret,
                      ),
                      const SizedBox(height: 14),
                      _SettingsField(
                        label: 'Default Warehouse',
                        controller: warehouse,
                      ),
                      const SizedBox(height: 14),
                      _SettingsField(
                        label: 'Default UOM',
                        controller: uom,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SmoothAppear(
                  delay: const Duration(milliseconds: 60),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.l10n.adminSettingsSectionTitle,
                          style: theme.textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text(
                        context.l10n.adminSettingsSectionSubtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _SettingsField(
                        label: 'Werka Phone',
                        controller: werkaPhone,
                      ),
                      const SizedBox(height: 12),
                      _SettingsField(
                        label: 'Werka Name',
                        controller: werkaName,
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: saving ? null : _save,
                          icon: saving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_rounded),
                          label: Text(
                            saving ? context.l10n.pinSaving : context.l10n.save,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SettingsField extends StatelessWidget {
  const _SettingsField({
    required this.label,
    required this.controller,
  });

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
      ),
    );
  }
}
