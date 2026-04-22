import '../../../core/api/mobile_api.dart';
import '../../../core/security/security_controller.dart';
import '../../../app/app_router.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/localization/locale_controller.dart';
import '../../../core/session/app_session.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/m3_confirm_dialog.dart';
import '../../../core/widgets/m3_segmented_list.dart';
import '../../../core/widgets/motion_widgets.dart';
import '../../../core/widgets/top_refresh_scroll_physics.dart';
import '../data/profile_avatar_cache.dart';
import '../models/app_models.dart';
import '../../admin/presentation/widgets/admin_dock.dart';
import '../../supplier/presentation/widgets/supplier_dock.dart';
import '../../customer/presentation/widgets/customer_dock.dart';
import '../../werka/presentation/widgets/werka_dock.dart';
import '../../werka/presentation/widgets/werka_navigation_drawer.dart';
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

  String _normalizeWerkaLabel(String value, UserRole role) {
    final trimmed = value.trim();
    if (role == UserRole.werka && trimmed.toLowerCase() == 'werka') {
      return 'Wmanager';
    }
    return value;
  }

  String _normalizedDisplayName(SessionProfile profile) =>
      _normalizeWerkaLabel(profile.displayName, profile.role);

  String _normalizedLegalName(SessionProfile profile) =>
      _normalizeWerkaLabel(profile.legalName, profile.role);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    nicknameController.text = _normalizedDisplayName(profile);
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
      nicknameController.text = _normalizedDisplayName(updated);
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
      nicknameController.text = _normalizedDisplayName(updated);
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
      nicknameController.text.trim() != _normalizedDisplayName(profile).trim();

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
      final enable = await showM3ConfirmDialog(
        context: context,
        title: 'Tezkor ochish',
        message: 'Face ID yoki fingerprint bilan tez ochishni yoqasizmi?',
        cancelLabel: context.l10n.no,
        confirmLabel: context.l10n.yes,
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
        final displayName = _normalizedDisplayName(current);
        final legalName = _normalizedLegalName(current);
        final effectiveLegalName =
            (legalName.isEmpty ? displayName : legalName).trim();

        return AppShell(
          title: l10n.profileTitle,
          subtitle: '',
          nativeTopBar: true,
          animateOnEnter: role != UserRole.customer,
          drawer: role == UserRole.werka
              ? WerkaNavigationDrawer(
                  selectedIndex: 3,
                  onNavigate: _openWerkaDrawerRoute,
                )
              : null,
          bottom: role == UserRole.supplier
              ? const SupplierDock(activeTab: null, showPrimaryFab: false)
              : role == UserRole.werka
                  ? const WerkaDock(activeTab: null, showPrimaryFab: false)
                  : role == UserRole.customer
                      ? const CustomerDock(activeTab: null)
                      : const AdminDock(activeTab: null, showPrimaryFab: false),
          contentPadding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
          child: AppRefreshIndicator(
            onRefresh: _refreshProfile,
            child: ListView(
              physics: const TopRefreshScrollPhysics(),
              padding: EdgeInsets.fromLTRB(0, 0, 0, bottomPadding),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
                  child: SmoothAppear(
                    delay: const Duration(milliseconds: 20),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  _AvatarPreview(
                                    displayName: displayName,
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
                                      displayName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                              fontWeight: FontWeight.w700),
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
                                    if (effectiveLegalName.isNotEmpty) ...[
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
                                              effectiveLegalName,
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
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                            cursorColor: Theme.of(context).colorScheme.primary,
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

  void _openWerkaDrawerRoute(String route) {
    final current = ModalRoute.of(context)?.settings.name;
    if (current == route) {
      return;
    }
    Navigator.of(context).pushReplacementNamed(route);
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
          isDismissible: true,
          enableDrag: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          sheetAnimationStyle: AppMotion.sheetEaseOut,
          builder: (context) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: SafeArea(
                top: false,
                bottom: false,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: GestureDetector(
                    onTap: () {},
                    child: _ProfileSelectionSheet(
                      title: l10n.languageTitle,
                      subtitle: l10n.languageBody,
                      child: M3SegmentSpacedColumn(
                        children: [
                          _ProfileSelectionOption(
                            index: 0,
                            itemCount: 3,
                            title: l10n.uzbek,
                            subtitle: 'Uzbek',
                            active: currentLocale.languageCode == 'uz',
                            onTap: () =>
                                Navigator.of(context).pop(const Locale('uz')),
                          ),
                          _ProfileSelectionOption(
                            index: 1,
                            itemCount: 3,
                            title: l10n.english,
                            subtitle: 'English',
                            active: currentLocale.languageCode == 'en',
                            onTap: () =>
                                Navigator.of(context).pop(const Locale('en')),
                          ),
                          _ProfileSelectionOption(
                            index: 2,
                            itemCount: 3,
                            title: l10n.russian,
                            subtitle: 'Russian',
                            active: currentLocale.languageCode == 'ru',
                            onTap: () =>
                                Navigator.of(context).pop(const Locale('ru')),
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
          isDismissible: true,
          enableDrag: true,
          isScrollControlled: true,
          useSafeArea: false,
          backgroundColor: Colors.transparent,
          sheetAnimationStyle: AppMotion.sheetEaseOut,
          builder: (context) {
            final mediaQuery = MediaQuery.of(context);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).maybePop(),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  onTap: () {},
                  child: _ProfileSelectionSheet(
                    title: l10n.themeTitle,
                    subtitle: l10n.themeBody,
                    maxHeight: mediaQuery.size.height * 0.72,
                    bottomPadding: mediaQuery.padding.bottom + 24,
                    child: M3SegmentSpacedColumn(
                      children: [
                        _ThemeSelectionOption(
                          index: 0,
                          itemCount: 7,
                          title: l10n.themeClassicLabel,
                          active: variant == AppThemeVariant.classic,
                          swatches: const [
                            Color(0xFF324670),
                            Color(0xFFD8E2FF),
                            Color(0xFF53627F),
                          ],
                          onTap: () => Navigator.of(context)
                              .pop(AppThemeVariant.classic),
                        ),
                        _ThemeSelectionOption(
                          index: 1,
                          itemCount: 7,
                          title: l10n.themeEarthLabel,
                          active: variant == AppThemeVariant.earthy,
                          swatches: const [
                            Color(0xFF8A7650),
                            Color(0xFFDBCEA5),
                            Color(0xFF8E977D),
                          ],
                          onTap: () =>
                              Navigator.of(context).pop(AppThemeVariant.earthy),
                        ),
                        _ThemeSelectionOption(
                          index: 2,
                          itemCount: 7,
                          title: l10n.themeBlushLabel,
                          active: variant == AppThemeVariant.blush,
                          swatches: const [
                            Color(0xFFF5AFAF),
                            Color(0xFFF9DFDF),
                            Color(0xFFFBEFEF),
                          ],
                          onTap: () =>
                              Navigator.of(context).pop(AppThemeVariant.blush),
                        ),
                        _ThemeSelectionOption(
                          index: 3,
                          itemCount: 7,
                          title: l10n.themeMossLabel,
                          active: variant == AppThemeVariant.moss,
                          swatches: const [
                            Color(0xFF84B179),
                            Color(0xFFC7EABB),
                            Color(0xFFA2CB8B),
                          ],
                          onTap: () =>
                              Navigator.of(context).pop(AppThemeVariant.moss),
                        ),
                        _ThemeSelectionOption(
                          index: 4,
                          itemCount: 7,
                          title: l10n.themeLavenderLabel,
                          active: variant == AppThemeVariant.lavender,
                          swatches: const [
                            Color(0xFF4D4C7D),
                            Color(0xFFD8B9C3),
                            Color(0xFF827397),
                          ],
                          onTap: () => Navigator.of(context)
                              .pop(AppThemeVariant.lavender),
                        ),
                        _ThemeSelectionOption(
                          index: 5,
                          itemCount: 7,
                          title: l10n.themeSlateLabel,
                          active: variant == AppThemeVariant.slate,
                          swatches: const [
                            Color(0xFF30364F),
                            Color(0xFFACBAC4),
                            Color(0xFFE1D9BC),
                          ],
                          onTap: () =>
                              Navigator.of(context).pop(AppThemeVariant.slate),
                        ),
                        _ThemeSelectionOption(
                          index: 6,
                          itemCount: 7,
                          title: l10n.themeOceanLabel,
                          active: variant == AppThemeVariant.ocean,
                          swatches: const [
                            Color(0xFF1C4D8D),
                            Color(0xFF4988C4),
                            Color(0xFFBDE8F5),
                          ],
                          onTap: () =>
                              Navigator.of(context).pop(AppThemeVariant.ocean),
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
                          : variant == AppThemeVariant.lavender
                              ? l10n.themeLavenderLabel
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

class _ProfileSelectionSheet extends StatelessWidget {
  const _ProfileSelectionSheet({
    required this.title,
    required this.subtitle,
    required this.child,
    this.maxHeight,
    this.bottomPadding = 24,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final double? maxHeight;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight ?? double.infinity,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(12, 12, 12, bottomPadding),
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
              Text(
                title,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileSelectionOption extends StatelessWidget {
  const _ProfileSelectionOption({
    required this.index,
    required this.itemCount,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.active = false,
  });

  final int index;
  final int itemCount;
  final String title;
  final String? subtitle;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final slot = M3SegmentedListGeometry.standaloneListSlotForIndex(
      index,
      itemCount,
    );
    final radius = M3SegmentedListGeometry.cornerRadiusForSlot(slot);
    return M3SegmentFilledSurface(
      slot: slot,
      cornerRadius: radius,
      backgroundColor: active
          ? scheme.secondaryContainer.withValues(alpha: 0.9)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.72),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color:
                          active ? scheme.onSecondaryContainer : scheme.onSurface,
                    ),
                  ),
                  if ((subtitle ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: active
                            ? scheme.onSecondaryContainer.withValues(alpha: 0.74)
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: AppMotion.medium,
              curve: AppMotion.smooth,
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                color: active ? scheme.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: active ? null : Border.all(color: scheme.outlineVariant),
              ),
              child: active
                  ? Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: scheme.onPrimary,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeSelectionOption extends StatelessWidget {
  const _ThemeSelectionOption({
    required this.index,
    required this.itemCount,
    required this.title,
    required this.swatches,
    required this.active,
    required this.onTap,
  });

  final int index;
  final int itemCount;
  final String title;
  final List<Color> swatches;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final slot = M3SegmentedListGeometry.standaloneListSlotForIndex(
      index,
      itemCount,
    );
    final radius = M3SegmentedListGeometry.cornerRadiusForSlot(slot);
    return M3SegmentFilledSurface(
      slot: slot,
      cornerRadius: radius,
      backgroundColor: active
          ? scheme.secondaryContainer.withValues(alpha: 0.9)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.72),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: active ? scheme.onSecondaryContainer : scheme.onSurface,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final swatch in swatches) ...[
                  Container(
                    height: 14,
                    width: 14,
                    decoration: BoxDecoration(
                      color: swatch,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (swatch != swatches.last) const SizedBox(width: 6),
                ],
              ],
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: AppMotion.medium,
              curve: AppMotion.smooth,
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                color: active ? scheme.primary : Colors.transparent,
                shape: BoxShape.circle,
                border: active ? null : Border.all(color: scheme.outlineVariant),
              ),
              child: active
                  ? Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: scheme.onPrimary,
                    )
                  : null,
            ),
          ],
        ),
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
