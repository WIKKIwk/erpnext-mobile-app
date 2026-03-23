import '../../../core/api/mobile_api.dart';
import '../../../core/security/security_controller.dart';
import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/session/app_session.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../../core/widgets/top_refresh_scroll_physics.dart';
import '../data/profile_avatar_cache.dart';
import '../models/app_models.dart';
import '../../admin/presentation/widgets/admin_dock.dart';
import '../../supplier/presentation/widgets/supplier_dock.dart';
import '../../customer/presentation/widgets/customer_dock.dart';
import '../../werka/presentation/widgets/werka_dock.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with WidgetsBindingObserver {
  final TextEditingController nicknameController = TextEditingController();
  bool savingNickname = false;
  bool savingAvatar = false;
  bool savingPin = false;
  bool savingBiometric = false;
  String? errorMessage;
  File? cachedAvatar;
  Uint8List? pendingAvatarBytes;
  String? pendingAvatarName;

  SessionProfile get profile => AppSession.instance.profile!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    nicknameController.text = profile.displayName;
    _loadCachedAvatar();
  }

  Future<void> _loadCachedAvatar() async {
    final file = await ProfileAvatarCache.ensureCached(profile);
    if (!mounted) {
      return;
    }
    setState(() {
      cachedAvatar = file;
    });
  }

  Future<void> _refreshProfile() async {
    final updated = await MobileApi.instance.profile();
    final file = await ProfileAvatarCache.ensureCached(updated);
    if (!mounted) {
      return;
    }
    setState(() {
      nicknameController.text = updated.displayName;
      cachedAvatar = file;
      errorMessage = null;
    });
  }

  Future<void> _saveNickname() async {
    final nickname = nicknameController.text.trim();
    setState(() {
      savingNickname = true;
      errorMessage = null;
    });
    try {
      final updated = await MobileApi.instance.updateNickname(nickname);
      nicknameController.text = updated.displayName;
      if (!mounted) {
        return;
      }
      setState(() {});
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        errorMessage = context.l10n.nicknameSaveFailed;
      });
    } finally {
      if (mounted) {
        setState(() {
          savingNickname = false;
        });
      }
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return;
      }
      final picked = result.files.single;
      final bytes = picked.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('empty avatar');
      }
      if (!mounted) {
        return;
      }
      setState(() {
        errorMessage = null;
        pendingAvatarBytes = bytes;
        pendingAvatarName = picked.name;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        errorMessage = context.l10n.imagePickFailed;
      });
    }
  }

  Future<void> _saveAvatar() async {
    final bytes = pendingAvatarBytes;
    final filename = pendingAvatarName;
    if (bytes == null ||
        bytes.isEmpty ||
        filename == null ||
        filename.isEmpty) {
      return;
    }

    setState(() {
      savingAvatar = true;
      errorMessage = null;
    });
    try {
      final updated = await MobileApi.instance.uploadAvatar(
        bytes: bytes,
        filename: filename,
      );
      final file = await ProfileAvatarCache.cacheFromBytes(
        updated,
        bytes,
        filename,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        cachedAvatar = file;
        pendingAvatarBytes = null;
        pendingAvatarName = null;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        errorMessage = context.l10n.imageSaveFailed;
      });
    } finally {
      if (mounted) {
        setState(() {
          savingAvatar = false;
        });
      }
    }
  }

  bool get _hasNicknameChanges =>
      nicknameController.text.trim() != profile.displayName.trim();

  bool get _hasProfileChanges =>
      _hasNicknameChanges || pendingAvatarBytes != null;

  Future<void> _saveProfileChanges() async {
    if (_hasNicknameChanges) {
      await _saveNickname();
    }
    if (pendingAvatarBytes != null) {
      await _saveAvatar();
    }
  }

  Future<void> _showPinFlow() async {
    final result =
        await Navigator.of(context).pushNamed(AppRoutes.pinSetupEntry);
    if (result != true || !mounted) {
      return;
    }

    setState(() {
      savingPin = true;
      errorMessage = null;
    });
    try {
      final canUseBiometrics =
          await SecurityController.instance.canUseBiometrics();
      if (!mounted ||
          !canUseBiometrics ||
          SecurityController.instance.biometricEnabledForCurrentUser) {
        return;
      }
      final enable = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Tezkor ochish'),
            content: const Text(
              'Face ID yoki fingerprint bilan tez ochishni yoqasizmi?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Yo‘q'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Ha'),
              ),
            ],
          );
        },
      );
      if (enable == true) {
        await _toggleBiometric(true);
      } else {
        setState(() {});
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        errorMessage = 'PIN saqlanmadi';
      });
    } finally {
      if (mounted) {
        setState(() {
          savingPin = false;
        });
      }
    }
  }

  Future<void> _removePin() async {
    setState(() {
      savingPin = true;
      errorMessage = null;
    });
    try {
      await SecurityController.instance.clearPinForCurrentUser();
      if (!mounted) {
        return;
      }
      setState(() {});
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        errorMessage = 'PIN o‘chirilmadi';
      });
    } finally {
      if (mounted) {
        setState(() {
          savingPin = false;
        });
      }
    }
  }

  Future<void> _toggleBiometric(bool enabled) async {
    setState(() {
      savingBiometric = true;
      errorMessage = null;
    });
    try {
      final ok = await SecurityController.instance
          .setBiometricEnabledForCurrentUser(enabled);
      if (!ok && mounted) {
        setState(() {
          errorMessage = enabled
              ? 'Biometrik ochish yoqilmadi'
              : 'Biometrik ochish o‘chirilmadi';
        });
      } else if (mounted) {
        setState(() {});
      }
    } finally {
      if (mounted) {
        setState(() {
          savingBiometric = false;
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    nicknameController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _refreshProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LocaleController.instance,
      builder: (context, _) {
        final l10n = context.l10n;
        final current = profile;
        final role = current.role;
        final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
        final bottomPadding = bottomInset + 136.0;
        final subtitle = role == UserRole.supplier
            ? l10n.supplierAccount
            : role == UserRole.werka
                ? l10n.werkaAccount
                : role == UserRole.customer
                    ? l10n.customerAccount
                    : l10n.adminAccount;
        final bool hasPin = SecurityController.instance.hasPinForCurrentUser;
        final bool biometricEnabled =
            SecurityController.instance.biometricEnabledForCurrentUser;
        final bool savingProfileChanges = savingNickname || savingAvatar;

        return AppShell(
          title: l10n.profileTitle,
          subtitle: '',
          animateOnEnter: role != UserRole.customer,
          bottom: role == UserRole.supplier
              ? const SupplierDock(activeTab: SupplierDockTab.profile)
              : role == UserRole.werka
                  ? const WerkaDock(activeTab: WerkaDockTab.profile)
                  : role == UserRole.customer
                      ? const CustomerDock(activeTab: CustomerDockTab.profile)
                      : const AdminDock(activeTab: AdminDockTab.profile),
          contentPadding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
          child: AppRefreshIndicator(
            onRefresh: _refreshProfile,
            child: ListView(
              physics: const TopRefreshScrollPhysics(),
              padding: EdgeInsets.fromLTRB(0, 0, 0, bottomPadding),
              children: [
                SmoothAppear(
                  delay: const Duration(milliseconds: 20),
                  child: _ProfilePanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                _AvatarPreview(
                                  displayName: current.displayName,
                                  cachedAvatar: cachedAvatar,
                                  pendingAvatarBytes: pendingAvatarBytes,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: GestureDetector(
                                    onTap: savingAvatar ? null : _pickAvatar,
                                    child: Container(
                                      height: 32,
                                      width: 32,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerLow,
                                          width: 2,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.camera_alt_rounded,
                                        size: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    current.displayName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subtitle,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  if (current.phone.trim().isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.phone_rounded,
                                          size: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            current.phone,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if ((current.legalName.isEmpty
                                          ? current.displayName
                                          : current.legalName)
                                      .trim()
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.badge_rounded,
                                          size: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            current.legalName.isEmpty
                                                ? current.displayName
                                                : current.legalName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            _ThemeIconToggle(
                              isDark: ThemeController.instance.isDark,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: nicknameController,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: l10n.nicknameLabel,
                            hintText: l10n.nicknameHint,
                          ),
                        ),
                        if (_hasProfileChanges) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: savingProfileChanges
                                  ? null
                                  : _saveProfileChanges,
                              icon: savingProfileChanges
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.check_rounded),
                              label: Text(l10n.save),
                            ),
                          ),
                        ],
                        if (pendingAvatarBytes != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            l10n.selectedImageNotice,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 18),
                        _LanguagePreferenceRow(
                          currentLocale: LocaleController.instance.locale,
                        ),
                        const SizedBox(height: 16),
                        _ThemePreferenceRow(
                          variant: ThemeController.instance.variant,
                        ),
                        const SizedBox(height: 24),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withValues(alpha: 0.55),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          l10n.securityTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 14),
                        _ProfileActionButton(
                          primary: true,
                          onPressed: savingPin ? null : _showPinFlow,
                          label: savingPin
                              ? l10n.pinSaving
                              : hasPin
                                  ? l10n.pinChange
                                  : l10n.pinSet,
                        ),
                        if (hasPin) ...[
                          const SizedBox(height: 10),
                          _ProfileActionButton(
                            primary: false,
                            onPressed: savingPin ? null : _removePin,
                            label: l10n.pinRemove,
                          ),
                        ],
                        const SizedBox(height: 16),
                        _BiometricPreferenceRow(
                          enabled: biometricEnabled,
                          interactive: hasPin && !savingBiometric,
                          onChanged: (value) => _toggleBiometric(value),
                        ),
                      ],
                    ),
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 14),
                  _ProfilePanel(
                    child: Text(errorMessage!),
                  ),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(26),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: child,
      ),
    );
  }
}

class _LanguagePreferenceRow extends StatelessWidget {
  const _LanguagePreferenceRow({
    required this.currentLocale,
  });

  final Locale currentLocale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        final picked = await showModalBottomSheet<Locale>(
          context: context,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            return SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.languageTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 14),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.uzbek),
                          trailing: currentLocale.languageCode == 'uz'
                              ? Icon(Icons.check_rounded, color: scheme.primary)
                              : null,
                          onTap: () =>
                              Navigator.of(context).pop(const Locale('uz')),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.english),
                          trailing: currentLocale.languageCode == 'en'
                              ? Icon(Icons.check_rounded, color: scheme.primary)
                              : null,
                          onTap: () =>
                              Navigator.of(context).pop(const Locale('en')),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.russian),
                          trailing: currentLocale.languageCode == 'ru'
                              ? Icon(Icons.check_rounded, color: scheme.primary)
                              : null,
                          onTap: () =>
                              Navigator.of(context).pop(const Locale('ru')),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
        if (picked == null) {
          return;
        }
        await LocaleController.instance.setLocale(picked);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.languageTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.languageBody,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              currentLocale.languageCode == 'uz'
                  ? l10n.uzbek
                  : currentLocale.languageCode == 'ru'
                      ? l10n.russian
                      : l10n.english,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemePreferenceRow extends StatelessWidget {
  const _ThemePreferenceRow({
    required this.variant,
  });

  final AppThemeVariant variant;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        final picked = await showModalBottomSheet<AppThemeVariant>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            final mediaQuery = MediaQuery.of(context);
            return SafeArea(
              top: false,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerLow,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: mediaQuery.size.height * 0.72,
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.themeTitle,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 14),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(l10n.themeClassicLabel),
                            trailing: variant == AppThemeVariant.classic
                                ? Icon(Icons.check_rounded, color: scheme.primary)
                                : null,
                            onTap: () => Navigator.of(context)
                                .pop(AppThemeVariant.classic),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(l10n.themeEarthLabel),
                            trailing: variant == AppThemeVariant.earthy
                                ? Icon(Icons.check_rounded, color: scheme.primary)
                                : null,
                            onTap: () =>
                                Navigator.of(context).pop(AppThemeVariant.earthy),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(l10n.themeBlushLabel),
                            trailing: variant == AppThemeVariant.blush
                                ? Icon(Icons.check_rounded, color: scheme.primary)
                                : null,
                            onTap: () =>
                                Navigator.of(context).pop(AppThemeVariant.blush),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(l10n.themeMossLabel),
                            trailing: variant == AppThemeVariant.moss
                                ? Icon(Icons.check_rounded, color: scheme.primary)
                                : null,
                            onTap: () =>
                                Navigator.of(context).pop(AppThemeVariant.moss),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(l10n.themeVioletLabel),
                            trailing: variant == AppThemeVariant.violet
                                ? Icon(Icons.check_rounded, color: scheme.primary)
                                : null,
                            onTap: () =>
                                Navigator.of(context).pop(AppThemeVariant.violet),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(l10n.themeSlateLabel),
                            trailing: variant == AppThemeVariant.slate
                                ? Icon(Icons.check_rounded, color: scheme.primary)
                                : null,
                            onTap: () =>
                                Navigator.of(context).pop(AppThemeVariant.slate),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(l10n.themeOceanLabel),
                            trailing: variant == AppThemeVariant.ocean
                                ? Icon(Icons.check_rounded, color: scheme.primary)
                                : null,
                            onTap: () =>
                                Navigator.of(context).pop(AppThemeVariant.ocean),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
        if (picked == null) {
          return;
        }
        await ThemeController.instance.setVariant(picked);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.themeTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.themeBody,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              variant == AppThemeVariant.classic
                  ? l10n.themeClassicLabel
                  : variant == AppThemeVariant.blush
                      ? l10n.themeBlushLabel
                      : variant == AppThemeVariant.moss
                          ? l10n.themeMossLabel
                          : variant == AppThemeVariant.violet
                              ? l10n.themeVioletLabel
                              : variant == AppThemeVariant.slate
                                  ? l10n.themeSlateLabel
                                  : variant == AppThemeVariant.ocean
                                      ? l10n.themeOceanLabel
                      : l10n.themeEarthLabel,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeIconToggle extends StatelessWidget {
  const _ThemeIconToggle({
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return _ThemeIconButton(
      asset: isDark
          ? 'assets/icons/contrast-2-fill.svg'
          : 'assets/icons/sun-fill.svg',
      onTap: () => ThemeController.instance.setThemeMode(
        isDark ? ThemeMode.light : ThemeMode.dark,
      ),
    );
  }
}

class _ThemeIconButton extends StatelessWidget {
  const _ThemeIconButton({
    required this.asset,
    required this.onTap,
  });

  final String asset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOutCubic,
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: AppTheme.actionSurface(context),
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.cardBorder(context)),
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeInOutCubic,
          switchOutCurve: Curves.easeInOutCubic,
          transitionBuilder: (child, animation) {
            if (animation.status == AnimationStatus.reverse) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            }
            final turns = Tween<double>(
              begin: 0.15,
              end: 0,
            ).animate(animation);
            return RotationTransition(
              turns: turns,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
          child: SvgPicture.asset(
            asset,
            key: ValueKey<String>(asset),
            width: 22,
            height: 22,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.onSurface,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.primary,
    required this.onPressed,
    required this.label,
  });

  final bool primary;
  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
      width: double.infinity,
      height: 50,
      child: primary
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(label),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(label),
            ),
    );
    return child;
  }
}

