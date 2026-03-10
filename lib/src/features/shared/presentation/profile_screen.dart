import '../../../core/api/mobile_api.dart';
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
              padding: const EdgeInsets.all(22),
              child: Column(
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
                              color: AppTheme.primaryButton(context),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.cardBackground(context),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color:
                                  AppTheme.primaryButtonForeground(context),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    current.displayName,
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(fontSize: 28),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  if (pendingAvatarBytes != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: savingAvatar ? null : _saveAvatar,
                        child: savingAvatar
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Text('Rasm saqlash'),
                      ),
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
                    'Nickname',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nicknameController,
                    decoration: const InputDecoration(
                      labelText: 'Nickname',
                      hintText: 'O‘zingizga ko‘rinadigan ism',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
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
                ],
              ),
            ),
            const SizedBox(height: 18),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    label: 'Telefon',
                    value: current.phone,
                  ),
                  const SizedBox(height: 14),
                  _InfoRow(
                    label: 'Asl ism',
                    value: current.legalName.isEmpty
                        ? current.displayName
                        : current.legalName,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ThemeModeButton(
                          label: 'Qora',
                          active: ThemeController.instance.isDark,
                          onTap: () => ThemeController.instance
                              .setThemeMode(ThemeMode.dark),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ThemeModeButton(
                          label: 'Oq',
                          active: !ThemeController.instance.isDark,
                          onTap: () => ThemeController.instance
                              .setThemeMode(ThemeMode.light),
                        ),
                      ),
                    ],
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

class _ThemeModeButton extends StatelessWidget {
  const _ThemeModeButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: active ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? AppTheme.primaryButton(context)
              : AppTheme.cardBackground(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.cardBorder(context)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: active
                    ? AppTheme.primaryButtonForeground(context)
                    : Theme.of(context).colorScheme.onSurface,
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
