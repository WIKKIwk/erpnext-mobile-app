import '../../../core/api/mobile_api.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/app_loading_indicator.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/app_retry_state.dart';
import '../../../core/widgets/motion_widgets.dart';
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
        leading: AppShellIconAction(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.of(context).pop(changed),
        ),
        title: context.l10n.adminSettingsTitle,
        subtitle: '',
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

          return ListView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
            children: [
              SmoothAppear(
                delay: const Duration(milliseconds: 20),
                child: _SettingsSectionCard(
                  title: context.l10n.erpConnectionTitle,
                  subtitle: context.l10n.erpConnectionSubtitle,
                  child: Column(
                    children: [
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
              ),
              const SizedBox(height: 16),
              SmoothAppear(
                delay: const Duration(milliseconds: 60),
                child: _SettingsSectionCard(
                  title: context.l10n.adminSettingsSectionTitle,
                  subtitle: context.l10n.adminSettingsSectionSubtitle,
                  child: Column(
                    children: [
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
                            saving
                                ? context.l10n.pinSaving
                                : context.l10n.save,
                          ),
                        ),
                      ),
                    ],
                  ),
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

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card.filled(
      margin: EdgeInsets.zero,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            child,
          ],
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