class _BiometricPreferenceRow extends StatelessWidget {
  const _BiometricPreferenceRow({
    required this.enabled,
    required this.interactive,
    required this.onChanged,
  });

  final bool enabled;
  final bool interactive;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.biometricEnableTitle,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                enabled
                    ? l10n.biometricEnabledBody
                    : l10n.biometricDisabledBody,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Theme(
          data: theme.copyWith(
            switchTheme: SwitchThemeData(
              thumbColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return scheme.surfaceContainerHighest;
                }
                if (states.contains(WidgetState.selected)) {
                  return scheme.onPrimary;
                }
                return scheme.outline;
              }),
              trackColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return scheme.surfaceContainerHighest.withValues(alpha: 0.55);
                }
                if (states.contains(WidgetState.selected)) {
                  return scheme.primary;
                }
                return scheme.surfaceContainerHighest;
              }),
              trackOutlineColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.transparent;
                }
                return scheme.outlineVariant;
              }),
              trackOutlineWidth: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return 0;
                }
                return 1;
              }),
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return scheme.primary.withValues(alpha: 0.12);
                }
                return Colors.transparent;
              }),
              thumbIcon: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const Icon(Icons.check_rounded, size: 14);
                }
                return const Icon(Icons.close_rounded, size: 12);
              }),
            ),
          ),
          child: Switch(
            value: enabled,
            onChanged: interactive ? onChanged : null,
          ),
        ),
      ],
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.displayName,
    required this.cachedAvatar,
    required this.pendingAvatarBytes,
  });

  final String displayName;
  final File? cachedAvatar;
  final Uint8List? pendingAvatarBytes;

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      height: 96,
      width: 96,
      decoration: BoxDecoration(
        color: AppTheme.actionSurface(context),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        (displayName.isNotEmpty ? displayName[0] : 'U').toUpperCase(),
        style: Theme.of(context).textTheme.headlineMedium,
      ),
    );

    if (pendingAvatarBytes != null && pendingAvatarBytes!.isNotEmpty) {
      return ClipOval(
        child: Image.memory(
          pendingAvatarBytes!,
          height: 96,
          width: 96,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => fallback,
        ),
      );
    }

    if (cachedAvatar == null) {
      return fallback;
    }

    return ClipOval(
      child: Image.file(
        cachedAvatar!,
        height: 96,
        width: 96,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}
