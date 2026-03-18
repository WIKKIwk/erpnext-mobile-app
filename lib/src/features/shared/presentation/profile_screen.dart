import '../../../core/api/mobile_api.dart';
import '../../../core/security/security_controller.dart';
import '../../../app/app_router.dart';
import '../../../core/session/app_session.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/motion_widgets.dart';
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
        errorMessage = 'Nickname saqlanmadi';
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
        errorMessage = 'Rasm tanlanmadi';
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
        errorMessage = 'Rasm saqlanmadi';
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
    final current = profile;
    final role = current.role;
    final subtitle = role == UserRole.supplier
        ? 'Supplier account'
        : role == UserRole.werka
            ? 'Werka account'
            : role == UserRole.customer
                ? 'Customer account'
                : 'Admin account';
    final bool hasPin = SecurityController.instance.hasPinForCurrentUser;
    final bool biometricEnabled =
        SecurityController.instance.biometricEnabledForCurrentUser;
    final bool savingProfileChanges = savingNickname || savingAvatar;

    return AppShell(
      title: 'Profile',
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
      child: RefreshIndicator.adaptive(
        onRefresh: _refreshProfile,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
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
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
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
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _ThemeIconToggle(
                          isDark: ThemeController.instance.isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _InfoTile(
                      label: 'Telefon',
                      value: current.phone,
                    ),
                    const SizedBox(height: 10),
                    _InfoTile(
                      label: 'Asl ism',
                      value: current.legalName.isEmpty
                          ? current.displayName
                          : current.legalName,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nicknameController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Nickname',
                        hintText: 'O‘zingizga ko‘rinadigan ism',
                      ),
                    ),
                    if (_hasProfileChanges) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              savingProfileChanges ? null : _saveProfileChanges,
                          icon: savingProfileChanges
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.check_rounded),
                          label: const Text('Saqlash'),
                        ),
                      ),
                    ],
                    if (pendingAvatarBytes != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Yangi rasm tanlandi, saqlashni bosing.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
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
                      'Security',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hasPin
                          ? '4 xonali PIN yoqilgan'
                          : 'App uchun 4 xonali PIN o‘rnating',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    _ProfileActionButton(
                      primary: true,
                      onPressed: savingPin ? null : _showPinFlow,
                      label: savingPin
                          ? 'Saqlanmoqda...'
                          : hasPin
                              ? 'PIN almashtirish'
                              : 'PIN o‘rnatish',
                    ),
                    if (hasPin) ...[
                      const SizedBox(height: 10),
                      _ProfileActionButton(
                        primary: false,
                        onPressed: savingPin ? null : _removePin,
                        label: 'PIN o‘chirish',
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
      isDark: isDark,
      onTap: () => ThemeController.instance.setThemeMode(
        isDark ? ThemeMode.light : ThemeMode.dark,
      ),
    );
  }
}

class _ThemeIconButton extends StatelessWidget {
  const _ThemeIconButton({
    required this.asset,
    required this.isDark,
    required this.onTap,
  });

  final String asset;
  final bool isDark;
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
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
                'Biometrik autentifikatsiyani yoqish',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                enabled
                    ? 'Yoqilgan. App Face ID yoki fingerprint bilan tez ochiladi.'
                    : 'O‘chirilgan. Face ID yoki fingerprint bilan tez ochish ishlamaydi.',
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
