import '../../../core/api/mobile_api.dart';
import '../../../core/location/country_dial_code_service.dart';
import '../../../core/security/security_controller.dart';
import '../../../app/app_router.dart';
import '../../../core/session/app_session.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/common_widgets.dart';
import '../data/profile_avatar_cache.dart';
import '../models/app_models.dart';
import '../../admin/presentation/widgets/admin_dock.dart';
import '../../supplier/presentation/widgets/supplier_dock.dart';
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
  bool savingLocation = false;
  String? errorMessage;
  String? countryPrefix;
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
    _loadCountryPrefix();
  }

  Future<void> _loadCountryPrefix() async {
    final prefix = await CountryDialCodeService.instance.cachedPrefix();
    if (!mounted) {
      return;
    }
    setState(() {
      countryPrefix = prefix;
    });
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

  Future<void> _refreshCountryPrefix() async {
    setState(() {
      savingLocation = true;
      errorMessage = null;
    });
    try {
      final prefix =
          await CountryDialCodeService.instance.refreshFromLocation();
      if (!mounted) {
        return;
      }
      setState(() {
        countryPrefix = prefix;
      });
      if (prefix == null || prefix.isEmpty) {
        setState(() {
          errorMessage = 'Country code aniqlanmadi';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          savingLocation = false;
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
            : 'Admin account';
    final bool hasPin = SecurityController.instance.hasPinForCurrentUser;
    final bool biometricEnabled =
        SecurityController.instance.biometricEnabledForCurrentUser;

    return AppShell(
      title: 'Profile',
      subtitle: 'Shaxsiy sozlamalar va session.',
      bottom: role == UserRole.supplier
          ? const SupplierDock(activeTab: SupplierDockTab.profile)
          : role == UserRole.werka
              ? const WerkaDock(activeTab: WerkaDockTab.profile)
              : const AdminDock(activeTab: AdminDockTab.profile),
      child: RefreshIndicator.adaptive(
        onRefresh: _refreshProfile,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            SoftCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                                height: 30,
                                width: 30,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryButton(context),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.cardBackground(context),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.camera_alt_rounded,
                                  size: 14,
                                  color:
                                      AppTheme.primaryButtonForeground(context),
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
                                  .headlineMedium
                                  ?.copyWith(fontSize: 24),
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
                  const SizedBox(height: 16),
                  _InfoRow(
                    label: 'Telefon',
                    value: current.phone,
                  ),
                  const SizedBox(height: 12),
                  _InfoRow(
                    label: 'Asl ism',
                    value: current.legalName.isEmpty
                        ? current.displayName
                        : current.legalName,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nicknameController,
                    decoration: const InputDecoration(
                      labelText: 'Nickname',
                      hintText: 'O‘zingizga ko‘rinadigan ism',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: savingNickname ? null : _saveNickname,
                          child: savingNickname
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Text('Saqlash'),
                        ),
                      ),
                      if (pendingAvatarBytes != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: savingAvatar ? null : _saveAvatar,
                            child: savingAvatar
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Rasm saqlash'),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (pendingAvatarBytes != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Yangi rasm tanlandi, saqlashni bosing.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security va Location',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    hasPin
                        ? '4 xonali PIN yoqilgan'
                        : 'App uchun 4 xonali PIN o‘rnating',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: savingPin ? null : _showPinFlow,
                      child: Text(
                        savingPin
                            ? 'Saqlanmoqda...'
                            : hasPin
                                ? 'PIN almashtirish'
                                : 'PIN o‘rnatish',
                      ),
                    ),
                  ),
                  if (hasPin) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: savingPin ? null : _removePin,
                        child: const Text('PIN o‘chirish'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          biometricEnabled
                              ? 'Face ID / Fingerprint yoqilgan'
                              : 'Face ID / Fingerprint o‘chirilgan',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Switch.adaptive(
                        value: biometricEnabled,
                        onChanged: hasPin && !savingBiometric
                            ? (value) => _toggleBiometric(value)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    countryPrefix == null || countryPrefix!.isEmpty
                        ? 'Country code aniqlanmagan'
                        : 'Hozirgi country code: $countryPrefix',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: savingLocation ? null : _refreshCountryPrefix,
                      child: Text(
                        savingLocation
                            ? 'Aniqlanmoqda...'
                            : 'Country code yangilash',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (errorMessage != null) ...[
              const SizedBox(height: 14),
              SoftCard(
                child: Text(errorMessage!),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await MobileApi.instance.logout();
                  await SecurityController.instance.clearForLogout();
                  if (!mounted) {
                    return;
                  }
                  navigator.pushNamedAndRemoveUntil('/', (route) => false);
                },
                child: const Text('Logout'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ThemeIconButton(
          asset: 'assets/icons/contrast-2-fill.svg',
          active: isDark,
          onTap: () => ThemeController.instance.setThemeMode(ThemeMode.dark),
        ),
        const SizedBox(width: 8),
        _ThemeIconButton(
          asset: isDark
              ? 'assets/icons/sun-line.svg'
              : 'assets/icons/sun-fill.svg',
          active: !isDark,
          onTap: () => ThemeController.instance.setThemeMode(ThemeMode.light),
        ),
      ],
    );
  }
}

class _ThemeIconButton extends StatelessWidget {
  const _ThemeIconButton({
    required this.asset,
    required this.active,
    required this.onTap,
  });

  final String asset;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: active ? null : onTap,
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: active
              ? AppTheme.primaryButton(context)
              : AppTheme.actionSurface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder(context)),
        ),
        alignment: Alignment.center,
        child: SvgPicture.asset(
          asset,
          width: 22,
          height: 22,
          colorFilter: ColorFilter.mode(
            active
                ? AppTheme.primaryButtonForeground(context)
                : Theme.of(context).colorScheme.onSurface,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
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
